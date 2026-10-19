import { cards, deck, upgrades, type Card, type Upgrade } from "./data";
import { campaignBoard, campaignIntent, days } from "./campaign";
export type Phase =
  | "loading"
  | "title"
  | "tutorial"
  | "playerTurn"
  | "enemyResolve"
  | "camp"
  | "dayComplete"
  | "victory"
  | "defeat";
export type Tile = {
  terrain:
    | "ground"
    | "tree"
    | "rock"
    | "hydrant"
    | "house"
    | "peat"
    | "vent"
    | "core";
  fire: number;
  wet: number;
  foam: number;
  rescued?: boolean;
  soaked?: number;
  cleared?: boolean;
};
export type Intent = {
  kind: "ember" | "dry" | "pop";
  tiles: number[];
  rotated: boolean;
};
export type Command =
  | { type: "play"; card: Card; route: number[]; target?: number }
  | { type: "refill" }
  | { type: "end" }
  | { type: "buy"; upgrade: Upgrade }
  | { type: "continue" };
export type State = {
  version: 2;
  mode: "slice" | "campaign";
  day: number;
  totalTurns: number;
  history: {
    day: number;
    period: "day" | "night";
    turns: number;
    integrity: number;
    api: number;
    summary: string;
  }[];
  stageStartIntegrity: number;
  revision: number;
  seed: number;
  rng: number;
  phase: Phase;
  encounter: "tutorial" | "boss" | "day" | "bara" | "gambut" | "night";
  turn: number;
  board: Tile[];
  water: number;
  capacity: number;
  actions: number;
  integrity: number;
  api: number;
  hazard: number;
  coins: number;
  fund: number;
  hand: Card[];
  draw: Card[];
  discard: Card[];
  intent: Intent;
  bossHP: number;
  openUntil: number;
  upgrades: Upgrade[];
  shelter: boolean;
  campVisit: number;
  purchaseMade: boolean;
  log: { crewId: string; revision: number; command: Command }[];
  message: string;
};
export type Result = {
  ok: boolean;
  state: State;
  message: string;
  cost: number;
};
export const neighbors = (i: number) =>
  [
    i - 6,
    i + 6,
    ...(i % 6 ? [i - 1] : []),
    ...(i % 6 < 5 ? [i + 1] : []),
  ].filter((n) => n >= 0 && n < 36);
