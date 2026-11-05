import { withSupabase } from "npm:@supabase/server@^1";
import { DateTime } from "npm:luxon@3";

const MONTHS: Record<string, number> = {
  "janv.": 1,
  "févr.": 2,
  "mars": 3,
  "avr.": 4,
  "mai": 5,
  "juin": 6,
  "juil.": 7,
  "août": 8,
  "sept.": 9,
  "oct.": 10,
  "nov.": 11,
  "déc.": 12,
};

function decodeHtml(text: string) {
  return text
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&#39;/gi, "'")
    .replace(/&#x27;/gi, "'")
    .replace(/&quot;/gi, '"')
    .replace(/&eacute;/gi, "é")
    .replace(/&Eacute;/gi, "É");
}

function clean(text: string) {
  return decodeHtml(text)
    .replace(/\s+/g, " ")
    .trim();
}

function stripTags(html: string) {
  return clean(html.replace(/<[^>]*>/g, " "));
}

function cleanOpponent(raw: string) {
  let value = clean(raw);

  value = value.replace(/\s+Datas de l'équipe.*$/i, "");
  value = value.replace(/\s+\d{1,3}\s+\d{1,3}\s*$/, "");

  return value.trim();
}

function extractScore(raw: string) {
  const withoutStats = clean(raw).replace(/\s+Datas de l'équipe.*$/i, "");
  const found = withoutStats.match(/\s+(\d{1,3})\s+(\d{1,3})\s*$/);

  if (!found) return null;

  return {
    first: Number(found[1]),
    second: Number(found[2]),
  };
}

function extractCompetitionIdentity(poolUrl: string | null) {
  if (!poolUrl) {
    return {
      phase: "unknown",
      pool: "unknown",
    };
  }

  try {
    const url = new URL(poolUrl);

    return {
      phase: url.searchParams.get("phase") ?? "unknown",
      pool: url.searchParams.get("poule") ?? "unknown",
    };
  } catch {
    return {
      phase: "unknown",
      pool: "unknown",
    };
  }
}

function extractMatchUrls(html: string, baseUrl: string) {
  const urls: string[] = [];
  const seen = new Set<string>();

  const regex = /href=["']([^"']*\/match\/\d+[^"']*)["']/gi;
  let found: RegExpExecArray | null;

  while ((found = regex.exec(html)) !== null) {
    try {
      const href = decodeHtml(found[1]);
      const absoluteUrl = new URL(href, baseUrl).toString();

      if (!seen.has(absoluteUrl)) {
        seen.add(absoluteUrl);
        urls.push(absoluteUrl);
      }
    } catch {
      // Lien invalide : on l'ignore sans bloquer la synchronisation.
    }
  }

  return urls;
}

function parseVenueFromMatchPage(html: string) {
  const text = stripTags(html);

  const found = text.match(
    /\bSalle\s+Nom\s+(.+?)\s+Adresse\s+(.+?)(?=\s+Téléphone\b|\s+L[’']actualité Basketball\b|$)/i,
  );

  if (!found) {
    return {
      name: null as string | null,
      address: null as string | null,
    };
  }

  return {
    name: clean(found[1]) || null,
    address: clean(found[2]) || null,
  };
}

async function fetchMatchVenue(matchUrl: string) {
  try {
    const response = await fetch(matchUrl, {
      headers: {
        "User-Agent": "Mozilla/5.0 ESB-Basket-FFBB-Sync/1.0",
        "Accept": "text/html",
      },
    });

    if (!response.ok) {
      return {
        name: null as string | null,
        address: null as string | null,
        error: `FFBB détail HTTP ${response.status}`,
      };
    }

    const html = await response.text();
    const venue = parseVenueFromMatchPage(html);

    return {
      ...venue,
      error: null as string | null,
    };
  } catch (error) {
    return {
      name: null as string | null,
      address: null as string | null,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

function parseMatches(html: string, baseUrl: string) {
  const text = stripTags(html);
  const matchUrls = extractMatchUrls(html, baseUrl);

  const results: Array<{
    round: string;
    day: number;
    monthLabel: string;
    month: number;
    time: string;
    homeAway: "Domicile" | "Extérieur";
    opponentRaw: string;
    opponent: string;
    scoreRaw: { first: number; second: number } | null;
    matchUrl: string | null;
  }> = [];

  const regex =
    /J(\d+)\s+(\d{1,2})\s+(janv\.|févr\.|mars|avr\.|mai|juin|juil\.|août|sept\.|oct\.|nov\.|déc\.)\s+(\d{2}h\d{2})\s+(Domicile|Extérieur)\s+(.+?)(?=\s+#?\d+\s+J\d+|\s+Datas de l'équipe|\s+Classement officiel|$)/gi;

  let match: RegExpExecArray | null;
  let matchIndex = 0;

  while ((match = regex.exec(text)) !== null) {
    const opponentRaw = clean(match[6]);

    results.push({
      round: `J${match[1]}`,
      day: Number(match[2]),
      monthLabel: match[3],
      month: MONTHS[match[3].toLowerCase()],
      time: match[4],
      homeAway: match[5] as "Domicile" | "Extérieur",
      opponentRaw,
      opponent: cleanOpponent(opponentRaw),
      scoreRaw: extractScore(opponentRaw),
      matchUrl: matchUrls[matchIndex] ?? null,
    });

    matchIndex++;
  }

  return results;
}

function toParisTimestamp(
  year: number,
  month: number,
  day: number,
  time: string,
) {
  const [hour, minute] = time.split("h").map(Number);

  const dt = DateTime.fromObject(
    {
      year,
      month,
      day,
      hour,
      minute,
      second: 0,
    },
    {
      zone: "Europe/Paris",
    },
  );

  if (!dt.isValid) return null;

  return dt.toUTC().toISO();
}

export default {
  fetch: withSupabase(
    { auth: "publishable" },
    async (req, ctx) => {
      if (req.method !== "POST") {
        return Response.json(
          { error: "POST required" },
          { status: 405 },
        );
      }

      // Client serveur privilégié : bypass RLS
      const supabase = ctx.supabaseAdmin;

      const syncStartedAt = new Date().toISOString();

      const { data: syncRun, error: syncStartError } = await supabase
        .from("sync_runs")
        .insert({
          source: "FFBB",
          started_at: syncStartedAt,
          status: "running",
        })
        .select("id")
        .single();

      if (syncStartError) {
        return Response.json(
          {
            error: "Impossible de créer le journal de synchronisation",
            details: syncStartError.message,
          },
          { status: 500 },
        );
      }

      const syncId = syncRun.id;

      try {
        const { data: teams, error: teamsError } = await supabase
          .from("teams")
          .select(
            "id, code, name, competition_label, ffbb_team_id, ffbb_team_url, ffbb_pool_url",
          )
          .eq("is_competition_active", true)
          .not("ffbb_team_url", "is", null);

        if (teamsError) {
          throw new Error(`Lecture teams : ${teamsError.message}`);
        }

        let matchesFound = 0;
        let matchesCreated = 0;
        let matchesUpdated = 0;
        let conflictsFound = 0;
        let venuesEnriched = 0;
        let venueDetailErrors = 0;

        const report: Array<Record<string, unknown>> = [];

        for (const team of teams ?? []) {
          const response = await fetch(team.ffbb_team_url, {
            headers: {
              "User-Agent": "Mozilla/5.0 ESB-Basket-FFBB-Sync/1.0",
              "Accept": "text/html",
            },
          });

          if (!response.ok) {
            report.push({
              team: team.code,
              error: `FFBB HTTP ${response.status}`,
            });
            continue;
          }

          const html = await response.text();
          const parsed = parseMatches(html, team.ffbb_team_url);

          matchesFound += parsed.length;

          const competitionIdentity = extractCompetitionIdentity(
            team.ffbb_pool_url,
          );

          let teamCreated = 0;
          let teamUpdated = 0;
          let teamConflicts = 0;
          let teamVenuesEnriched = 0;
          let teamVenueDetailErrors = 0;

          for (const match of parsed) {
            const year = match.month >= 9 ? 2026 : 2027;

            const scheduledAtFFBB = toParisTimestamp(
              year,
              match.month,
              match.day,
              match.time,
            );

            const ffbbMatchId = [
              team.ffbb_team_id,
              competitionIdentity.phase,
              competitionIdentity.pool,
              match.round,
            ].join("-");

            const isSuspiciousTime = match.time === "02h00";

            const { data: existing, error: existingError } = await supabase
              .from("matches")
              .select(
                "id, published, scheduled_at_override, venue_name_override, override_note, ffbb_match_url, venue_name_raw, venue_address_raw",
              )
              .eq("ffbb_match_id", ffbbMatchId)
              .maybeSingle();

            if (existingError) {
              throw new Error(
                `Recherche ${team.code} ${match.round} : ${existingError.message}`,
              );
            }

            const hasClubOverride = Boolean(
              existing?.scheduled_at_override
            );

            const hasConflict =
              isSuspiciousTime && !hasClubOverride;

            const conflictNote = hasConflict
              ? `Horaire FFBB suspect (${match.time}) - validation club nécessaire`
              : null;

            let venueNameRaw = existing?.venue_name_raw ?? null;
            let venueAddressRaw = existing?.venue_address_raw ?? null;
            let venueDetailError: string | null = null;

            if (match.matchUrl) {
              const venue = await fetchMatchVenue(match.matchUrl);

              if (venue.name) {
                venueNameRaw = venue.name;
              }

              if (venue.address) {
                venueAddressRaw = venue.address;
              }

              venueDetailError = venue.error;

              if (venue.name || venue.address) {
                venuesEnriched++;
                teamVenuesEnriched++;
              }

              if (venue.error) {
                venueDetailErrors++;
                teamVenueDetailErrors++;
              }
            }

            const payload = {
              team_id: team.id,

              ffbb_match_id: ffbbMatchId,
              ffbb_match_url:
                match.matchUrl ?? existing?.ffbb_match_url ?? null,

              opponent_name: match.opponent,

              venue_name_raw: venueNameRaw,
              venue_address_raw: venueAddressRaw,

              scheduled_at: scheduledAtFFBB,
              scheduled_at_ffbb: scheduledAtFFBB,

              home_away:
                match.homeAway === "Domicile"
                  ? "home"
                  : "away",

              competition_name: team.competition_label,
              round_label: match.round,

              status: "scheduled",

              has_conflict: hasConflict,
              conflict_note: conflictNote,

              fetched_at: new Date().toISOString(),

              source_data: {
                source: "FFBB",
                source_url: team.ffbb_team_url,
                match_detail_url: match.matchUrl,
                team: team.code,
                round: match.round,
                date: {
                  year,
                  month: match.month,
                  day: match.day,
                },
                time_ffbb: match.time,
                home_away_ffbb: match.homeAway,
                opponent_raw: match.opponentRaw,
                opponent_clean: match.opponent,
                score_raw: match.scoreRaw,
                venue_name_raw: venueNameRaw,
                venue_address_raw: venueAddressRaw,
                venue_detail_error: venueDetailError,
                phase: competitionIdentity.phase,
                pool: competitionIdentity.pool,
              },
            };

            if (existing) {
              const { error: updateError } = await supabase
                .from("matches")
                .update(payload)
                .eq("id", existing.id);

              if (updateError) {
                throw new Error(
                  `Mise à jour ${team.code} ${match.round} : ${updateError.message}`,
                );
              }

              matchesUpdated++;
              teamUpdated++;
            } else {
              const { error: insertError } = await supabase
                .from("matches")
                .insert({
                  ...payload,
                  published: false,
                });

              if (insertError) {
                throw new Error(
                  `Création ${team.code} ${match.round} : ${insertError.message}`,
                );
              }

              matchesCreated++;
              teamCreated++;
            }

            if (hasConflict) {
              conflictsFound++;
              teamConflicts++;
            }
          }

          report.push({
            team: team.code,
            matches: parsed.length,
            created: teamCreated,
            updated: teamUpdated,
            conflicts: teamConflicts,
            venuesEnriched: teamVenuesEnriched,
            venueDetailErrors: teamVenueDetailErrors,
          });
        }

        const finalStatus =
          conflictsFound > 0 ? "warning" : "success";

        await supabase
          .from("sync_runs")
          .update({
            finished_at: new Date().toISOString(),
            status: finalStatus,
            matches_found: matchesFound,
            matches_created: matchesCreated,
            matches_updated: matchesUpdated,
            conflicts_found: conflictsFound,
            details: {
              venues_enriched: venuesEnriched,
              venue_detail_errors: venueDetailErrors,
              report,
            },
          })
          .eq("id", syncId);

        return Response.json({
          success: true,
          syncId,
          status: finalStatus,
          matchesFound,
          matchesCreated,
          matchesUpdated,
          conflictsFound,
          venuesEnriched,
          venueDetailErrors,
          teams: report,
          message:
            "Synchronisation terminée. Aucun match importé n'est publié automatiquement.",
        });
      } catch (error) {
        const message =
          error instanceof Error
            ? error.message
            : String(error);

        await supabase
          .from("sync_runs")
          .update({
            finished_at: new Date().toISOString(),
            status: "error",
            details: {
              error: message,
            },
          })
          .eq("id", syncId);

        return Response.json(
          {
            success: false,
            syncId,
            error: message,
          },
          { status: 500 },
        );
      }
    },
  ),
};