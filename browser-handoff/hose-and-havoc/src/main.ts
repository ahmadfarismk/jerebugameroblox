import Phaser from "phaser";
import { Board } from "./board";
import { cards, upgrades, apiBand, type Card, type Upgrade } from "./data";
import {
  newRun,
  resolve,
  forecast,
  parseSave,
  type State,
  type Command,
  neighbors,
} from "./engine";
import { tone } from "./audio";
import "./style.css";
import {
  stageName,
  stageGuide,
  progress,
  objectives,
  bossPanel,
  interlude,
} from "./campaign-ui";
const SAVE = "bahaya-jerebu-v1",
  SETTINGS = "bahaya-settings";
const app = document.querySelector<HTMLDivElement>("#app")!;
let state: State | undefined,
  selected: Card | undefined,
  route: number[] = [],
  target: number | undefined,
  busy = false,
  previewRevision = 0,
  saveError = "",
  corrupt = false;
let settings = {
  muted: true,
  reduced: matchMedia("(prefers-reduced-motion: reduce)").matches,
};
try {
  settings = {
    ...settings,
    ...JSON.parse(localStorage.getItem(SETTINGS) || "{}"),
  };
} catch {}
let scene = new Board();
let game: Phaser.Game | undefined;
const art = (key: string, cls = "") =>
  `<img class="${cls}" src="/assets/${key}.webp" alt="">`;
