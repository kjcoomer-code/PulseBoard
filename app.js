const sampleAppleWorkouts = [
  { date: "2026-02-16", type: "Outdoor Run", durationMinutes: 44, activeCalories: 508, distanceMiles: 5.2, averageHeartRate: 152, source: "apple" },
  { date: "2026-02-17", type: "Strength", durationMinutes: 38, activeCalories: 321, distanceMiles: 0, averageHeartRate: 118, source: "apple" },
  { date: "2026-02-19", type: "Cycling", durationMinutes: 62, activeCalories: 612, distanceMiles: 18.4, averageHeartRate: 145, source: "apple" },
  { date: "2026-02-20", type: "Walk", durationMinutes: 34, activeCalories: 184, distanceMiles: 2.1, averageHeartRate: 102, source: "apple" },
  { date: "2026-02-22", type: "HIIT", durationMinutes: 29, activeCalories: 356, distanceMiles: 0, averageHeartRate: 154, source: "apple" },
  { date: "2026-02-24", type: "Outdoor Run", durationMinutes: 47, activeCalories: 534, distanceMiles: 5.5, averageHeartRate: 149, source: "apple" },
  { date: "2026-02-25", type: "Strength", durationMinutes: 41, activeCalories: 346, distanceMiles: 0, averageHeartRate: 121, source: "apple" },
  { date: "2026-02-27", type: "Cycling", durationMinutes: 71, activeCalories: 648, distanceMiles: 20.3, averageHeartRate: 146, source: "apple" },
  { date: "2026-03-01", type: "Yoga", durationMinutes: 26, activeCalories: 126, distanceMiles: 0, averageHeartRate: 88, source: "apple" },
  { date: "2026-03-03", type: "Outdoor Run", durationMinutes: 50, activeCalories: 560, distanceMiles: 5.8, averageHeartRate: 151, source: "apple" },
  { date: "2026-03-05", type: "Strength", durationMinutes: 45, activeCalories: 362, distanceMiles: 0, averageHeartRate: 124, source: "apple" },
  { date: "2026-03-07", type: "Walk", durationMinutes: 56, activeCalories: 278, distanceMiles: 3.4, averageHeartRate: 96, source: "apple" }
];

const sampleOuraDaily = [
  { date: "2026-02-16", readinessScore: 76, sleepScore: 81, activityScore: 84, hrv: 42, restingHeartRate: 56, steps: 11102 },
  { date: "2026-02-17", readinessScore: 72, sleepScore: 79, activityScore: 78, hrv: 40, restingHeartRate: 57, steps: 9208 },
  { date: "2026-02-18", readinessScore: 83, sleepScore: 86, activityScore: 73, hrv: 51, restingHeartRate: 53, steps: 8050 },
  { date: "2026-02-19", readinessScore: 71, sleepScore: 76, activityScore: 88, hrv: 39, restingHeartRate: 58, steps: 12660 },
  { date: "2026-02-20", readinessScore: 82, sleepScore: 84, activityScore: 75, hrv: 47, restingHeartRate: 54, steps: 10026 },
  { date: "2026-02-21", readinessScore: 87, sleepScore: 88, activityScore: 71, hrv: 55, restingHeartRate: 51, steps: 7340 },
  { date: "2026-02-22", readinessScore: 69, sleepScore: 72, activityScore: 86, hrv: 37, restingHeartRate: 59, steps: 13444 },
  { date: "2026-02-23", readinessScore: 85, sleepScore: 87, activityScore: 68, hrv: 57, restingHeartRate: 50, steps: 7011 },
  { date: "2026-02-24", readinessScore: 77, sleepScore: 80, activityScore: 83, hrv: 44, restingHeartRate: 55, steps: 11502 },
  { date: "2026-02-25", readinessScore: 74, sleepScore: 78, activityScore: 79, hrv: 41, restingHeartRate: 56, steps: 9644 },
  { date: "2026-02-26", readinessScore: 88, sleepScore: 89, activityScore: 70, hrv: 58, restingHeartRate: 50, steps: 6882 },
  { date: "2026-02-27", readinessScore: 73, sleepScore: 75, activityScore: 87, hrv: 40, restingHeartRate: 57, steps: 12004 },
  { date: "2026-02-28", readinessScore: 81, sleepScore: 83, activityScore: 74, hrv: 49, restingHeartRate: 53, steps: 8443 },
  { date: "2026-03-01", readinessScore: 90, sleepScore: 91, activityScore: 67, hrv: 60, restingHeartRate: 49, steps: 6082 },
  { date: "2026-03-02", readinessScore: 84, sleepScore: 85, activityScore: 72, hrv: 52, restingHeartRate: 52, steps: 7641 },
  { date: "2026-03-03", readinessScore: 75, sleepScore: 77, activityScore: 85, hrv: 43, restingHeartRate: 56, steps: 11808 },
  { date: "2026-03-04", readinessScore: 86, sleepScore: 88, activityScore: 69, hrv: 56, restingHeartRate: 50, steps: 6702 },
  { date: "2026-03-05", readinessScore: 74, sleepScore: 76, activityScore: 82, hrv: 42, restingHeartRate: 57, steps: 10385 },
  { date: "2026-03-06", readinessScore: 89, sleepScore: 90, activityScore: 68, hrv: 61, restingHeartRate: 49, steps: 5901 },
  { date: "2026-03-07", readinessScore: 80, sleepScore: 82, activityScore: 76, hrv: 48, restingHeartRate: 54, steps: 9580 }
];

