import { test } from "node:test";
import assert from "node:assert/strict";
import { newRun, resolve, type Command } from "../src/engine";
test("boss can be beaten after skipping camp upgrades", () => {
  let s = newRun(2373565907);
  const left = [32, 26, 20, 14, 8, 7],
    right = [32, 26, 20, 14, 15, 16, 10],
    core = [32, 26, 20, 14, 8, 2];
  const commands: Command[] = [
    { type: "play", card: "spray", route: [32, 26, 20] },
    { type: "play", card: "spray", route: [32, 31, 25] },
    { type: "play", card: "spray", route: [32, 33, 34, 28] },
    { type: "continue" },
    { type: "play", card: "spray", route: left },
    { type: "play", card: "burst", route: right },
    { type: "end" },
    { type: "refill" },
    { type: "play", card: "burst", route: core },
    { type: "end" },
    { type: "play", card: "spray", route: left },
    { type: "play", card: "spray", route: right },
    { type: "refill" },
    { type: "end" },
    { type: "play", card: "burst", route: core },
    { type: "play", card: "spray", route: [32, 26, 20, 14, 13] },
    { type: "end" },
    { type: "play", card: "spray", route: left },
    { type: "refill" },
    { type: "play", card: "spray", route: right },
    { type: "end" },
    { type: "play", card: "burst", route: core },
  ];
  for (const command of commands) {
    const r = resolve(s, command);
    assert.ok(r.ok, `Turn ${s.turn}: ${r.message}`);
    s = r.state;
  }
  assert.equal(s.phase, "victory");
  assert.equal(s.upgrades.length, 0);
});
test("recorded browser victory seed 2373565907 replays without cheats", () => {
  let s = newRun(2373565907);
  const left = [32, 26, 20, 14, 8, 7],
    right = [32, 26, 20, 14, 15, 16, 10],
    core = [32, 26, 20, 14, 8, 2];
  const commands: Command[] = [
    { type: "play", card: "spray", route: [32, 26, 20] },
    { type: "play", card: "spray", route: [32, 31, 25] },
    { type: "play", card: "spray", route: [32, 33, 34, 28] },
    { type: "buy", upgrade: "tower" },
    { type: "continue" },
    { type: "play", card: "spray", route: left },
    { type: "play", card: "burst", route: right },
    { type: "end" },
    { type: "play", card: "burst", route: core },
    { type: "refill" },
    { type: "end" },
    { type: "play", card: "spray", route: left },
    { type: "play", card: "spray", route: right },
    { type: "refill" },
    { type: "end" },
    { type: "play", card: "burst", route: core },
    { type: "play", card: "spray", route: [32, 26, 20, 14, 13] },
    { type: "end" },
    { type: "play", card: "spray", route: left },
    { type: "play", card: "spray", route: right },
    { type: "end" },
    { type: "play", card: "burst", route: core },
  ];
  for (const c of commands) {
    const r = resolve(s, c);
    assert.ok(r.ok, `Turn ${s.turn} ${JSON.stringify(c)}: ${r.message}`);
    s = r.state;
  }
  assert.equal(s.phase, "victory");
  assert.equal(s.integrity, 4);
  assert.equal(s.turn, 6);
});
