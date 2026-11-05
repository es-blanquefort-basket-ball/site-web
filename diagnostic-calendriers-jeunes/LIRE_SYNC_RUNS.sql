-- Lecture seule ciblée : derniers résultats FFBB et détails des quatre équipes.
-- Projet fgswygeqstgagmipltpq. Ne lance ni fonction, ni cron, ni import.
SELECT r.id, r.started_at, r.finished_at, r.status,
       r.matches_found, r.matches_created, r.matches_updated, r.conflicts_found,
       r.details->>'error' AS erreur_globale,
       (SELECT jsonb_agg(p.value)
        FROM jsonb_array_elements(COALESCE(r.details->'report','[]'::jsonb)) p(value)
        WHERE p.value->>'team' IN ('U13F','U13M','U15M','U18M')) AS rapport_equipes_jeunes
FROM public.sync_runs r
WHERE r.source='FFBB'
ORDER BY r.started_at DESC
LIMIT 10;