const sampleOuraWorkouts = [
  { date: "2026-03-02", type: "Walking", durationMinutes: 32, activeCalories: 180, distanceMiles: 1.8, averageHeartRate: 98, source: "oura-workout" },
  { date: "2026-03-06", type: "Breathing Session", durationMinutes: 12, activeCalories: 0, distanceMiles: 0, averageHeartRate: 0, source: "oura-session" }
];

const state = {
  appleWorkouts: [],
  ouraWorkouts: [],
  ouraDaily: [],
  ouraConnected: false,
  ouraLoading: false,
  serverConfigured: false,
  lastSync: "",
  authenticated: false,
  hasUsers: false,
  user: null
};

const authScreen = document.querySelector("#authScreen");
const appShell = document.querySelector("#appShell");
const authMessage = document.querySelector("#authMessage");
const loginForm = document.querySelector("#loginForm");
const registerForm = document.querySelector("#registerForm");
const showLoginBtn = document.querySelector("#showLoginBtn");
const showRegisterBtn = document.querySelector("#showRegisterBtn");
const logoutBtn = document.querySelector("#logoutBtn");
const userGreeting = document.querySelector("#userGreeting");

const appleInput = document.querySelector("#appleInput");
const ouraInput = document.querySelector("#ouraInput");
const appleStatus = document.querySelector("#appleStatus");
const ouraStatus = document.querySelector("#ouraStatus");
const statsGrid = document.querySelector("#statsGrid");
const chart = document.querySelector("#chart");
const milestones = document.querySelector("#milestones");
const timelineBody = document.querySelector("#timelineBody");
const heroScore = document.querySelector("#heroScore");
const heroSummary = document.querySelector("#heroSummary");
const ouraConnectionStatus = document.querySelector("#ouraConnectionStatus");
const connectOuraBtn = document.querySelector("#connectOuraBtn");
const syncOuraBtn = document.querySelector("#syncOuraBtn");
const disconnectOuraBtn = document.querySelector("#disconnectOuraBtn");

showLoginBtn.addEventListener("click", () => setAuthMode("login"));
showRegisterBtn.addEventListener("click", () => setAuthMode("register"));
logoutBtn.addEventListener("click", logout);

loginForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const email = document.querySelector("#loginEmail").value.trim();
  const password = document.querySelector("#loginPassword").value;
  await submitAuth("/api/auth/login", { email, password }, "Signing in...");
});

registerForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const name = document.querySelector("#registerName").value.trim();
  const email = document.querySelector("#registerEmail").value.trim();
  const password = document.querySelector("#registerPassword").value;
  await submitAuth("/api/auth/register", { name, email, password }, "Creating account...");
});

