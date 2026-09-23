(() => {
  'use strict';

  const SUPABASE_URL = 'https://fgswygeqstgagmipltpq.supabase.co';
  const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_dsoHXhS222GToiMUIpGkCA_lFPAJm-A';
  const CALENDAR_VIEW = 'public_calendar';
  const SELECT_FIELDS = [
    'team_code',
    'opponent_name',
    'home_away',
    'local_date',
    'local_time',
    'venue_name',
    'venue_address',
    'round_label',
    'ffbb_match_url',
    'ffbb_team_url'
  ].join(',');

  const calendar = document.getElementById('club-calendar');
  const monthTitle = document.getElementById('calendar-current-month');
  const status = document.getElementById('calendar-status');
  const emptyMonth = document.getElementById('calendar-empty-month');
  const previousButton = document.getElementById('calendar-prev');
  const nextButton = document.getElementById('calendar-next');
  const todayButton = document.getElementById('calendar-today');
  const dateForm = document.getElementById('calendar-date-form');
  const dateInput = document.getElementById('calendar-date');
  const drawerLayer = document.getElementById('calendar-day-drawer');
  const drawer = drawerLayer?.querySelector('.calendar-drawer');
  const drawerBackdrop = drawerLayer?.querySelector('.calendar-drawer-backdrop');
  const drawerClose = drawerLayer?.querySelector('.calendar-drawer-close');
  const drawerTitle = document.getElementById('calendar-day-title');
  const drawerContent = document.getElementById('calendar-day-content');

  if (!calendar || !monthTitle || !status || !emptyMonth || !previousButton || !nextButton || !todayButton || !dateForm || !dateInput || !drawerLayer || !drawer || !drawerBackdrop || !drawerClose || !drawerTitle || !drawerContent) {
    return;
  }

  const monthFormatter = new Intl.DateTimeFormat('fr-FR', { month: 'long', year: 'numeric' });
  const fullDateFormatter = new Intl.DateTimeFormat('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

  const pad = value => String(value).padStart(2, '0');
  const capitalize = value => value.charAt(0).toUpperCase() + value.slice(1);

  const dateKeyFromDate = date => `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;

  const dateFromKey = dateKey => {
    const [year, month, day] = dateKey.split('-').map(Number);
    return new Date(year, month - 1, day, 12);
  };

  const displayLocalTime = value => {
    const match = /^(\d{2}):(\d{2})/.exec(value);
    return match ? `${match[1]}h${match[2]}` : value;
  };

  const safeFfbbUrl = value => {
    if (!value) return null;
    try {
      const url = new URL(value);
      return url.protocol === 'https:' && url.hostname === 'competitions.ffbb.com' ? url.href : null;
    } catch {
      return null;
    }
  };

  const locationLabel = homeAway => {
    if (homeAway === 'home') return 'Domicile';
    if (homeAway === 'away') return 'Extérieur';
    return 'Lieu à confirmer';
  };

  const normalizeCalendarEntry = item => {
    const localDate = String(item.local_date || '').trim();
    const localTime = String(item.local_time || '').trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(localDate) || !/^\d{2}:\d{2}/.test(localTime)) return null;
    return {
      type: 'match',
      teamCode: String(item.team_code || 'Équipe').trim(),
      opponentName: String(item.opponent_name || 'Adversaire à confirmer').trim(),
      homeAway: item.home_away,
      localDate,
      localTime,
      venueName: item.venue_name ? String(item.venue_name).trim() : '',
      venueAddress: item.venue_address ? String(item.venue_address).trim() : '',
      roundLabel: item.round_label ? String(item.round_label).trim() : '',
      ffbbMatchUrl: safeFfbbUrl(item.ffbb_match_url),
      ffbbTeamUrl: safeFfbbUrl(item.ffbb_team_url)
    };
  };

  const today = new Date();
  let displayedYear = today.getFullYear();
  let displayedMonth = today.getMonth();
  let selectedDateKey = null;
  let requestSequence = 0;
  let openDrawerAfterRender = false;
  let drawerTrigger = null;

  const setStatus = (message, isError = false) => {
    status.textContent = message;
    status.classList.toggle('is-error', isError);
  };

  const createElement = (tagName, className, text) => {
    const element = document.createElement(tagName);
    if (className) element.className = className;
    if (text !== undefined) element.textContent = text;
    return element;
  };

  const pluralLabel = (count, singular, plural) => `${count} ${count > 1 ? plural : singular}`;

  const groupEventsByDate = events => {
    const groups = new Map();
    events.forEach(event => {
      const key = event.localDate;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(event);
    });
    return groups;
  };

  const groupEventsByType = events => ({
    match: events.filter(event => event.type === 'match'),
    training: events.filter(event => event.type === 'training'),
    event: events.filter(event => event.type === 'event')
  });

  const appendDetailRow = (container, label, value, linkUrl = null) => {
    if (!value) return;
    const row = createElement('div', 'calendar-detail-row');
    row.append(createElement('span', 'calendar-detail-label', label));
    if (linkUrl) {
      const link = createElement('a', 'calendar-detail-value calendar-detail-link', value);
      link.href = linkUrl;
      link.target = '_blank';
      link.rel = 'noopener';
      row.append(link);
    } else {
      row.append(createElement('span', 'calendar-detail-value', value));
    }
    container.append(row);
  };

  const createMatchCard = event => {
    const card = createElement('article', `calendar-day-item is-match ${event.homeAway === 'away' ? 'is-away' : 'is-home'}`);
    const heading = createElement('h5', 'calendar-day-item-title');
    heading.append(
      createElement('span', '', event.teamCode),
      createElement('time', 'calendar-day-item-time', displayLocalTime(event.localTime))
    );
    const details = createElement('div', 'calendar-day-item-details');
    appendDetailRow(details, 'Adversaire', event.opponentName);
    appendDetailRow(details, 'Rencontre', locationLabel(event.homeAway));
    appendDetailRow(details, 'Gymnase', event.venueName);
    appendDetailRow(details, 'Adresse', event.venueAddress);
    appendDetailRow(details, 'Journée', event.roundLabel);
    const ffbbUrl = event.ffbbMatchUrl || event.ffbbTeamUrl;
    const ffbbLabel = event.ffbbMatchUrl ? 'Voir la fiche du match' : 'Voir la fiche de l’équipe';
    appendDetailRow(details, 'FFBB', ffbbUrl ? ffbbLabel : '', ffbbUrl);
    card.append(heading, details);
    return card;
  };

  const createGenericCard = (event, typeClass) => {
    const card = createElement('article', `calendar-day-item ${typeClass}`);
    card.append(createElement('h5', 'calendar-day-item-title', event.title || 'Information à venir'));
    return card;
  };

  const createDayGroup = (title, events, type) => {
    if (!events.length) return null;
    const section = createElement('section', 'calendar-day-group');
    const heading = createElement('h4', 'calendar-day-group-title');
    heading.append(createElement('span', '', title), createElement('span', 'calendar-group-count', String(events.length)));
    section.append(heading);
    events.forEach(event => {
      if (type === 'match') section.append(createMatchCard(event));
      if (type === 'training') section.append(createGenericCard(event, 'is-training'));
      if (type === 'event') section.append(createGenericCard(event, 'is-event'));
    });
    return section;
  };

  const closeDayDrawer = () => {
    if (drawerLayer.hidden) return;
    drawerLayer.hidden = true;
    document.body.classList.remove('calendar-drawer-open');
    const trigger = drawerTrigger;
    drawerTrigger = null;
    trigger?.focus();
  };

  const openDayDrawer = (dateKey, events, trigger = null) => {
    selectedDateKey = dateKey;
    drawerTrigger = trigger;
    calendar.querySelectorAll('.calendar-day').forEach(day => day.classList.toggle('is-selected', day.dataset.date === dateKey));
    const groups = groupEventsByType(events);
    drawerTitle.textContent = `Journée du ${fullDateFormatter.format(dateFromKey(dateKey))}`;
    const dayGroups = [
      createDayGroup('Matchs', groups.match, 'match'),
      createDayGroup('Entraînements', groups.training, 'training'),
      createDayGroup('Événements', groups.event, 'event')
    ].filter(Boolean);
    drawerContent.replaceChildren(...dayGroups);
    drawerLayer.hidden = false;
    document.body.classList.add('calendar-drawer-open');
    drawer.focus();
  };

  const createCount = (count, singular, plural, typeClass) => {
    const indicator = createElement('span', `calendar-count ${typeClass}`);
    indicator.append(createElement('strong', '', String(count)), createElement('span', '', count > 1 ? plural : singular));
    return indicator;
  };

  const createDaySummary = events => {
    const groups = groupEventsByType(events);
    const summary = createElement('span', 'calendar-day-summary');
    if (groups.match.length) summary.append(createCount(groups.match.length, 'match', 'matchs', 'is-match'));
    if (groups.training.length) summary.append(createCount(groups.training.length, 'entraînement', 'entraînements', 'is-training'));
    if (groups.event.length) summary.append(createCount(groups.event.length, 'événement', 'événements', 'is-event'));
    const teams = [...new Set(groups.match.map(event => event.teamCode))];
    if (teams.length) {
      const badges = createElement('span', 'calendar-team-badges');
      teams.slice(0, 3).forEach(team => badges.append(createElement('span', 'calendar-team-badge', team)));
      if (teams.length > 3) badges.append(createElement('span', 'calendar-team-badge', `+${teams.length - 3}`));
      summary.append(badges);
    }
    return summary;
  };

  const renderCalendar = events => {
    const groupedEvents = groupEventsByDate(events);
    const monthDate = new Date(displayedYear, displayedMonth, 15, 12);
    const firstDay = new Date(displayedYear, displayedMonth, 1, 12);
    const mondayOffset = (firstDay.getDay() + 6) % 7;
    const gridStart = new Date(firstDay);
    gridStart.setDate(firstDay.getDate() - mondayOffset);
    const todayKey = dateKeyFromDate(new Date());
    let currentMonthEventCount = 0;

    monthTitle.textContent = capitalize(monthFormatter.format(monthDate));
    calendar.replaceChildren();

    for (let index = 0; index < 42; index += 1) {
      const cellDate = new Date(gridStart);
      cellDate.setDate(gridStart.getDate() + index);
      const dayKey = dateKeyFromDate(cellDate);
      const dayEvents = groupedEvents.get(dayKey) || [];
      const isCurrentMonth = cellDate.getMonth() === displayedMonth;
      const groups = groupEventsByType(dayEvents);
      if (isCurrentMonth) currentMonthEventCount += dayEvents.length;

      const day = createElement('article', 'calendar-day');
      day.dataset.date = dayKey;
      day.setAttribute('role', 'gridcell');
      if (!isCurrentMonth) day.classList.add('is-outside');
      if (!dayEvents.length) day.classList.add('is-empty');
      if (dayKey === todayKey) day.classList.add('is-today');
      if (dayKey === selectedDateKey) day.classList.add('is-selected');

      const dayButton = createElement('button', 'calendar-day-button');
      dayButton.type = 'button';
      if (dayKey === todayKey) dayButton.setAttribute('aria-current', 'date');
      dayButton.setAttribute('aria-label', `${capitalize(fullDateFormatter.format(cellDate))}, ${pluralLabel(groups.match.length, 'match', 'matchs')}, ${pluralLabel(groups.training.length, 'entraînement', 'entraînements')}, ${pluralLabel(groups.event.length, 'événement', 'événements')}`);
      const dayNumber = createElement('time', 'calendar-day-number', String(cellDate.getDate()));
      dayNumber.dateTime = dayKey;
      dayButton.append(dayNumber);
      if (dayEvents.length) dayButton.append(createDaySummary(dayEvents));
      dayButton.addEventListener('click', () => openDayDrawer(dayKey, dayEvents, dayButton));
      day.append(dayButton);
      calendar.append(day);
    }

    emptyMonth.classList.toggle('is-visible', currentMonthEventCount === 0);
    setStatus(currentMonthEventCount === 0
      ? 'Aucune rencontre publiée pour ce mois.'
      : `${currentMonthEventCount} rencontre${currentMonthEventCount > 1 ? 's' : ''} publiée${currentMonthEventCount > 1 ? 's' : ''} pour ce mois.`);

    if (selectedDateKey) {
      const selectedDay = calendar.querySelector(`[data-date="${selectedDateKey}"]`);
      if (selectedDay) selectedDay.scrollIntoView({ behavior: 'smooth', block: 'center' });
      if (openDrawerAfterRender) {
        openDrawerAfterRender = false;
        openDayDrawer(selectedDateKey, groupedEvents.get(selectedDateKey) || [], selectedDay?.querySelector('.calendar-day-button') || null);
      }
    }
  };

  const fetchMonthEvents = async () => {
    const requestId = ++requestSequence;
    setStatus('Chargement du calendrier…');
    emptyMonth.classList.remove('is-visible');
    const rangeStart = `${displayedYear}-${pad(displayedMonth + 1)}-01`;
    const nextMonth = new Date(displayedYear, displayedMonth + 1, 1);
    const rangeEnd = dateKeyFromDate(nextMonth);
    const url = new URL(`${SUPABASE_URL}/rest/v1/${CALENDAR_VIEW}`);
    url.searchParams.set('select', SELECT_FIELDS);
    url.searchParams.append('local_date', `gte.${rangeStart}`);
    url.searchParams.append('local_date', `lt.${rangeEnd}`);
    url.searchParams.set('order', 'local_date.asc,local_time.asc');

    try {
      const response = await fetch(url, { headers: { apikey: SUPABASE_PUBLISHABLE_KEY, Accept: 'application/json' } });
      if (!response.ok) throw new Error(`Réponse Supabase ${response.status}`);
      const payload = await response.json();
      if (!Array.isArray(payload)) throw new Error('Format de réponse inattendu');
      if (requestId !== requestSequence) return;
      renderCalendar(payload.map(normalizeCalendarEntry).filter(Boolean));
    } catch (error) {
      if (requestId !== requestSequence) return;
      renderCalendar([]);
      setStatus('Le calendrier est temporairement indisponible. Utilisez les liens FFBB ci-dessous.', true);
      console.error('Chargement du calendrier impossible :', error);
    }
  };

  const changeMonth = offset => {
    const nextMonth = new Date(displayedYear, displayedMonth + offset, 1, 12);
    displayedYear = nextMonth.getFullYear();
    displayedMonth = nextMonth.getMonth();
    selectedDateKey = null;
    closeDayDrawer();
    fetchMonthEvents();
  };

  previousButton.addEventListener('click', () => changeMonth(-1));
  nextButton.addEventListener('click', () => changeMonth(1));
  todayButton.addEventListener('click', () => {
    const currentDate = new Date();
    displayedYear = currentDate.getFullYear();
    displayedMonth = currentDate.getMonth();
    selectedDateKey = dateKeyFromDate(currentDate);
    dateInput.value = selectedDateKey;
    openDrawerAfterRender = true;
    fetchMonthEvents();
  });

  dateForm.addEventListener('submit', event => {
    event.preventDefault();
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateInput.value);
    if (!match) {
      setStatus('Choisissez une date valide.', true);
      return;
    }
    displayedYear = Number(match[1]);
    displayedMonth = Number(match[2]) - 1;
    selectedDateKey = dateInput.value;
    openDrawerAfterRender = true;
    fetchMonthEvents();
  });

  drawerBackdrop.addEventListener('click', closeDayDrawer);
  drawerClose.addEventListener('click', closeDayDrawer);
  document.addEventListener('keydown', event => {
    if (drawerLayer.hidden) return;
    if (event.key === 'Escape') {
      closeDayDrawer();
      return;
    }
    if (event.key !== 'Tab') return;
    const focusableElements = [...drawer.querySelectorAll('a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])')];
    if (!focusableElements.length) {
      event.preventDefault();
      drawer.focus();
      return;
    }
    const firstFocusable = focusableElements[0];
    const lastFocusable = focusableElements[focusableElements.length - 1];
    if (event.shiftKey && document.activeElement === firstFocusable) {
      event.preventDefault();
      lastFocusable.focus();
    } else if (!event.shiftKey && document.activeElement === lastFocusable) {
      event.preventDefault();
      firstFocusable.focus();
    }
  });

  fetchMonthEvents();
})();