function random(s: State) {
  s.rng = (Math.imul(s.rng, 1664525) + 1013904223) >>> 0;
  return s.rng / 4294967296;
}
function shuffle(s: State, a: Card[]) {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(random(s) * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
function draw(s: State) {
  while (s.hand.length < 5) {
    if (!s.draw.length) {
      s.draw = shuffle(s, s.discard);
      s.discard = [];
    }
    const c = s.draw.shift();
    if (!c) break;
    s.hand.push(c);
  }
}
// Introductory assistance swaps an existing card, never creates a duplicate.
function assure(s: State, c: Card, preserve: Card[] = []) {
  if (s.hand.includes(c)) return;
  for (const pile of [s.draw, s.discard]) {
    const i = pile.indexOf(c);
    if (i >= 0) {
      let swap = s.hand.length - 1;
      if (preserve.includes(s.hand[swap]))
        swap = s.hand.findIndex((card) => !preserve.includes(card));
      const old = swap >= 0 ? s.hand.splice(swap, 1)[0] : undefined;
      pile.splice(i, 1);
      if (old) pile.push(old);
      s.hand.push(c);
      return;
    }
  }
}
function board(boss: boolean): Tile[] {
  const b: Tile[] = Array.from({ length: 36 }, () => ({
    terrain: "ground",
    fire: 0,
    wet: 0,
    foam: 0,
  }));
  b[32].terrain = "hydrant";
  for (const i of [0, 5, 24]) b[i].terrain = "tree";
  b[23].terrain = "rock";
  b[17].terrain = "house";
  if (boss) {
    b[2].terrain = "core";
    for (const i of [7, 10]) {
      b[i].terrain = "vent";
      b[i].fire = 2;
    }
  } else for (const i of [20, 25, 28]) b[i].fire = 2;
  return b;
}
function intent(s: State): Intent {
  if (s.mode === "campaign") {
    const authored = campaignIntent(s.day, s.turn, s.encounter === "night");
    if (authored) return authored;
  }
  if (s.encounter === "tutorial")
    return { kind: "ember", tiles: [12, 13, 14, 15, 16, 17], rotated: false };
  const cycle = (s.turn - 1) % 3;
  let tiles: number[];
  if (cycle === 0) {
    const row = [2, 4, 3][Math.floor((s.turn - 1) / 3) % 3];
    tiles = Array.from({ length: 6 }, (_, c) => row * 6 + c);
  } else if (cycle === 1) {
    const col = [0, 5, 3][Math.floor((s.turn - 1) / 3) % 3];
    tiles = Array.from({ length: 6 }, (_, r) => r * 6 + col);
  } else {
    const eligible = s.board
      .map((t, i) => (t.terrain === "ground" && !t.fire ? i : -1))
      .filter((i) => i >= 0);
    tiles = [];
    while (tiles.length < 2 && eligible.length)
      tiles.push(
        eligible.splice(Math.floor(random(s) * eligible.length), 1)[0],
      );
  }
  if (s.bossHP < 6) {
    const extra = s.board.findIndex(
      (t, i) => t.terrain === "ground" && !tiles.includes(i),
    );
    if (extra >= 0) tiles.push(extra);
  }
  return {
    kind: cycle === 0 ? "ember" : cycle === 1 ? "dry" : "pop",
    tiles,
    rotated: false,
  };
}
export function newRun(
  seed: number,
  mode: "slice" | "campaign" = "slice",
): State {
  const s: State = {
    version: 2,
    mode,
    day: 1,
    totalTurns: 0,
    history: [],
    stageStartIntegrity: 5,
    revision: 0,
    seed: seed >>> 0,
    rng: seed >>> 0,
    phase: "tutorial",
    encounter: "tutorial",
    turn: 1,
    board: board(false),
    water: 10,
    capacity: 10,
    actions: 3,
    integrity: 5,
    api: 30,
    hazard: 0,
    coins: 0,
    fund: 0,
    hand: [],
    draw: [...deck],
    discard: [],
    intent: { kind: "ember", tiles: [], rotated: false },
    bossHP: mode === "campaign" ? 0 : 12,
    openUntil: 0,
    upgrades: [],
    shelter: false,
    campVisit: 0,
    purchaseMade: false,
    log: [],
    message:
      "Tutorial hand: three Sprays. Tap a card, then the hydrant and adjacent tiles.",
  };
  draw(s);
  s.intent = intent(s);
  return s;
}
export function needsRescue(s: State) {
  return (
    s.mode === "campaign" && s.encounter !== "night" && [4, 6].includes(s.day)
  );
}
export function isBoss(s: State) {
  return ["boss", "bara", "gambut"].includes(s.encounter);
}
function recordStage(s: State, period: "day" | "night", summary: string) {
  s.history.push({
    day: s.day,
    period,
    turns: s.turn,
    integrity: s.integrity,
    api: s.api,
    summary,
  });
}
function enterCamp(s: State) {
  s.phase = "camp";
  s.campVisit++;
  s.purchaseMade = false;
  const bonus = s.integrity >= s.stageStartIntegrity ? 2 : 1;
  s.fund += bonus;
  const summary = `Malam ${s.day} survived: ${Math.max(0, s.stageStartIntegrity - s.integrity)} integrity lost; +${bonus} Camp Fund. API ${s.api}.`;
  recordStage(s, "night", summary);
  const recovery = Math.min(30, s.api);
  s.api -= recovery;
  if (s.api < 301) s.hazard = 0;
  const heal = s.upgrades.includes("kitchen")
    ? Math.min(1, 5 - s.integrity)
    : 0;
  s.integrity += heal;
  s.message =
    summary +
    ` Camp ventilation cleared ${recovery} API.` +
    (heal ? ` Field Kitchen restored ${heal} integrity.` : "") +
    " Choose one upgrade or continue.";
}
function startStage(s: State, night: boolean) {
  s.encounter = night ? "night" : days[s.day - 1].kind;
  s.phase = s.day === 1 && !night ? "tutorial" : "playerTurn";
  s.board = campaignBoard(s.day, night);
  s.turn = 1;
  s.actions = 3;
  s.water = s.capacity;
  s.openUntil = 0;
  s.bossHP = night ? 0 : days[s.day - 1].hp;
  s.stageStartIntegrity = s.integrity;
  // Keep the same eleven cards and PRNG across all thirteen boards.
  s.discard.push(...s.hand);
  s.hand = [];
  draw(s);
  s.intent = intent(s);
}
export function safeHouse(s: State, target: number) {
  if (s.board[target]?.terrain !== "house" || s.board[target].rescued)
    return false;
  const seen = new Set([target]);
  const q = [target];
  while (q.length) {
    const i = q.shift()!;
    if (s.board[i].terrain === "hydrant") return true;
    for (const n of neighbors(i))
      if (
        !seen.has(n) &&
        !s.board[n].fire &&
        s.board[n].terrain !== "rock" &&
        (s.board[n].terrain !== "house" || n === target)
      ) {
        seen.add(n);
        q.push(n);
      }
  }
  return false;
}
function reward(s: State) {
  s.coins += 4;
  s.fund++;
  s.api = Math.max(0, s.api - 6);
}
function finish(s: State) {
  if (s.mode === "campaign") {
    if (s.encounter === "night") return;
    const won = isBoss(s)
      ? s.bossHP <= 0
      : s.board.every((t) => !t.fire && (t.terrain !== "peat" || t.cleared)) &&
        (!needsRescue(s) ||
          s.board.filter((t) => t.terrain === "house").every((t) => t.rescued));
    if (!won) return;
    recordStage(
      s,
      "day",
      `${days[s.day - 1].name.replace(/\.$/, "")} cleared.`,
    );
    if (s.day === 7) {
      s.phase = "victory";
      s.message =
        "Seven days. Six nights. One very soggy haze king. Kampung saved!";
    } else {
      s.phase = "dayComplete";
      const stipend = s.day === 1 ? 3 : 0;
      s.fund += stipend;
      s.message = `Hari ${s.day} complete! ${stipend ? "+3 Camp Fund training stipend. " : ""}Next: one Malam defense round. The crew will refill water; your deck carries over.`;
    }
    return;
  }
  if (s.encounter === "boss" && s.bossHP <= 0) {
    s.phase = "victory";
    s.message = "My majestic haze! Raja Jerebu has deflated. Kampung saved!";
  } else if (
    s.encounter === "tutorial" &&
    s.board.every((t) => !t.fire && (t.terrain !== "peat" || t.cleared))
  ) {
    s.phase = "camp";
    s.campVisit++;
    s.fund += 3;
    s.message =
      "Three fires out! +3 Camp Fund tutorial completion stipend. Choose one upgrade.";
    if (s.upgrades.includes("kitchen"))
      s.integrity = Math.min(5, s.integrity + 1);
  }
}
export function resolve(
  input: State,
  command: Command,
  expectedRevision = input.revision,
): Result {
  const fail = (message: string): Result => ({
    ok: false,
    state: input,
    message,
    cost: 0,
  });
  if (expectedRevision !== input.revision)
    return fail("That preview is old. Select a new action.");
  const s: State = structuredClone(input);
  let cost = 0;
  let message = "";
  if (command.type === "buy") {
    if (s.phase !== "camp" || s.purchaseMade)
      return fail("Only one upgrade per camp visit.");
    const u = upgrades[command.upgrade];
    if (!u || s.upgrades.includes(command.upgrade) || s.fund < u.cost)
      return fail("Upgrade unavailable or insufficient Camp Fund.");
    s.fund -= u.cost;
    s.upgrades.push(command.upgrade);
    s.purchaseMade = true;
    if (command.upgrade === "tower") {
      s.capacity += 4;
      s.water = Math.min(s.capacity, s.water + 4);
    }
    if (command.upgrade === "kitchen")
      s.integrity = Math.min(5, s.integrity + 2);
    if (command.upgrade === "shelter") s.shelter = true;
    message = `${u.name} installed. Purchase saved.`;
  } else if (command.type === "continue") {
    if (s.mode === "campaign") {
      if (s.phase === "dayComplete") {
        startStage(s, true);
        message = `Malam ${s.day}: survive one announced attack. Protect the hydrant with Foam Line, or rotate the lane with Wind Turn. Extinguishing the fire reduces API. End Turn completes the night.`;
      } else if (s.phase === "camp") {
        if (s.day >= 7) return fail("The campaign is complete.");
        s.day++;
        startStage(s, false);
        message = `Hari ${s.day}: ${days[s.day - 1].guide}`;
      } else return fail("Finish this encounter first.");
    } else {
      if (s.phase !== "camp") return fail("Visit camp first.");
      s.encounter = "boss";
      s.phase = "playerTurn";
      s.board = board(true);
      s.turn = 1;
      s.actions = 3;
      s.water = s.capacity;
      s.hand = [];
      s.discard = [];
      s.draw = shuffle(s, [...deck]);
      draw(s);
      assure(s, "spray");
      assure(s, "burst", ["spray"]);
      s.intent = intent(s);
      message = "Raja Jerebu! Douse both vents, then Burst Jet the core.";
    }
  } else {
    if (s.phase !== "tutorial" && s.phase !== "playerTurn")
      return fail("The crew is not planning a turn.");
    if (command.type === "refill") {
      if (s.actions < 1) return fail("No actions left. End Turn to replenish.");
      s.actions--;
      const gain = Math.min(
        s.capacity - s.water,
        s.upgrades.includes("tower") ? 7 : 5,
      );
      s.water += gain;
      message = `Refilled ${gain} water.`;
    }
    if (command.type === "play") {
      const c = cards[command.card];
      if (!c) return fail("Unknown card.");
      if (command.card !== "emergency" && !s.hand.includes(command.card))
        return fail("Card is no longer in your hand.");
      if (s.actions < c.actions) return fail(`Need ${c.actions} actions.`);
      if (command.card === "wind") {
        if (s.intent.kind !== "ember" || s.intent.rotated)
          return fail("Only an unrotated ember lane can turn.");
        s.intent.tiles = s.intent.tiles.map(
          (i) => (i % 6) * 6 + 5 - Math.floor(i / 6),
        );
        s.intent.rotated = true;
        message = "Ember lane rotated clockwise. See the new marked tiles.";
      } else if (command.card === "rescue") {
        if (command.target === undefined || !safeHouse(s, command.target))
          return fail(
            "Select an unrescued house with a clear path to a hydrant.",
          );
        s.board[command.target].rescued = true;
        s.fund += 2;
        message = "Residents safe! +2 Camp Fund.";
      } else {
        const route = command.route;
        if (route.length < 2 || route.length > 9)
          return fail("Route needs 1–8 edges. Start at a hydrant.");
        if (s.board[route[0]]?.terrain !== "hydrant")
          return fail("Start the hose at a hydrant.");
        if (new Set(route).size !== route.length)
          return fail("A route cannot repeat tiles.");
        for (let k = 1; k < route.length; k++) {
          const t = s.board[route[k]];
          if (!t || !neighbors(route[k - 1]).includes(route[k]))
            return fail("Use adjacent tiles, without diagonals.");
          if (t.terrain === "rock" || t.terrain === "house")
            return fail("Hoses cannot cross rocks or houses.");
          if (
            k < route.length - 1 &&
            (t.fire || t.terrain === "vent" || t.terrain === "core")
          )
            return fail("Fires and boss nozzles must be the final target.");
        }
        const target = s.board[route.at(-1)!];
        cost =
          c.base + route.slice(1).filter((i) => s.board[i].wet === 0).length;
        if (s.water < cost)
          return fail(`Need ${cost} water; refill or use wet ground.`);
        if (command.card === "foam") {
          if (
            target.fire ||
            target.terrain === "vent" ||
            target.terrain === "core"
          )
            return fail("Foam must end on an empty tile.");
          for (const i of route) s.board[i].foam = 2;
          message = "Foam protects this route for two resolutions.";
        } else if (command.card === "soak") {
          if (target.terrain !== "peat" || target.cleared)
            return fail("Soak needs uncleared peat.");
          if (target.soaked === s.turn)
            return fail("Second Soak must be on the next turn.");
          if (target.soaked === s.turn - 1) {
            target.cleared = true;
            target.soaked = undefined;
            reward(s);
            message = "Peat extinguished permanently!";
          } else {
            target.soaked = s.turn;
            message = "Peat soaked. Soak again next turn.";
          }
          target.fire = 0;
        } else if (target.terrain === "core") {
          if (
            command.card !== "burst" ||
            !s.openUntil ||
            (s.encounter === "boss" &&
              s.board.some((t) => t.terrain === "vent" && t.fire))
          )
            return fail(
              s.encounter === "bara"
                ? "Bara is shielded. Block two ember impacts in one resolution to expose it."
                : s.encounter === "gambut"
                  ? "Gambut is armored. Permanently clear both peat patches first."
                  : "Core shielded. Douse both vents; use Burst Jet when open.",
            );
          s.bossHP = Math.max(0, s.bossHP - c.damage);
          message = `Core ${input.bossHP} → ${s.bossHP} HP. WHO TURNED ON THE TAP?!`;
        } else {
          if (!target.fire) return fail("Aim at a living fire or vent.");
          const old = target.fire;
          target.fire = Math.max(0, target.fire - c.damage);
          message = `Target ${old} → ${target.fire} HP.`;
          if (!target.fire) {
            if (target.terrain === "peat") {
              target.soaked = undefined;
              message =
                "Peat suppressed this turn. Use consecutive Soaks to clear it.";
            } else reward(s);
          }
        }
        for (const i of route.slice(1)) s.board[i].wet = 2;
        s.water -= cost;
        if (
          s.encounter === "gambut" &&
          !s.openUntil &&
          s.board.filter((t) => t.terrain === "peat").every((t) => t.cleared)
        ) {
          s.openUntil = 999;
          message += " Gambut armor cracked! Core stays open.";
        }
        if (
          s.encounter === "boss" &&
          !s.openUntil &&
          s.board.filter((t) => t.terrain === "vent").every((t) => !t.fire)
        ) {
          s.openUntil = s.turn + 1;
          message += " Core OPEN through turn " + s.openUntil + "!";
        }
      }
      s.actions -= c.actions;
      if (command.card !== "emergency") {
        s.hand.splice(s.hand.indexOf(command.card), 1);
        s.discard.push(command.card);
      }
      if (
        s.mode === "slice" &&
        s.encounter === "boss" &&
        s.openUntil &&
        !input.openUntil
      )
        assure(s, "burst");
      finish(s);
    }
    if (command.type === "end") {
      s.phase = "enemyResolve";
      s.totalTurns++;
      const blocked =
        s.intent.kind === "ember"
          ? s.intent.tiles.filter((i) => s.board[i].wet || s.board[i].foam)
              .length
          : 0;
      for (const i of s.intent.tiles) {
        const t = s.board[i];
        if (s.intent.kind === "dry") {
          t.wet = 0;
          continue;
        }
        if (t.foam) {
          t.foam = 0;
          continue;
        }
        if (t.wet) continue;
        if (t.terrain === "house" || t.terrain === "hydrant") s.integrity--;
        else if (["ground", "tree", "peat"].includes(t.terrain))
          t.fire = Math.max(t.fire, 2);
      }
      for (const t of s.board)
        if (
          t.terrain === "peat" &&
          !t.cleared &&
          !t.fire &&
          (t.soaked === undefined || t.soaked < s.turn)
        ) {
          t.fire = 2;
          t.soaked = undefined;
        }
      if (s.encounter === "bara" && blocked >= 2) {
        s.bossHP = Math.max(0, s.bossHP - 4);
        s.openUntil = s.turn + 1;
      }
      const fires = s.board.filter((t) => t.fire).length;
      s.api = Math.max(
        0,
        Math.min(500, s.api + fires * 8 - (fires === 0 ? 10 : 0)),
      );
      s.hazard = s.api >= 301 ? s.hazard + 1 : 0;
      if (s.integrity <= 0 && s.shelter) {
        s.integrity = 1;
        s.shelter = false;
      }
      for (const t of s.board) {
        t.wet = Math.max(0, t.wet - 1);
        t.foam = Math.max(0, t.foam - 1);
      }
      if (s.integrity <= 0 || s.hazard >= 2) {
        s.phase = "defeat";
        s.message =
          s.integrity <= 0
            ? "Camp integrity lost. The crew evacuates."
            : "Two hazardous resolutions. Evacuate the kampung.";
      } else {
        if (s.encounter === "night") {
          enterCamp(s);
        } else {
          // Counter damage can win before advancing the turn or generating another intent.
          finish(s);
          if (
            !(["dayComplete", "victory", "camp"] as Phase[]).includes(s.phase)
          ) {
            if (
              s.openUntil &&
              s.turn >= s.openUntil &&
              s.encounter !== "gambut"
            ) {
              s.openUntil = 0;
              for (const t of s.board) if (t.terrain === "vent") t.fire = 2;
            }
            s.turn++;
            s.actions = 3;
            s.discard.push(...s.hand);
            s.hand = [];
            draw(s);
            if (s.mode === "slice" && s.encounter === "boss" && s.openUntil)
              assure(s, "burst");
            s.intent = intent(s);
            s.phase = s.encounter === "tutorial" ? "tutorial" : "playerTurn";
            message = s.hazard
              ? "EVACUATION WARNING: one hazardous strike. Lower API before another resolution!"
              : "New turn. The next attack is marked. Nothing moves until End Turn.";
            if (s.encounter === "bara" && blocked >= 2)
              message = `Bara blocked ${blocked} times: 4 recoil damage! Nozzle open through turn ${s.openUntil}.`;
            finish(s);
          }
        }
      }
    }
  }
  s.revision++;
  s.log.push({
    crewId: "solo-crew",
    revision: s.revision,
    command: structuredClone(command),
  });
  if (
    !(["camp", "dayComplete", "victory", "defeat"] as Phase[]).includes(
      s.phase,
    ) ||
    command.type === "buy"
  )
    s.message = message;
  return { ok: true, state: s, message: s.message || message, cost };
}
export function forecast(s: State) {
  const r = resolve(s, { type: "end" }).state;
  return {
    integrity: r.integrity - s.integrity,
    api: r.api - s.api,
    hazard: r.hazard,
    phase: r.phase,
    bossDamage: s.bossHP - r.bossHP,
  };
}
export function parseSave(raw: string): State {
  const s = JSON.parse(raw);
  // Preserve old slice progress instead of silently starting a different campaign.
  if (s?.version === 1) {
    s.version = 2;
    s.mode = "slice";
    s.day = s.encounter === "boss" ? 7 : 1;
    s.totalTurns = 0;
    s.history = [];
    s.stageStartIntegrity = s.integrity;
  }
  if (
    s?.version !== 2 ||
    !Array.isArray(s.board) ||
    s.board.length !== 36 ||
    ![
      "tutorial",
      "playerTurn",
      "camp",
      "dayComplete",
      "victory",
      "defeat",
    ].includes(s.phase)
  )
    throw Error("Incompatible save");
  if (
    !["slice", "campaign"].includes(s.mode) ||
    !Number.isInteger(s.day) ||
    s.day < 1 ||
    s.day > 7 ||
    !Number.isInteger(s.totalTurns) ||
    s.totalTurns < 0 ||
    !Array.isArray(s.history) ||
    !Number.isFinite(s.stageStartIntegrity) ||
    !["tutorial", "boss", "day", "bara", "gambut", "night"].includes(
      s.encounter,
    )
  )
    throw Error("Invalid campaign progress");
  for (const key of [
    "revision",
    "seed",
    "rng",
    "turn",
    "water",
    "capacity",
    "actions",
    "integrity",
    "api",
    "hazard",
    "coins",
    "fund",
    "bossHP",
    "openUntil",
    "campVisit",
  ])
    if (!Number.isFinite(s[key])) throw Error("Invalid save");
  if (s.water < 0 || s.water > s.capacity || s.actions < 0 || s.actions > 3)
    throw Error("Invalid resources");
  for (const t of s.board)
    if (
      ![
        "ground",
        "tree",
        "rock",
        "hydrant",
        "house",
        "peat",
        "vent",
        "core",
      ].includes(t.terrain) ||
      !Number.isFinite(t.fire) ||
      !Number.isFinite(t.wet) ||
      !Number.isFinite(t.foam)
    )
      throw Error("Invalid board");
  const all = [...s.hand, ...s.draw, ...s.discard];
  if (
    all.length !== deck.length ||
    deck.some(
      (c) =>
        all.filter((x) => x === c).length !==
        deck.filter((x) => x === c).length,
    )
  )
    throw Error("Invalid deck");
  if (
    !s.intent ||
    !["ember", "dry", "pop"].includes(s.intent.kind) ||
    !Array.isArray(s.intent.tiles) ||
    s.intent.tiles.some(
      (i: number) => !Number.isInteger(i) || i < 0 || i > 35,
    ) ||
    !Array.isArray(s.log) ||
    !Array.isArray(s.upgrades) ||
    s.upgrades.some((u: Upgrade) => !upgrades[u])
  )
    throw Error("Invalid intent or upgrades");
  return s as State;
}