document.querySelector("#loadSampleBtn").addEventListener("click", () => {
  state.appleWorkouts = normalizeApple(sampleAppleWorkouts);
  state.ouraDaily = normalizeOura(sampleOuraDaily);
  state.ouraWorkouts = normalizeWorkouts(sampleOuraWorkouts, "oura");
  appleStatus.textContent = `${state.appleWorkouts.length} sample workouts loaded`;
  ouraStatus.textContent = `${state.ouraDaily.length} sample daily entries and ${state.ouraWorkouts.length} Oura activity items loaded`;
  render();
});

document.querySelector("#clearDataBtn").addEventListener("click", () => {
  state.appleWorkouts = [];
  state.ouraWorkouts = [];
  state.ouraDaily = [];
  appleInput.value = "";
  ouraInput.value = "";
  appleStatus.textContent = "No file loaded";
  ouraStatus.textContent = "No file loaded";
  render();
});

connectOuraBtn.addEventListener("click", async () => {
  try {
    const response = await fetch("/auth/oura/url");
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || "Could not start Oura auth.");
    }
    window.location.href = payload.authorizationUrl;
  } catch (error) {
    ouraConnectionStatus.textContent = error.message;
  }
});

syncOuraBtn.addEventListener("click", async () => {
  await syncOuraData();
});

disconnectOuraBtn.addEventListener("click", async () => {
  try {
    const response = await fetch("/api/oura/disconnect", { method: "POST" });
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || "Could not disconnect Oura.");
    }
    state.ouraConnected = false;
    state.ouraDaily = [];
    state.ouraWorkouts = [];
    state.lastSync = "";
    ouraStatus.textContent = "Disconnected from Oura";
    await refreshOuraStatus();
    render();
  } catch (error) {
    ouraConnectionStatus.textContent = error.message;
  }
});

appleInput.addEventListener("change", async (event) => {
  const file = event.target.files?.[0];
  if (!file) {
    return;
  }

  try {
    const json = JSON.parse(await file.text());
    state.appleWorkouts = normalizeApple(json);
    appleStatus.textContent = `${state.appleWorkouts.length} workouts from ${file.name}`;
    render();
  } catch (error) {
    appleStatus.textContent = `Could not read ${file.name}`;
    console.error(error);
  }
});

ouraInput.addEventListener("change", async (event) => {
  const file = event.target.files?.[0];
  if (!file) {
    return;
  }

  try {
    const json = JSON.parse(await file.text());
    state.ouraDaily = normalizeOura(json.daily ?? json);
    state.ouraWorkouts = normalizeWorkouts(json.workouts ?? json.sessions ?? [], "oura");
    ouraStatus.textContent = `${state.ouraDaily.length} daily entries from ${file.name}`;
    render();
  } catch (error) {
    ouraStatus.textContent = `Could not read ${file.name}`;
    console.error(error);
  }
});

function setAuthMode(mode) {
  const loginMode = mode === "login";
  loginForm.classList.toggle("hidden", !loginMode);
  registerForm.classList.toggle("hidden", loginMode);
  showLoginBtn.classList.toggle("primary", loginMode);
  showLoginBtn.classList.toggle("secondary", !loginMode);
  showRegisterBtn.classList.toggle("primary", !loginMode);
  showRegisterBtn.classList.toggle("secondary", loginMode);
  if (state.hasUsers) {
    authMessage.textContent = loginMode ? "Sign in to continue." : "Create another local account.";
  } else {
    authMessage.textContent = "Create the first local PulseBoard account.";
    registerForm.classList.remove("hidden");
    loginForm.classList.add("hidden");
  }
}

async function submitAuth(url, body, busyMessage) {
  authMessage.textContent = busyMessage;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    });
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || "Authentication failed.");
    }
    await bootstrapAuth();
  } catch (error) {
    authMessage.textContent = error.message;
  }
}

async function logout() {
  await fetch("/api/auth/logout", { method: "POST" });
  state.authenticated = false;
  state.user = null;
  authScreen.classList.remove("hidden");
  appShell.classList.add("hidden");
  await bootstrapAuth();
}

