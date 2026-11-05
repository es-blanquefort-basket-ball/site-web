// Navigateur local : données du staging injectées, aucune écriture Supabase.
// NODE_PATH doit contenir le module Playwright fourni par le runtime.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.join(__dirname, '..');
const mini = JSON.parse(fs.readFileSync(process.env.CALENDAR_STAGING_SNAPSHOT || path.join(root, 'preparation-calendriers/apercu-import.json')));
const real = JSON.parse(fs.readFileSync(process.env.CALENDAR_PUBLIC_SNAPSHOT || path.join(root, 'preparation-calendriers/etat-public-calendar-avant.json')));
const counts = { U9F: 5, U9M1: 5, U9M2: 5, 'U11 Mixte': 4, 'U11 M': 5 };
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true, timeout: 15000 });
  try {
    const page = await browser.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    let rows = [...real, ...mini.map(row => ({ ...row, score_home: 19, score_away: 19 }))];
    let fail = false;
    await page.route('https://fgswygeqstgagmipltpq.supabase.co/rest/v1/**', async route => {
      if (fail) return route.fulfill({ status: 503, body: '{}' });
      const q = new URL(route.request().url()).searchParams;
      assert(!q.get('select').includes('score'));
      let result = rows.filter(row => !q.get('team_code') || row.team_code === q.get('team_code').slice(3));
      for (const condition of q.getAll('local_date')) {
        const [op, date] = condition.split('.');
        result = result.filter(row => op === 'gte' ? row.local_date >= date : row.local_date < date);
      }
      if (q.has('limit')) result = result.slice(0, Number(q.get('limit')));
      await route.fulfill({ json: result });
    });
    async function ready() {
      await page.waitForFunction(() => !document.querySelector('#calendar-status').textContent.includes('Chargement') && !document.querySelector('#calendar-team-status').textContent.includes('Vérification'));
    }
    async function month(date) {
      await page.locator('#calendar-date').fill(date);
      await page.locator('#calendar-date-form button').click();
      await ready();
      await page.locator('.calendar-drawer-close').click();
    }
    async function visibleMatches() {
      return page.locator('.calendar-count.is-match strong').evaluateAll(nodes => nodes.reduce((n, el) => n + Number(el.textContent), 0));
    }
    for (const width of process.env.CALENDAR_PUBLIC_ONLY ? [] : [390, 768, 1440]) {
      await page.setViewportSize({ width, height: 950 });
      let unknown = 0;
      for (const [team, count] of Object.entries(counts)) {
        await page.goto(`http://127.0.0.1:8765/calendrier.html?equipe=${encodeURIComponent(team)}`);
        await ready();
        assert.equal(await page.locator('#calendar-team').inputValue(), team);
        let total = 0;
        for (const date of ['2026-11-01', '2026-12-01']) {
          await month(date);
          total += await visibleMatches();
          const dates = await page.locator('.calendar-day:not(.is-empty)').evaluateAll(nodes => nodes.map(el => el.dataset.date));
          for (const day of dates) {
            await page.locator(`[data-date="${day}"] button`).click();
            const cards = page.locator('.calendar-day-item');
            const expected = mini.filter(row => row.team_code === team && row.local_date === day);
            assert.equal(await cards.count(), expected.length);
            const cardTeams = await page.locator('.calendar-day-item-title > span:first-child').allTextContents();
            assert(cardTeams.every(text => text === team));
            const times = await page.locator('.calendar-day-item-time').allTextContents();
            unknown += times.filter(time => time === 'Horaire à confirmer').length;
            assert(!/score|19\s*[-:]\s*19/i.test(await page.locator('#calendar-day-content').innerText()));
            await page.keyboard.press('Escape');
          }
        }
        assert.equal(total, count);
        assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      }
      assert.equal(unknown, 11);
      await page.locator('#calendar-team-form > a').click();
      await ready();
      await month('2026-11-01');
      assert.equal(await visibleMatches(), rows.filter(row => row.local_date.startsWith('2026-11')).length);
      await page.locator('#calendar-team').selectOption('U9M2');
      await page.locator('#calendar-team-form button').click();
      await ready();
      assert(new URL(page.url()).searchParams.get('equipe') === 'U9M2');
      await month('2026-11-01');
      assert.equal(await visibleMatches(), 4);
      await page.goto('http://127.0.0.1:8765/equipes.html');
      for (const team of Object.keys(counts)) {
        const card = page.locator('article').filter({ has: page.getByRole('heading', { name: team, exact: true }) });
        const link = card.locator('a[href*="?equipe="]');
        assert.equal(await link.count(), 1);
        assert.equal(new URL(await link.getAttribute('href'), 'http://local').searchParams.get('equipe'), team);
      }
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      assert.equal(await page.locator('img').evaluateAll(nodes => nodes.filter(img => !img.complete || img.naturalWidth === 0).length), 0);
      if (width === 390) {
        await page.locator('.burger').click();
        assert(await page.locator('.navlinks').isVisible());
      }
      console.log(`OK ${width}px : cinq filtres, 24 rencontres du staging, 11 horaires inconnus, retour général, liens Équipes, images et débordement.`);
    }
    // État réellement publié : les MiniBasket sont absents, U18 aussi.
    rows = real;
    await page.goto('http://127.0.0.1:8765/calendrier.html?equipe=U9F');
    await ready();
    assert((await page.locator('#calendar-team-status').innerText()).includes('aucune rencontre publiée'));
    assert.equal(await visibleMatches(), 0);
    for (const team of ['U13F', 'U13M', 'U15M', 'SG1', 'SG2']) {
      await page.goto(`http://127.0.0.1:8765/calendrier.html?equipe=${team}`);
      await ready();
      for (const publishedMonth of new Set(real.filter(row => row.team_code === team).map(row => row.local_date.slice(0, 7)))) {
        await month(`${publishedMonth}-01`);
        assert.equal(await visibleMatches(), real.filter(row => row.team_code === team && row.local_date.startsWith(publishedMonth)).length);
      }
    }
    // U18 est une fixture de comportement, aucune rencontre U18 réelle n'est inventée.
    rows = [{ ...mini[0], team_code: 'U18M', local_date: '2026-11-07' }];
    await page.goto('http://127.0.0.1:8765/calendrier.html?equipe=U18M');
    await ready();
    await month('2026-11-01');
    assert.equal(await visibleMatches(), 1);
    fail = true;
    await page.goto('http://127.0.0.1:8765/calendrier.html?equipe=U9F');
    await ready();
    assert((await page.locator('#calendar-status').innerText()).includes('temporairement indisponible'));
    assert.equal(errors.length, 0, errors.join('\n'));
    console.log('OK : instantané des 33 publications, absence MiniBasket explicite, U18 simulé, erreur réseau gérée, aucun score sélectionné ni affiché.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
