import { test } from "node:test";
import assert from "node:assert/strict";
import {
  newRun,
  resolve,
  parseSave,
  forecast,
  type State,
  type Command,
} from "../src/engine";
import { campaignBoard, campaignIntent, days } from "../src/campaign";
import { deck, type Card } from "../src/data";
import { runCampaign, routeTo } from "./campaign-player";
function act(s: State, c: Command) {
  const r = resolve(s, c);
  assert.ok(r.ok, r.message);
  return r.state;
}
function give(s: State, c: Card) {
  if (s.hand.includes(c)) return;
  for (const pile of [s.draw, s.discard]) {
    const i = pile.indexOf(c);
    if (i >= 0) {
      pile.splice(i, 1);
      const old = s.hand.pop();
      if (old) pile.push(old);
      s.hand.push(c);
      return;
    }
  }
}
function stage(day: number, night = false) {
  const s = newRun(42, "campaign");
  s.day = day;
  s.encounter = night ? "night" : days[day - 1].kind;
  s.phase = "playerTurn";
  s.board = campaignBoard(day, night);
  s.bossHP = night ? 0 : days[day - 1].hp;
  s.intent = campaignIntent(day, 1, night) ?? s.intent;
  return s;
}
function training() {
  let s = newRun(42, "campaign");
  for (const route of [
    [32, 26, 20],
    [32, 31, 25],
    [32, 33, 34, 28],
  ])
    s = act(s, { type: "play", card: "spray", route });
  return s;
}
test("day → Malam → camp → next day preserves the eleven-card deck", () => {
  let s = training();
  assert.equal(s.phase, "dayComplete");
  assert.equal(s.history.length, 1);
  assert.equal(s.fund, 6);
  const reload = parseSave(JSON.stringify(s));
  assert.deepEqual(s, reload);
  s = act(s, { type: "continue" });
  assert.equal(s.encounter, "night");
  assert.equal(s.day, 1);
  assert.equal(s.water, 10);
  assert.deepEqual(
    [...s.hand, ...s.draw, ...s.discard].sort(),
    [...deck].sort(),
  );
  assert.equal(resolve(s, { type: "continue" }).ok, false);
  s = act(s, { type: "end" });
  assert.equal(s.phase, "camp");
  assert.equal(s.history.length, 2);
  assert.equal(s.campVisit, 1);
  s = act(s, { type: "continue" });
  assert.equal(s.day, 2);
  assert.equal(s.encounter, "day");
  assert.equal(s.turn, 1);
  assert.deepEqual(
    [...s.hand, ...s.draw, ...s.discard].sort(),
    [...deck].sort(),
  );
});
test("Malam requires one resolution even after extinguishing every fire; loss wins over camp rewards", () => {
  let s = stage(1, true);
  s = act(s, { type: "play", card: "spray", route: [32, 33, 34, 28] });
  assert.equal(s.phase, "playerTurn");
  assert.equal(s.history.length, 0);
  s.integrity = 1;
  s.stageStartIntegrity = 1;
  const fund = s.fund;
  s = act(s, { type: "end" });
  assert.equal(s.phase, "defeat");
  assert.equal(s.fund, fund);
  assert.equal(s.history.length, 0);
});
test("Foam and Wind protect night camp; forecast equals committed result", () => {
  for (const card of ["foam", "wind"] as const) {
    let s = stage(2, true);
    give(s, card);
    s = act(s, { type: "play", card, route: card === "foam" ? [32, 31] : [] });
    const f = forecast(s),
      before = structuredClone(s);
    s = act(s, { type: "end" });
    assert.equal(s.integrity, 5);
    assert.equal(s.fund, 2);
    assert.equal(s.api - before.api, f.api);
    assert.equal(s.integrity - before.integrity, f.integrity);
    assert.equal(s.campVisit, 1);
    assert.equal(s.history[0].period, "night");
  }
});
test("Kitchen heal, camp ventilation, purchase and night rewards cannot repeat on reload", () => {
  let s = stage(3, true);
  s.integrity = s.stageStartIntegrity = 3;
  s.api = 150;
  s.upgrades = ["kitchen"];
  s = act(s, { type: "end" });
  assert.equal(s.integrity, 3);
  assert.equal(s.api, 144);
  assert.match(s.message, /cleared 30 API/);
  const again = parseSave(JSON.stringify(s));
  assert.deepEqual(again, s);
  assert.equal(resolve(again, { type: "end" }).ok, false);
  s.fund = 8;
  s = act(s, { type: "buy", upgrade: "tower" });
  assert.equal(s.capacity, 14);
  assert.equal(resolve(s, { type: "buy", upgrade: "shelter" }).ok, false);
  const visited = s.campVisit;
  s = act(s, { type: "continue" });
  assert.equal(s.integrity, 3);
  assert.equal(s.campVisit, visited);
});
test("Bara has a real blocked-lane counter and exposed nozzle, with no same-turn telegraph damage", () => {
  let s = stage(3);
  give(s, "burst");
  assert.equal(
    resolve(s, { type: "play", card: "burst", route: [32, 26, 20, 14] }).ok,
    false,
  );
  give(s, "foam");
  s = act(s, { type: "play", card: "foam", route: [32, 26, 27] });
  assert.equal(forecast(s).bossDamage, 4);
  s = act(s, { type: "end" });
  assert.equal(s.bossHP, 4);
  assert.equal(s.openUntil, 2);
  assert.equal(s.turn, 2);
  assert.equal(s.phase, "playerTurn");
  s = act(s, { type: "end" });
  assert.equal(s.phase, "dayComplete");
  assert.equal(s.bossHP, 0);
  assert.equal(s.history.length, 1);
  assert.equal(s.history[0].turns, 2);
});
test("Gambut needs both permanent peat clears and supports the second hydrant", () => {
  let s = stage(5);
  give(s, "burst");
  assert.equal(
    resolve(s, {
      type: "play",
      card: "burst",
      route: [35, 29, 28, 22, 16, 10, 9],
    }).ok,
    false,
  );
  s.board[26].cleared = true;
  s.board[26].fire = 0;
  s.board[28].soaked = 0;
  s.water = 10;
  give(s, "soak");
  s = act(s, { type: "play", card: "soak", route: [35, 34, 28] });
  assert.equal(s.openUntil, 999);
  assert.equal(s.board[28].cleared, true);
  give(s, "burst");
  s.water = 14;
  s = act(s, {
    type: "play",
    card: "burst",
    route: [35, 34, 28, 22, 16, 10, 9],
  });
  assert.equal(s.bossHP, 4);
  s = act(s, { type: "end" });
  assert.equal(s.openUntil, 999);
  give(s, "burst");
  s.water = 14;
  s = act(s, {
    type: "play",
    card: "burst",
    route: [35, 34, 28, 22, 16, 10, 9],
  });
  assert.equal(s.phase, "dayComplete");
});
test("required rescue gates ordinary day completion; Day 7 has no extra night", () => {
  let s = stage(4);
  s.board.forEach((t) => {
    t.fire = 0;
    if (t.terrain === "peat") t.cleared = true;
  });
  give(s, "rescue");
  assert.equal(s.phase, "playerTurn");
  s = act(s, { type: "play", card: "rescue", route: [], target: 17 });
  assert.equal(s.phase, "dayComplete");
  let b = stage(7);
  b.bossHP = 4;
  b.openUntil = 2;
  b.board[7].fire = b.board[10].fire = 0;
  give(b, "burst");
  b = act(b, { type: "play", card: "burst", route: [32, 26, 20, 14, 8, 2] });
  assert.equal(b.phase, "victory");
  assert.equal(resolve(b, { type: "continue" }).ok, false);
});
test("legacy slice saves migrate without reroll; malformed campaign progress is rejected", () => {
  const old: any = newRun(9);
  old.version = 1;
  for (const key of [
    "mode",
    "day",
    "totalTurns",
    "history",
    "stageStartIntegrity",
  ])
    delete old[key];
  const migrated = parseSave(JSON.stringify(old));
  assert.equal(migrated.version, 2);
  assert.equal(migrated.mode, "slice");
  assert.deepEqual(migrated.hand, old.hand);
  assert.equal(migrated.rng, old.rng);
  assert.throws(() =>
    parseSave(JSON.stringify({ ...newRun(1, "campaign"), day: 8 })),
  );
});
test("every authored objective has a legal route before or after dousing blockers", () => {
  for (let d = 1; d <= 7; d++) {
    const s = stage(d);
    s.board.forEach((t) => (t.fire = 0));
    s.board.forEach((t, i) => {
      if (["peat", "vent", "core"].includes(t.terrain))
        assert.ok(routeTo(s, i), `day ${d} target ${i}`);
    });
  }
});
test("complete campaign wins reproducibly and survives save/resume at every command", () => {
  const { state, commands } = runCampaign(42);
  assert.equal(state.phase, "victory");
  assert.equal(state.history.length, 13);
  assert.equal(state.history.filter((h) => h.period === "night").length, 6);
  assert.equal(state.campVisit, 6);
  let replay = newRun(42, "campaign");
  for (const c of commands) {
    const before = JSON.stringify(replay);
    const preview = resolve(replay, c);
    assert.equal(JSON.stringify(replay), before);
    replay = parseSave(JSON.stringify(act(replay, c)));
    assert.deepEqual(replay, parseSave(JSON.stringify(preview.state)));
    assert.deepEqual(
      [...replay.hand, ...replay.draw, ...replay.discard].sort(),
      [...deck].sort(),
    );
  }
  assert.deepEqual(replay, parseSave(JSON.stringify(state)));
});