async function bootstrapAuth() {
  try {
    const response = await fetch("/api/auth/status");
    const payload = await response.json();
    state.authenticated = Boolean(payload.authenticated);
    state.hasUsers = Boolean(payload.hasUsers);
    state.user = payload.user ?? null;

    if (state.authenticated) {
      authScreen.classList.add("hidden");
      appShell.classList.remove("hidden");
      userGreeting.textContent = `Signed in as ${state.user.name}`;
      authMessage.textContent = "";
      await refreshOuraStatus();
      render();
    } else {
      authScreen.classList.remove("hidden");
      appShell.classList.add("hidden");
      setAuthMode(payload.hasUsers ? "login" : "register");
    }
  } catch (error) {
    authMessage.textContent = "Could not reach the PulseBoard server. Start server.ps1 and refresh the page.";
  }
}

async function refreshOuraStatus() {
  try {
    const response = await fetch("/api/oura/status");
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || "Could not read Oura status.");
    }
    state.serverConfigured = Boolean(payload.configured);
    state.ouraConnected = Boolean(payload.connected);
    state.lastSync = payload.lastSync ?? "";

    if (!payload.configured) {
      ouraConnectionStatus.textContent = "Server is missing oura-config.json. Add your client ID and secret, then restart the server.";
    } else if (payload.tokenReadError) {
      ouraConnectionStatus.textContent = payload.tokenReadError;
    } else if (payload.connected) {
      const scopeCopy = payload.scope ? ` Scopes: ${payload.scope}.` : "";
      const lastSyncCopy = payload.lastSync ? ` Last sync: ${new Date(payload.lastSync).toLocaleString()}.` : "";
      ouraConnectionStatus.textContent = `Connected to Oura.${scopeCopy}${lastSyncCopy}`;
    } else {
      ouraConnectionStatus.textContent = "Ready to connect. Use the button to start the Oura OAuth flow.";
    }

    connectOuraBtn.disabled = !payload.configured || payload.connected;
    syncOuraBtn.disabled = !payload.connected;
    disconnectOuraBtn.disabled = !payload.connected && !payload.tokenReadError;
  } catch (error) {
    state.serverConfigured = false;
    state.ouraConnected = false;
    ouraConnectionStatus.textContent = error.message;
    connectOuraBtn.disabled = true;
    syncOuraBtn.disabled = true;
    disconnectOuraBtn.disabled = true;
  }
}

async function syncOuraData() {
  if (state.ouraLoading) {
    return;
  }

  state.ouraLoading = true;
  syncOuraBtn.disabled = true;
  ouraConnectionStatus.textContent = "Syncing latest Oura daily data, workouts, and sessions...";

  try {
    const now = new Date();
    const endDate = now.toISOString().slice(0, 10);
    const startDate = new Date(now.getTime() - (1000 * 60 * 60 * 24 * 29)).toISOString().slice(0, 10);
    const response = await fetch(`/api/oura/summary?start_date=${startDate}&end_date=${endDate}`);
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || "Could not sync Oura data.");
    }

    state.ouraDaily = normalizeOura(payload.daily ?? []);
    state.ouraWorkouts = normalizeWorkouts(payload.workouts ?? [], "oura");
    state.lastSync = payload.lastSync ?? new Date().toISOString();
    const notes = payload.notes?.length ? ` ${payload.notes.join(" ")}` : "";
    ouraStatus.textContent = `${state.ouraDaily.length} live daily entries and ${state.ouraWorkouts.length} Oura activity items synced.${notes}`;
    await refreshOuraStatus();
    render();
  } catch (error) {
    ouraConnectionStatus.textContent = error.message;
  } finally {
    state.ouraLoading = false;
    syncOuraBtn.disabled = !state.ouraConnected;
  }
}

