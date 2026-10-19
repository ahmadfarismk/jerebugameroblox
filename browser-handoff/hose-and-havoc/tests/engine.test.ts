import { test } from "node:test";
import assert from "node:assert/strict";
import {
  newRun,
  resolve,
  parseSave,
  type State,
  type Command,
} from "../src/engine";
import { deck, type Card } from "../src/data";
function act(s: State, c: Command) {
  const r = resolve(s, c);
  assert.ok(r.ok, r.message);
  return r.state;
}
function give(s: State, c: Card) {
  if (s.hand.includes(c)) return;
  for (const p of [s.draw, s.discard]) {
    const i = p.indexOf(c);
    if (i >= 0) {
      p.splice(i, 1);
      const old = s.hand.pop();
      if (old) p.push(old);
      s.hand.push(c);
      return;
    }
  }
}
function boss() {
  let s = newRun(42);
  s = act(s, { type: "play", card: "spray", route: [32, 26, 20] });
  s = act(s, { type: "play", card: "spray", route: [32, 31, 25] });
  s = act(s, { type: "play", card: "spray", route: [32, 33, 34, 28] });
  assert.equal(s.phase, "camp");
  return act(s, { type: "continue" });
}
test("preview is pure, exact dry/wet costs and revision protects duplicate commit", () => {
  const s = newRun(42),
    raw = JSON.stringify(s),
    c: Command = { type: "play", card: "spray", route: [32, 26, 20] };
  const p = resolve(s, c);
  assert.equal(JSON.stringify(s), raw);
  assert.equal(p.cost, 2);
  assert.equal(p.state.water, 8);
  assert.deepEqual(resolve(s, c), p);
  assert.equal(resolve(p.state, c, s.revision).ok, false);
  const foam = structuredClone(p.state);
  give(foam, "foam");
  assert.equal(
    resolve(foam, { type: "play", card: "foam", route: [32, 26, 20] }).cost,
    1,
  );
});
test("invalid routes and overspending never change resources", () => {
  const s = newRun(7);
  for (const route of [
    [32, 25],
    [32, 26, 32],
    [31, 25],
    [32, 26, 20, 14],
    [32, 33, 34, 35, 29, 23],
  ]) {
    const r = resolve(s, { type: "play", card: "spray", route });
    assert.equal(r.ok, false);
    assert.deepEqual(r.state, s);
  }
  s.water = 0;
  assert.equal(
    resolve(s, { type: "play", card: "spray", route: [32, 26, 20] }).ok,
    false,
  );
  s.actions = 0;
  assert.equal(resolve(s, { type: "refill" }).ok, false);
  assert.equal(resolve(s, { type: "end" }).ok, true);
});
test("deck exhausts and reshuffles deterministically without duplicates", () => {
  let a = newRun(81),
    b = newRun(81);
  a.integrity = b.integrity = 999;
  for (let i = 0; i < 10; i++) {
    a.api = b.api = 0;
    a = act(a, { type: "end" });
    b = act(b, { type: "end" });
    assert.deepEqual(a, b);
    assert.deepEqual(
      [...a.hand, ...a.draw, ...a.discard].sort(),
      [...deck].sort(),
    );
  }
});
test("wet protects twice, foam consumes on impact; next telegraph does not hit early", () => {
  let s = newRun(1);
  s.board[17].wet = 2;
  s.board[12].foam = 2;
  s = act(s, { type: "end" });
  assert.equal(s.integrity, 5);
  assert.equal(s.board[17].wet, 1);
  assert.equal(s.board[12].fire, 0);
  assert.equal(s.board[12].foam, 0);
  s = act(s, { type: "end" });
  assert.equal(s.integrity, 5);
  assert.equal(s.board[17].wet, 0);
  s = act(s, { type: "end" });
  assert.equal(s.integrity, 4);
});
test("boss rejects shielded core without spending; window lasts through next turn", () => {
  let s = boss();
  give(s, "burst");
  assert.equal(
    resolve(s, { type: "play", card: "burst", route: [32, 26, 20, 14, 8, 2] })
      .ok,
    false,
  );
  s.water = 30;
  give(s, "spray");
  s = act(s, { type: "play", card: "spray", route: [32, 26, 20, 14, 8, 7] });
  give(s, "spray");
  s = act(s, {
    type: "play",
    card: "spray",
    route: [32, 26, 20, 14, 15, 16, 10],
  });
  assert.equal(s.openUntil, 2);
  assert.ok(s.hand.includes("burst"));
  assert.deepEqual(
    [...s.hand, ...s.draw, ...s.discard].sort(),
    [...deck].sort(),
  );
  s = act(s, { type: "end" });
  assert.equal(s.openUntil, 2);
  assert.ok(s.hand.includes("burst"));
  s = act(s, { type: "play", card: "burst", route: [32, 26, 20, 14, 8, 2] });
  assert.equal(s.bossHP, 8);
  s = act(s, { type: "end" });
  assert.equal(s.openUntil, 0);
  assert.equal(s.board[7].fire, 2);
});
test("hazard warning then loss, shelter prevents one fatal hit, victories", () => {
  let s = newRun(1);
  s.api = 301;
  s = act(s, { type: "end" });
  assert.equal(s.hazard, 1);
  assert.match(s.message, /WARNING/);
  s = act(s, { type: "end" });
  assert.equal(s.phase, "defeat");
  s = newRun(1);
  s.integrity = 1;
  s.shelter = true;
  s = act(s, { type: "end" });
  assert.equal(s.integrity, 1);
  assert.equal(s.shelter, false);
  s = act(s, { type: "end" });
  assert.equal(s.phase, "defeat");
  let b = boss();
  b.bossHP = 4;
  b.openUntil = 2;
  b.board[7].fire = b.board[10].fire = 0;
  give(b, "burst");
  b = act(b, { type: "play", card: "burst", route: [32, 26, 20, 14, 8, 2] });
  assert.equal(b.phase, "victory");
});
test("rescue is finite and wind rotates exactly once", () => {
  let s = newRun(1);
  give(s, "rescue");
  s = act(s, { type: "play", card: "rescue", route: [], target: 17 });
  assert.equal(s.fund, 2);
  give(s, "rescue");
  assert.equal(
    resolve(s, { type: "play", card: "rescue", route: [], target: 17 }).ok,
    false,
  );
  give(s, "wind");
  s = act(s, { type: "play", card: "wind", route: [] });
  assert.deepEqual(s.intent.tiles, [3, 9, 15, 21, 27, 33]);
  give(s, "wind");
  assert.equal(resolve(s, { type: "play", card: "wind", route: [] }).ok, false);
});
test("peat needs consecutive turns; suppression gives no rewards", () => {
  let s = newRun(1);
  s.board[26].terrain = "peat";
  s.board[26].fire = 2;
  give(s, "soak");
  s = act(s, { type: "play", card: "soak", route: [32, 26] });
  assert.equal(s.fund, 0);
  s = act(s, { type: "end" });
  assert.equal(s.board[26].fire, 0);
  give(s, "soak");
  s = act(s, { type: "play", card: "soak", route: [32, 26] });
  assert.equal(s.board[26].cleared, true);
  assert.equal(s.fund, 1);
  let b = newRun(1);
  b.board[26].terrain = "peat";
  b.board[26].fire = 2;
  give(b, "soak");
  b = act(b, { type: "play", card: "soak", route: [32, 26] });
  b = act(b, { type: "end" });
  b = act(b, { type: "end" });
  assert.equal(b.board[26].fire, 2);
});
test("save validates corruption, retains full state, camp purchase is once only", () => {
  let s = newRun(42);
  s = act(s, { type: "play", card: "spray", route: [32, 26, 20] });
  s = act(s, { type: "play", card: "spray", route: [32, 31, 25] });
  s = act(s, { type: "play", card: "spray", route: [32, 33, 34, 28] });
  assert.equal(s.fund, 6);
  s.integrity = 2;
  s = act(s, { type: "buy", upgrade: "kitchen" });
  assert.equal(s.integrity, 4);
  const loaded = parseSave(JSON.stringify(s));
  assert.deepEqual(loaded, s);
  assert.equal(resolve(loaded, { type: "buy", upgrade: "kitchen" }).ok, false);
  assert.equal(loaded.integrity, 4);
  assert.throws(() => parseSave("{}"));
  assert.throws(() => parseSave("{"));
  assert.throws(() => parseSave(JSON.stringify({ ...s, hand: [] })));
});
