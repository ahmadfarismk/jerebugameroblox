import {
  newRun,
  resolve,
  neighbors,
  forecast,
  needsRescue,
  type State,
  type Command,
} from "../src/engine";
import { type Card } from "../src/data";

export function routeTo(s: State, target: number): number[] | undefined {
  const q: { route: number[]; cost: number }[] = s.board.flatMap((t, i) =>
    t.terrain === "hydrant" ? [{ route: [i], cost: 0 }] : [],
  );
  const best = new Map<string, number>();
  while (q.length) {
    q.sort((a, b) => a.cost - b.cost || a.route.length - b.route.length);
    const { route, cost } = q.shift()!;
    const i = route.at(-1)!;
    if (i === target && route.length > 1) return route;
    if (route.length >= 9) continue;
    for (const n of neighbors(i)) {
      const t = s.board[n];
      if (
        route.includes(n) ||
        t.terrain === "rock" ||
        t.terrain === "house" ||
        (n !== target &&
          (t.fire || t.terrain === "vent" || t.terrain === "core"))
      )
        continue;
      const nc = cost + (t.wet ? 0 : 1),
        key = `${n}:${route.length + 1}`;
      if ((best.get(key) ?? Infinity) <= nc) continue;
      best.set(key, nc);
      q.push({ route: [...route, n], cost: nc });
    }
  }
}
export function choose(s: State): Command {
  if (s.phase === "camp") {
    for (const upgrade of ["tower", "kitchen", "shelter"] as const) {
      const c: Command = { type: "buy", upgrade };
      if (resolve(s, c).ok) return c;
    }
    return { type: "continue" };
  }
  if (s.phase === "dayComplete") return { type: "continue" };
  const candidates: { command: Command; score: number }[] = [];
  const before = forecast(s);
  for (const card of new Set<Card>([...s.hand, "emergency"])) {
    const targets =
      card === "wind"
        ? [-1]
        : card === "rescue"
          ? s.board.flatMap((t, i) => (t.terrain === "house" ? [i] : []))
          : s.board.flatMap((t, i) =>
              (
                card === "foam"
                  ? !t.fire && t.terrain === "ground"
                  : card === "soak"
                    ? t.terrain === "peat" && !t.cleared
                    : t.fire > 0 || t.terrain === "core"
              )
                ? [i]
                : [],
            );
    for (const target of targets) {
      const route = ["wind", "rescue"].includes(card) ? [] : routeTo(s, target);
      if (!route) continue;
      const command: Command = {
        type: "play",
        card,
        route,
        target: card === "rescue" ? target : undefined,
      };
      const result = resolve(s, command);
      if (!result.ok) continue;
      const t = s.board[target];
      let score = 0;
      if (card === "wind" || card === "foam") {
        const after = forecast(result.state);
        score =
          (after.integrity - before.integrity) * 100 +
          (after.bossDamage - before.bossDamage) * 30 +
          (before.api - after.api) * 0.15;
        if (s.encounter === "night" && card === "foam" && s.board[32].foam)
          score = 0;
      } else if (card === "rescue") score = needsRescue(s) ? 150 : 10;
      else if (card === "soak") score = t.soaked === s.turn - 1 ? 200 : 90;
      else if (t.terrain === "core") score = 220;
      else if (t.terrain === "peat") score = 0;
      else
        score =
          (t.terrain === "vent" ? 100 : 55) +
          (t.fire - result.state.board[target].fire) * 5;
      score -= result.cost * 0.4 + (s.actions - result.state.actions) * 4;
      if (score > 0) candidates.push({ command, score });
    }
  }
  if (s.encounter === "bara" && before.bossDamage >= 4) return { type: "end" };
  candidates.sort((a, b) => b.score - a.score);
  if (candidates.length) return candidates[0].command;
  if (s.actions && s.water < s.capacity) return { type: "refill" };
  return { type: "end" };
}
export function runCampaign(seed: number) {
  let state = newRun(seed, "campaign");
  const commands: Command[] = [];
  for (
    let i = 0;
    i < 900 && !["victory", "defeat"].includes(state.phase);
    i++
  ) {
    const command = choose(state);
    const r = resolve(state, command);
    if (!r.ok) throw Error(r.message);
    state = r.state;
    commands.push(command);
  }
  return { state, commands };
}