function normalizeApple(input) {
  return asArray(input)
    .map((item) => ({
      date: coerceDate(item.date ?? item.workoutDate ?? item.startDate),
      type: item.type ?? item.workoutType ?? "Workout",
      durationMinutes: Number(item.durationMinutes ?? item.duration ?? 0),
      activeCalories: Number(item.activeCalories ?? item.calories ?? item.energyBurned ?? 0),
      distanceMiles: Number(item.distanceMiles ?? item.distance ?? 0),
      averageHeartRate: Number(item.averageHeartRate ?? item.avgHeartRate ?? item.heartRate ?? 0),
      source: item.source ?? "apple"
    }))
    .filter((item) => item.date);
}

function normalizeWorkouts(input, defaultSource = "oura") {
  return asArray(input)
    .map((item) => ({
      date: coerceDate(item.date ?? item.day ?? item.workoutDate ?? item.summaryDate ?? item.start_datetime ?? item.startTime ?? item.timestamp),
      type: item.type ?? item.activity ?? item.workoutType ?? item.sessionType ?? item.name ?? "Workout",
      durationMinutes: Number(item.durationMinutes ?? item.duration ?? item.total_duration ?? item.duration_in_minutes ?? 0),
      activeCalories: Number(item.activeCalories ?? item.calories ?? item.energyBurned ?? item.total_calories ?? 0),
      distanceMiles: toMiles(item.distanceMiles ?? item.distance ?? item.total_distance ?? 0),
      averageHeartRate: Number(item.averageHeartRate ?? item.avgHeartRate ?? item.average_heart_rate ?? item.heartRate ?? 0),
      source: item.source ?? defaultSource
    }))
    .filter((item) => item.date && (item.durationMinutes > 0 || item.activeCalories > 0 || item.distanceMiles > 0 || item.type));
}

function normalizeOura(input) {
  return asArray(input)
    .map((item) => ({
      date: coerceDate(item.date ?? item.day ?? item.summaryDate ?? item.timestamp),
      readinessScore: Number(item.readinessScore ?? item.readiness ?? item.readiness_score ?? item.score ?? 0),
      sleepScore: Number(item.sleepScore ?? item.sleep ?? item.sleep_score ?? 0),
      activityScore: Number(item.activityScore ?? item.activity ?? item.activity_score ?? 0),
      hrv: Number(item.hrv ?? item.averageHrv ?? item.average_hrv ?? item.hrvBalance ?? 0),
      restingHeartRate: Number(item.restingHeartRate ?? item.rhr ?? item.lowestHeartRate ?? item.lowest_heart_rate ?? 0),
      steps: Number(item.steps ?? item.dailySteps ?? item.step_count ?? 0)
    }))
    .filter((item) => item.date);
}

function asArray(input) {
  if (Array.isArray(input)) {
    return input;
  }
  if (input?.workouts && Array.isArray(input.workouts)) {
    return input.workouts;
  }
  if (input?.daily && Array.isArray(input.daily)) {
    return input.daily;
  }
  if (input?.data && Array.isArray(input.data)) {
    return input.data;
  }
  return [];
}

function coerceDate(value) {
  if (!value) {
    return "";
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return "";
  }
  return parsed.toISOString().slice(0, 10);
}

function toMiles(value) {
  const distance = Number(value ?? 0);
  if (!distance) {
    return 0;
  }
  return distance > 100 ? Number((distance / 1609.34).toFixed(2)) : distance;
}

function render() {
  if (!state.authenticated) {
    return;
  }
  const combinedWorkouts = [...state.appleWorkouts, ...state.ouraWorkouts].sort((a, b) => a.date.localeCompare(b.date));
  const merged = mergeDaily(combinedWorkouts, state.ouraDaily);
  const metrics = calculateMetrics(merged, combinedWorkouts, state.ouraDaily);
  renderStats(metrics);
  renderChart(merged);
  renderMilestones(metrics);
  renderTimeline(merged);
  renderHero(metrics);
}