app.innerHTML = `<header><a class="brand" href="#" aria-label="Bahaya Jerebu home">DB<span>LOX</span> <b>FIELD OPERATIONS</b></a><div class="settings"><button id="sound" aria-label="Toggle sound"></button><button id="motion" aria-label="Toggle reduced motion"></button></div></header><main id="content"></main><footer>Made for the kampung. <span>Solo • Device-local save • No account needed</span></footer>`;
const content = document.querySelector<HTMLElement>("#content")!;
window.addEventListener("game-asset-error", () => {
  if (document.querySelector("#asset-error")) return;
  const p = document.createElement("p");
  p.id = "asset-error";
  p.className = "asset-error";
  p.innerHTML =
    'Board art unavailable. Text markers are active. <button onclick="location.reload()">Retry art</button>';
  app.append(p);
});
function updateSettings() {
  document.querySelector("#sound")!.textContent = settings.muted
    ? "Sound off"
    : "Sound on";
  document.querySelector("#motion")!.textContent = settings.reduced
    ? "Motion reduced"
    : "Motion on";
  document.documentElement.classList.toggle("reduced", settings.reduced);
  scene.reduced = settings.reduced;
  try {
    localStorage.setItem(SETTINGS, JSON.stringify(settings));
  } catch {}
}
document.querySelector("#sound")!.addEventListener("click", () => {
  settings.muted = !settings.muted;
  updateSettings();
  tone(settings.muted);
});
document.querySelector("#motion")!.addEventListener("click", () => {
  settings.reduced = !settings.reduced;
  updateSettings();
});
document.querySelector(".brand")!.addEventListener("click", (e) => {
  e.preventDefault();
  title();
});
document.addEventListener(
  "error",
  (e) => {
    const el = e.target;
    if (el instanceof HTMLImageElement) {
      el.style.visibility = "hidden";
      document.querySelector("#asset-error")?.remove();
      const p = document.createElement("p");
      p.id = "asset-error";
      p.className = "asset-error";
      p.innerHTML =
        'Some illustrations could not load. Tile labels remain available. <button onclick="location.reload()">Retry art</button>';
      app.append(p);
    }
  },
  true,
);
function save() {
  if (!state) return;
  try {
    localStorage.setItem(SAVE, JSON.stringify(state));
    saveError = "";
  } catch {
    saveError = "Saving unavailable in this browser. Keep this tab open.";
  }
}
function teardown() {
  game?.destroy(true);
  game = undefined;
  scene.ready = false;
}
function title() {
  teardown();
  document.body.classList.remove("night");
  let saved = false;
  let savedLabel = "";
  try {
    const raw = localStorage.getItem(SAVE);
    if (raw) {
      const loaded = parseSave(raw);
      savedLabel =
        loaded.mode === "campaign"
          ? `Hari ${loaded.day} · ${loaded.encounter === "night" ? "Malam" : loaded.phase}`
          : "Quick slice";
      saved = true;
    }
    corrupt = false;
  } catch {
    corrupt = true;
  }
  content.innerHTML = `<section class="title-screen"><div class="hero-copy"><p class="eyebrow">A LITTLE WATER. A LOT OF TROUBLE.</p><h1>BAHAYA<br><span>JEREBU!</span></h1><p class="subtitle">Hose & Havoc</p><p class="intro">The haze has a crown. You have a hose.<br>Route water, outsmart the smoke, save your kampung.</p><div class="hero-actions"><button class="primary" id="new">Start seven-day campaign ↗</button>${saved ? `<button id="resume">Continue saved run · ${savedLabel}</button>` : ""}<button id="quick">Quick tutorial + Raja</button></div><label class="seed-label">Run seed (optional)<input id="seed" type="number" min="0" max="4294967295" placeholder="Random" aria-label="Run seed"></label>${corrupt ? '<p class="warning">This save is damaged or incompatible. Start a new run to replace it.</p>' : ""}<p class="small">Seven days · six Malam defenses · three original bosses<br>Turn-based. Take your time. Every attack is announced.</p></div><div class="hero-art">${art("boss.rajaJerebu", "tyrant")}<span class="speech">“WHO TURNED ON THE TAP?!”</span><span class="hero-badge">MEET RAJA JEREBU<br><b>100% haze. 0% chill.</b></span></div><div class="how"><div><b>01 / PICK</b><p>Choose a card for the job.</p></div><div><b>02 / ROUTE</b><p>Tap adjacent tiles from a hydrant.</p></div><div><b>03 / PADAM!</b><p>Preview the cost. Let it flow.</p></div></div></section>`;
  document.querySelector("#new")!.addEventListener("click", () => {
    const seed = (document.querySelector("#seed") as HTMLInputElement)?.value;
    state = newRun(
      seed ? Number(seed) : crypto.getRandomValues(new Uint32Array(1))[0],
      "campaign",
    );
    save();
    mountGame();
  });
  document.querySelector("#quick")!.addEventListener("click", () => {
    state = newRun(crypto.getRandomValues(new Uint32Array(1))[0], "slice");
    save();
    mountGame();
  });
  document.querySelector("#resume")?.addEventListener("click", () => {
    try {
      state = parseSave(localStorage.getItem(SAVE)!);
      mountGame();
    } catch {
      title();
    }
  });
}
function mountGame() {
  teardown();
  selected = undefined;
  route = [];
  target = undefined;
  if (!state) return;
  if (["camp", "dayComplete", "victory", "defeat"].includes(state.phase)) {
    renderInterlude();
    return;
  }
  content.innerHTML = `${progress(state)}<div class="run-heading"><div><p class="eyebrow" id="chapter"></p><h1 id="encounter-title"></h1></div><button id="home">Save & menu</button></div><div id="hud" class="hud"></div><div class="play-layout"><section class="board-column"><div id="boss"></div><div id="intent" class="intent"></div><div class="board-frame"><div id="board-canvas" aria-hidden="true"></div><div id="board-input" role="group" aria-label="6 by 6 hose routing board"></div></div><div class="legend"><span>~ Wet: free routing</span><span>○ Foam: protection</span><span>! Next attack</span></div></section><aside class="crew-panel"><div class="panel-heading"><p class="eyebrow">YOUR CREW, YOUR CALL</p><b id="turn"></b></div><p id="objective" class="objective"></p><p id="guide" class="guide"></p><div class="hand-heading"><h2>Choose your card</h2><span id="deck"></span></div><div id="hand" class="hand"></div><div id="detail" class="detail"></div><div id="preview" class="preview" aria-live="polite"></div><div class="confirm-row"><button id="confirm" class="primary">Padam · Confirm</button><button id="cancel">Cancel</button></div><div class="utilities"><button id="refill">Refill</button><button id="emergency">Emergency Spray</button></div><button id="end" class="end">End Turn →</button><p id="message" class="message" role="status"></p></aside></div>`;
  const grid = document.querySelector("#board-input")!;
  for (let i = 0; i < 36; i++) {
    const b = document.createElement("button");
    b.dataset.tile = String(i);
    b.addEventListener("pointerdown", (e) => {
      if (e.button === 2) return;
      e.preventDefault();
      b.focus();
      tile(i);
    });
    b.addEventListener("pointerenter", (e) => {
      if (e.buttons === 1 && route.at(-1) !== i) tile(i);
    });
    b.addEventListener("click", (e) => {
      if (e.detail === 0) tile(i);
    });
    b.addEventListener("keydown", (e) => {
      const n =
        e.key === "ArrowLeft"
          ? i - 1
          : e.key === "ArrowRight"
            ? i + 1
            : e.key === "ArrowUp"
              ? i - 6
              : e.key === "ArrowDown"
                ? i + 6
                : -1;
      if (n >= 0 && n < 36) {
        e.preventDefault();
        (grid.children[n] as HTMLElement).focus();
      }
    });
    grid.append(b);
  }
  grid.addEventListener(
    "touchmove",
    (e) => {
      const t = (e as TouchEvent).touches[0];
      const el = document.elementFromPoint(t.clientX, t.clientY) as HTMLElement;
      const i = Number(el?.dataset.tile);
      if (el?.dataset.tile !== undefined && i !== route.at(-1)) tile(i);
    },
    { passive: true },
  );
  grid.addEventListener("contextmenu", (e) => {
    e.preventDefault();
    cancel();
  });
  scene = new Board();
  scene.reduced = settings.reduced;
  game = new Phaser.Game({
    type: Phaser.AUTO,
    width: 480,
    height: 480,
    parent: "board-canvas",
    transparent: true,
    scene,
    render: { antialias: true },
    audio: { noAudio: true },
    banner: false,
  });
  document.querySelector("#home")!.addEventListener("click", () => {
    save();
    title();
  });
  document.querySelector("#cancel")!.addEventListener("click", cancel);
  document
    .querySelector("#refill")!
    .addEventListener("click", () => commit({ type: "refill" }));
  document
    .querySelector("#emergency")!
    .addEventListener("click", () => select("emergency"));
  document.querySelector("#confirm")!.addEventListener("click", () => {
    const c = command();
    if (c) commit(c);
  });
  document
    .querySelector("#end")!
    .addEventListener("click", () => commit({ type: "end" }));
  render();
}
function select(c: Card) {
  if (busy) return;
  selected = c;
  route = [];
  target = undefined;
  previewRevision = state!.revision;
  render();
}
function cancel() {
  selected = undefined;
  route = [];
  target = undefined;
  render();
}
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && document.querySelector("#board-input")) cancel();
});
function tile(i: number) {
  if (!state || busy) return;
  if (!selected) {
    state.message = "Choose a card first. Then tap the hydrant to begin.";
    render();
    return;
  }
  if (selected === "rescue") {
    target = i;
    render();
    return;
  }
  if (selected === "wind") return;
  if (route.at(-1) === i) return;
  if (!route.length || state.board[i].terrain === "hydrant") route = [i];
  else if (route.length > 1 && route.at(-2) === i) route.pop();
  else if (neighbors(route.at(-1)!).includes(i)) route.push(i);
  else {
    state.message = "That tile is not adjacent. Tap the next tile or Cancel.";
  }
  render();
}
function command(): Command | undefined {
  return selected
    ? { type: "play", card: selected, route: [...route], target }
    : undefined;
}
function render() {
  if (!state || !document.querySelector("#hud")) return;
  const s = state,
    band = apiBand(s.api);
  document.querySelector("#chapter")!.textContent =
    s.mode === "campaign"
      ? `${s.encounter === "night" ? "MALAM" : "HARI"} ${s.day} / SEVEN-DAY CAMPAIGN`
      : "QUICK SLICE / TRAINING + RAJA";
  document.querySelector("#encounter-title")!.textContent = stageName(s);
  document.querySelector("#objective")!.textContent = objectives(s);
  document.body.classList.toggle("night", s.encounter === "night");
  document.querySelector("#hud")!.innerHTML =
    `<div>${art("hud.water")}<span><b>${s.water}<small> / ${s.capacity}</small></b><label>WATER</label></span></div><div><strong class="action-icon">ϟ</strong><span><b>${s.actions}<small> / 3</small></b><label>ACTIONS</label></span></div><div>${art("hud.integrity")}<span><b>${s.integrity}<small> / 5</small></b><label>CAMP INTEGRITY</label></span></div><div class="api" style="--band:${band[1]}">${art(band[2])}<span><b>${s.api} <small>${band[0]}</small></b><label>API · GAME METER</label></span></div>`;
  document.querySelector("#boss")!.innerHTML = bossPanel(s);
  const f = forecast(s),
    c = command(),
    p = c ? resolve(s, c, previewRevision) : undefined;
  const rotated =
    selected === "wind" && p?.ok ? p.state.intent.tiles : undefined;
  document.querySelector("#intent")!.innerHTML =
    `<span class="intent-icon">${s.intent.kind === "dry" ? "≋" : "!"}</span><div><b>${s.intent.kind === "ember" ? "Ember lane" : s.intent.kind === "dry" ? "Dry gust" : "Peat pop"} · ${s.encounter === "night" ? "TURN + CAMP RECOVERY" : "AFTER END TURN"}</b><small>${s.intent.kind === "dry" ? "Marked tiles lose wetness. No immediate damage." : "Marked dry tiles ignite; wet / foam block impacts."} Camp ${f.integrity}, API ${f.api >= 0 ? "+" : ""}${f.api}.${f.hazard ? " ⚠ Evacuation warning!" : ""}${f.bossDamage ? ` Boss counter damage: ${f.bossDamage}.` : ""}</small></div>`;
  document.querySelector("#turn")!.textContent = `TURN ${s.turn}`;
  document.querySelector("#deck")!.textContent =
    `Draw ${s.draw.length} · Discard ${s.discard.length}`;
  document.querySelector("#guide")!.textContent = stageGuide(s);
  const hand = document.querySelector("#hand")!;
  hand.innerHTML = "";
  s.hand.forEach((c) => {
    const b = document.createElement("button");
    b.className = "card" + (selected === c ? " selected" : "");
    b.innerHTML = `${art(cards[c].art)}<strong>${cards[c].name}</strong><small>${cards[c].actions} action${cards[c].actions > 1 ? "s" : ""} · ${cards[c].base} + route 💧</small>`;
    b.setAttribute("aria-pressed", String(selected === c));
    b.addEventListener("click", () => select(c));
    hand.append(b);
  });
  document.querySelector("#detail")!.innerHTML = selected
    ? `<b>${cards[selected].name}</b><span>${cards[selected].text}</span>`
    : "<b>Make every drop count.</b><span>Choose a card to see its effect. Tap or drag a hose; arrows + Enter also work.</span>";
  document.querySelector("#preview")!.textContent = p
    ? p.ok
      ? `${p.cost} water · ${cards[selected!].actions} action(s) · ${p.message}`
      : p.message
    : "Route preview appears here. Nothing is spent until you confirm.";
  (document.querySelector("#confirm") as HTMLButtonElement).disabled =
    busy || !p?.ok;
  (document.querySelector("#refill") as HTMLButtonElement).disabled =
    busy || s.actions < 1;
  document.querySelector("#refill")!.textContent =
    `Refill +${s.upgrades.includes("tower") ? 7 : 5} 💧 · 1 action`;
  document.querySelector("#message")!.textContent = saveError || s.message;
  document.querySelector("#end")!.innerHTML =
    `End Turn →<span class="end-forecast"> Camp ${f.integrity}, API ${f.api >= 0 ? "+" : ""}${f.api}</span>`;
  document
    .querySelectorAll<HTMLButtonElement>("[data-tile]")
    .forEach((b, i) => {
      const t = s.board[i];
      b.setAttribute(
        "aria-label",
        `Row ${Math.floor(i / 6)}, column ${i % 6}: ${t.terrain}${t.fire ? `, fire ${t.fire} HP` : ""}${t.wet ? ", wet" : ""}${t.foam ? ", foam" : ""}${t.terrain === "peat" ? (t.cleared ? ", cleared" : t.soaked === s.turn ? ", first Soak this turn" : t.soaked === s.turn - 1 ? ", second Soak due now" : ", needs two consecutive Soaks") : ""}${t.terrain === "house" ? (t.rescued ? ", residents safe" : ", residents waiting") : ""}${s.intent.tiles.includes(i) ? ", incoming attack" : ""}`,
      );
      b.title = b.getAttribute("aria-label")!;
    });
  scene.updateBoard(s, route, rotated);
}
function commit(c: Command) {
  if (!state || busy) return;
  const result = resolve(
    state,
    c,
    c.type === "play" ? previewRevision : state.revision,
  );
  if (!result.ok) {
    state.message = result.message;
    render();
    return;
  }
  busy = true;
  const path = [...route];
  state = result.state;
  save();
  tone(settings.muted);
  selected = undefined;
  route = [];
  target = undefined;
  previewRevision = state.revision;
  if (["camp", "dayComplete", "victory", "defeat"].includes(state.phase)) {
    busy = false;
    teardown();
    renderInterlude();
    return;
  }
  render();
  scene.splash(path);
  document.querySelector("#boss")?.classList.add("hit");
  setTimeout(
    () => {
      busy = false;
      render();
    },
    settings.reduced ? 0 : 250,
  );
}
function renderInterlude() {
  if (!state) return;
  teardown();
  document.body.classList.remove("night");
  content.innerHTML = interlude(state);
  document
    .querySelectorAll<HTMLButtonElement>("[data-upgrade]")
    .forEach((b) =>
      b.addEventListener("click", () =>
        commit({ type: "buy", upgrade: b.dataset.upgrade as Upgrade }),
      ),
    );
  document.querySelector("#continue")?.addEventListener("click", () => {
    if (busy || !state) return;
    const r = resolve(state, { type: "continue" });
    if (!r.ok) return;
    state = r.state;
    save();
    mountGame();
  });
  document.querySelector("#interlude-home")?.addEventListener("click", () => {
    save();
    title();
  });
  document.querySelector("#again")?.addEventListener("click", () => {
    state = newRun(
      crypto.getRandomValues(new Uint32Array(1))[0],
      state?.mode ?? "campaign",
    );
    save();
    mountGame();
  });
}
updateSettings();
title();
