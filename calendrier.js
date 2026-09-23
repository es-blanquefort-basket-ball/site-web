(() => {
  'use strict';

  const SUPABASE_URL = 'https://fgswygeqstgagmipltpq.supabase.co';
  const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_dsoHXhS222GToiMUIpGkCA_lFPAJm-A';
  const CALENDAR_VIEW = 'public_calendar';
  const TIME_ZONE = 'Europe/Paris';
  const SELECT_FIELDS = [
    'team_code',
    'opponent_name',
    'home_away',
    'starts_at',
    'venue_name',
    'round_label',
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
  const dialog = document.getElementById('calendar-dialog');
  const dialogBody = document.getElementById('calendar-dialog-body');

  if (!calendar || !monthTitle || !status || !emptyMonth || !previousButton || !nextButton || !todayButton || !dateForm || !dateInput || !dialog || !dialogBody) {
    return;
  }

  const monthFormatter = new Intl.DateTimeFormat('fr-FR', {
    month: 'long',
    year: 'numeric',
    timeZone: TIME_ZONE
  });
  const fullDateFormatter = new Intl.DateTimeFormat('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: TIME_ZONE
  });
  const timeFormatter = new Intl.DateTimeFormat('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
    timeZone: TIME_ZONE
  });

  const pad = value => String(value).padStart(2, '0');
  const capitalize = value => value.charAt(0).toUpperCase() + value.slice(1);

  const zonedParts = date => {
    const parts = new Intl.DateTimeFormat('fr-FR', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      timeZone: TIME_ZONE
    }).formatToParts(date);
    const values = Object.fromEntries(parts.map(part => [part.type, part.value]));
    return {
      year: Number(values.year),
      month: Number(values.month),
      day: Number(values.day)
    };
  };

  const dateKeyInParis = date => {
    const parts = zonedParts(date);
    return `${parts.year}-${pad(parts.month)}-${pad(parts.day)}`;
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
    const startsAt = new Date(item.starts_at);
    if (Number.isNaN(startsAt.getTime())) return null;

    return {
      type: 'match',
      teamCode: String(item.team_code || 'Équipe').trim(),
      opponentName: String(item.opponent_name || 'Adversaire à confirmer').trim(),
      homeAway: item.home_away,
      startsAt,
      venueName: item.venue_name ? String(item.venue_name).trim() : '',
      roundLabel: item.round_label ? String(item.round_label).trim() : '',
      ffbbTeamUrl: safeFfbbUrl(item.ffbb_team_url)
    };
  };

  const todayParts = zonedParts(new Date());
  let displayedYear = todayParts.year;
  let displayedMonth = todayParts.month - 1;
  let selectedDateKey = null;
  let requestSequence = 0;

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

  const appendDetailRow = (label, value, linkUrl = null) => {
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
    dialogBody.append(row);
  };

  const showEventDetails = event => {
    dialogBody.replaceChildren();
    appendDetailRow('Équipe', event.teamCode);
    appendDetailRow('Adversaire', event.opponentName);
    appendDetailRow('Date', capitalize(fullDateFormatter.format(event.startsAt)));
    appendDetailRow('Horaire', timeFormatter.format(event.startsAt).replace(':', 'h'));
    appendDetailRow('Rencontre', locationLabel(event.homeAway));
    appendDetailRow('Gymnase', event.venueName);
    appendDetailRow('Journée', event.roundLabel);
    appendDetailRow('FFBB', event.ffbbTeamUrl ? 'Voir la fiche de l’équipe' : '', event.ffbbTeamUrl);

    if (typeof dialog.showModal === 'function') {
      dialog.showModal();
    } else {
      dialog.setAttribute('open', '');
    }
  };

  const createEventButton = event => {
    const button = createElement('button', 'calendar-event');
    button.type = 'button';
    button.setAttribute('aria-label', `${event.teamCode}, ${timeFormatter.format(event.startsAt)}, contre ${event.opponentName}, ${locationLabel(event.homeAway)}`);

    const top = createElement('span', 'calendar-event-top');
    top.append(
      createElement('span', '', event.teamCode),
      createElement('time', '', timeFormatter.format(event.startsAt).replace(':', 'h'))
    );
    const opponent = createElement('span', 'calendar-event-opponent', event.opponentName);
    const place = createElement('span', 'calendar-event-place', locationLabel(event.homeAway));
    button.append(top, opponent, place);
    button.addEventListener('click', () => showEventDetails(event));
    return button;
  };

  const groupEventsByDate = events => {
    const groups = new Map();
    events.forEach(event => {
      const key = dateKeyInParis(event.startsAt);
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(event);
    });
    return groups;
  };

  const renderCalendar = events => {
    const groupedEvents = groupEventsByDate(events);
    const monthDate = new Date(Date.UTC(displayedYear, displayedMonth, 15, 12));
    const firstDay = new Date(Date.UTC(displayedYear, displayedMonth, 1, 12));
    const mondayOffset = (firstDay.getUTCDay() + 6) % 7;
    const gridStart = new Date(firstDay);
    gridStart.setUTCDate(firstDay.getUTCDate() - mondayOffset);
    const todayKey = dateKeyInParis(new Date());
    let currentMonthEventCount = 0;

    monthTitle.textContent = capitalize(monthFormatter.format(monthDate));
    calendar.replaceChildren();

    for (let index = 0; index < 42; index += 1) {
      const cellDate = new Date(gridStart);
      cellDate.setUTCDate(gridStart.getUTCDate() + index);
      const dayKey = cellDate.toISOString().slice(0, 10);
      const dayEvents = groupedEvents.get(dayKey) || [];
      const isCurrentMonth = cellDate.getUTCMonth() === displayedMonth;

      if (isCurrentMonth) currentMonthEventCount += dayEvents.length;

      const day = createElement('article', 'calendar-day');
      day.dataset.date = dayKey;
      day.setAttribute('role', 'gridcell');
      day.setAttribute('aria-label', capitalize(fullDateFormatter.format(cellDate)));
      if (!isCurrentMonth) day.classList.add('is-outside');
      if (!dayEvents.length) day.classList.add('is-empty');
      if (dayKey === todayKey) day.classList.add('is-today');
      if (dayKey === selectedDateKey) day.classList.add('is-selected');

      const dayNumber = createElement('time', 'calendar-day-number', String(cellDate.getUTCDate()));
      dayNumber.dateTime = dayKey;
      const eventList = createElement('div', 'calendar-events');
      dayEvents.forEach(event => eventList.append(createEventButton(event)));
      day.append(dayNumber, eventList);
      calendar.append(day);
    }

    emptyMonth.classList.toggle('is-visible', currentMonthEventCount === 0);
    setStatus(currentMonthEventCount === 0
      ? 'Aucune rencontre publiée pour ce mois.'
      : `${currentMonthEventCount} rencontre${currentMonthEventCount > 1 ? 's' : ''} publiée${currentMonthEventCount > 1 ? 's' : ''} pour ce mois.`);

    if (selectedDateKey) {
      const selectedDay = calendar.querySelector(`[data-date="${selectedDateKey}"]`);
      if (selectedDay) selectedDay.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  };

  const fetchMonthEvents = async () => {
    const requestId = ++requestSequence;
    setStatus('Chargement du calendrier…');
    emptyMonth.classList.remove('is-visible');

    const rangeStart = new Date(Date.UTC(displayedYear, displayedMonth, 0, 0, 0, 0));
    const rangeEnd = new Date(Date.UTC(displayedYear, displayedMonth + 1, 2, 0, 0, 0));
    const url = new URL(`${SUPABASE_URL}/rest/v1/${CALENDAR_VIEW}`);
    url.searchParams.set('select', SELECT_FIELDS);
    url.searchParams.append('starts_at', `gte.${rangeStart.toISOString()}`);
    url.searchParams.append('starts_at', `lt.${rangeEnd.toISOString()}`);
    url.searchParams.set('order', 'starts_at.asc');

    try {
      const response = await fetch(url, {
        headers: {
          apikey: SUPABASE_PUBLISHABLE_KEY,
          Accept: 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`Réponse Supabase ${response.status}`);
      }

      const payload = await response.json();
      if (!Array.isArray(payload)) {
        throw new Error('Format de réponse inattendu');
      }

      if (requestId !== requestSequence) return;
      const events = payload.map(normalizeCalendarEntry).filter(Boolean);
      renderCalendar(events);
    } catch (error) {
      if (requestId !== requestSequence) return;
      renderCalendar([]);
      setStatus('Le calendrier est temporairement indisponible. Utilisez les liens FFBB ci-dessous.', true);
      console.error('Chargement du calendrier impossible :', error);
    }
  };

  const changeMonth = offset => {
    const nextMonth = new Date(Date.UTC(displayedYear, displayedMonth + offset, 1, 12));
    displayedYear = nextMonth.getUTCFullYear();
    displayedMonth = nextMonth.getUTCMonth();
    selectedDateKey = null;
    fetchMonthEvents();
  };

  previousButton.addEventListener('click', () => changeMonth(-1));
  nextButton.addEventListener('click', () => changeMonth(1));
  todayButton.addEventListener('click', () => {
    const parts = zonedParts(new Date());
    displayedYear = parts.year;
    displayedMonth = parts.month - 1;
    selectedDateKey = `${parts.year}-${pad(parts.month)}-${pad(parts.day)}`;
    dateInput.value = selectedDateKey;
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
    fetchMonthEvents();
  });

  fetchMonthEvents();
})();