function mergeDaily(workouts, ouraDaily) {
  const byDate = new Map();
  for (const workout of workouts) {
    const current = byDate.get(workout.date) ?? emptyMergedDay(workout.date);
    current.workoutTypes.push(`${workout.type}${workout.source === "apple" ? "" : " (Oura)"}`);
    current.workoutCount += 1;
    current.minutes += workout.durationMinutes;
    current.calories += workout.activeCalories;
    current.distance += workout.distanceMiles;
    current.avgHeartRate = Math.max(current.avgHeartRate, workout.averageHeartRate);
    current.strainScore += Math.round((workout.durationMinutes * 0.7) + (workout.activeCalories * 0.03) + (workout.averageHeartRate * 0.18));
    byDate.set(workout.date, current);
  }
  for (const day of ouraDaily) {
    const current = byDate.get(day.date) ?? emptyMergedDay(day.date);
    current.readinessScore = day.readinessScore;
    current.sleepScore = day.sleepScore;
    current.activityScore = day.activityScore;
    current.hrv = day.hrv;
    current.restingHeartRate = day.restingHeartRate;
    current.steps = day.steps;
    current.recoveryScore = Math.round((day.readinessScore * 0.45) + (day.sleepScore * 0.25) + (Math.min(day.hrv, 70) * 0.7) - (day.restingHeartRate * 0.3));
    byDate.set(day.date, current);
  }
  return [...byDate.values()].sort((a, b) => a.date.localeCompare(b.date)).map((day) => ({ ...day, balanceScore: day.recoveryScore - Math.round(day.strainScore * 0.35) }));
}

function emptyMergedDay(date) {
  return { date, workoutTypes: [], workoutCount: 0, minutes: 0, calories: 0, distance: 0, avgHeartRate: 0, readinessScore: 0, sleepScore: 0, activityScore: 0, hrv: 0, restingHeartRate: 0, steps: 0, strainScore: 0, recoveryScore: 0, balanceScore: 0 };
}

function calculateMetrics(merged, workouts, ouraDaily) {
  const last7 = merged.slice(-7);
  const totalMinutes = workouts.reduce((sum, item) => sum + item.durationMinutes, 0);
  const totalCalories = workouts.reduce((sum, item) => sum + item.activeCalories, 0);
  const totalDistance = workouts.reduce((sum, item) => sum + item.distanceMiles, 0);
  const avgReadiness = average(ouraDaily.map((item) => item.readinessScore));
  const avgSleep = average(ouraDaily.map((item) => item.sleepScore));
  const weeklyMinutes = last7.reduce((sum, item) => sum + item.minutes, 0);
  const weeklyStrain = last7.reduce((sum, item) => sum + item.strainScore, 0);
  const weeklyRecovery = last7.reduce((sum, item) => sum + item.recoveryScore, 0);
  const streak = calculateStreak(workouts.map((item) => item.date));
  const heroBalance = Math.max(0, Math.min(100, Math.round((weeklyRecovery / 7) - (weeklyStrain / 28) + 45)));
  return { totalWorkouts: workouts.length, totalMinutes, totalCalories, totalDistance, avgReadiness, avgSleep, weeklyMinutes, weeklyStrain, weeklyRecovery, streak, heroBalance, latestBalance: merged.at(-1)?.balanceScore ?? 0 };
}

function calculateStreak(dates) {
  const unique = [...new Set(dates)].sort().reverse();
  if (!unique.length) {
    return 0;
  }
  let streak = 0;
  let cursor = new Date(unique[0]);
  cursor.setHours(0, 0, 0, 0);
  for (const date of unique) {
    const isoCursor = cursor.toISOString().slice(0, 10);
    if (date === isoCursor) {
      streak += 1;
      cursor = new Date(cursor.getTime() - 86400000);
    } else {
      break;
    }
  }
  return streak;
}

function renderStats(metrics) {
  const cards = [
    ["Workouts logged", metrics.totalWorkouts, "Apple workouts plus synced Oura workouts and sessions."],
    ["Minutes trained", Math.round(metrics.totalMinutes), "All imported and synced workout duration."],
    ["Calories burned", Math.round(metrics.totalCalories), "Active calories from Apple and Oura workouts."],
    ["Miles covered", metrics.totalDistance.toFixed(1), "Distance across run, walk, ride, and recorded sessions."],
    ["Avg readiness", metrics.avgReadiness || "-", "Mean Oura readiness score."],
    ["Avg sleep", metrics.avgSleep || "-", "Mean Oura sleep score."],
    ["Weekly minutes", Math.round(metrics.weeklyMinutes), "Latest 7-day training volume."],
    ["Workout streak", metrics.streak, "Consecutive active days across Apple and Oura data."],
  ];
  statsGrid.innerHTML = cards.map(([title, value, subtitle]) => `<article class="stat-card"><div class="stat-title">${title}</div><div class="stat-value">${value}</div><div class="stat-subtitle">${subtitle}</div></article>`).join("");
}

function renderChart(merged) {
  if (!merged.length) {
    chart.innerHTML = `<div class="empty-state">Load data to compare workout strain and recovery.</div>`;
    return;
  }
  const recent = merged.slice(-14);
  const maxStrain = Math.max(...recent.map((item) => item.strainScore), 1);
  const maxRecovery = Math.max(...recent.map((item) => item.recoveryScore), 1);
  chart.innerHTML = recent.map((item) => `<div class="chart-col" title="${item.date}"><div class="bar recovery" style="height:${(item.recoveryScore / maxRecovery) * 140}px"></div><div class="bar strain" style="height:${(item.strainScore / maxStrain) * 140}px"></div><div class="chart-date">${item.date.slice(5)}</div></div>`).join("");
}

function renderMilestones(metrics) {
  const milestoneData = [
    { label: "Weekly cardio goal", current: metrics.weeklyMinutes, target: 150, suffix: "min" },
    { label: "Recovery average", current: metrics.weeklyRecovery / 7, target: 80, suffix: "pts" },
    { label: "Training balance", current: metrics.heroBalance, target: 75, suffix: "score" }
  ];
  milestones.innerHTML = milestoneData.map((item) => {
    const progress = Math.min(100, Math.round((item.current / item.target) * 100));
    return `<article class="milestone"><div class="milestone-head"><strong>${item.label}</strong><span>${Math.round(item.current)} / ${item.target} ${item.suffix}</span></div><div class="milestone-meter"><div class="milestone-fill" style="width:${progress}%"></div></div></article>`;
  }).join("");
}

function renderTimeline(merged) {
  if (!merged.length) {
    timelineBody.innerHTML = `<tr><td colspan="9" class="empty-state">No daily timeline yet.</td></tr>`;
    return;
  }
  timelineBody.innerHTML = merged.slice(-21).reverse().map((item) => `<tr><td>${item.date}</td><td><span class="pill">${item.workoutTypes[0] ?? "Recovery day"}</span></td><td>${Math.round(item.minutes)}</td><td>${Math.round(item.calories)}</td><td>${item.distance.toFixed(1)} mi</td><td>${item.readinessScore || "-"}</td><td>${item.sleepScore || "-"}</td><td>${item.hrv || "-"}</td><td>${item.balanceScore}</td></tr>`).join("");
}

function renderHero(metrics) {
  heroScore.textContent = metrics.heroBalance;
  if (!metrics.totalWorkouts && !metrics.avgReadiness) {
    heroSummary.textContent = "Import Apple workouts and Oura daily metrics to generate a training balance score.";
    return;
  }
  const sourceCopy = state.ouraConnected ? "using live Oura daily, workout, and session sync" : "using imported workout and Oura data";
  heroSummary.textContent = `You logged ${metrics.weeklyMinutes} minutes this week with average readiness ${metrics.avgReadiness || 0}, ${sourceCopy}. Latest balance score: ${metrics.latestBalance}.`;
}

function average(values) {
  const filtered = values.filter(Boolean);
  if (!filtered.length) {
    return 0;
  }
  return Math.round(filtered.reduce((sum, value) => sum + value, 0) / filtered.length);
}

await bootstrapAuth();
const params = new URLSearchParams(window.location.search);
if (params.get("oura") === "connected") {
  window.history.replaceState({}, document.title, window.location.pathname);
  if (state.authenticated) {
    ouraConnectionStatus.textContent = "Oura authorization completed. If workout/session scopes were just added, disconnect and reconnect once, then sync again.";
    await syncOuraData();
  }
}
