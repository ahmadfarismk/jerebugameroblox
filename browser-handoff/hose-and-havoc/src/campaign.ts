import type { Tile, Intent } from "./engine";

export const days = [
  {
    name: "Welcome to the kampung.",
    area: "Training ground",
    kind: "tutorial",
    hp: 0,
    guide:
      "Training: Spray → hydrant (5,2) → adjacent tiles → fire → Confirm. Wet tiles are free to route through. Refill costs 1 action. End Turn restores 3 actions.",
  },
  {
    name: "A chain of good deeds.",
    area: "Kampung lanes",
    kind: "day",
    hp: 0,
    guide:
      "Clear the near fire, then reuse its wet route to reach the next. The house is threatened by the marked ember lane. Rescue is optional today.",
  },
  {
    name: "Bara Bebola",
    area: "The ember orchard",
    kind: "bara",
    hp: 8,
    guide:
      "Block at least TWO marked ember impacts with wet ground or foam: Bara takes 4 recoil damage and exposes its nozzle through the next turn. Burst Jet can hit the open nozzle. Two successful counters also win.",
  },
  {
    name: "Under the roots.",
    area: "Peat rescue",
    kind: "day",
    hp: 0,
    guide:
      "Soak the peat on two consecutive turns to clear it permanently. A missed follow-up reignites it. Rescue the marked house, then extinguish all fires.",
  },
  {
    name: "Gambut Gempal",
    area: "The peat marsh",
    kind: "gambut",
    hp: 8,
    guide:
      "Two hydrants, two peat patches. Clear BOTH patches with consecutive Soaks to crack Gambut’s armor permanently. Then Burst Jet its nozzle twice. Other fires do not have to be cleared to win.",
  },
  {
    name: "Against the wind.",
    area: "Last village outpost",
    kind: "day",
    hp: 0,
    guide:
      "Rescue the house and clear every fire. Wind Turn rotates the announced lane clockwise once. Foam and wet ground protect the marked tiles. Either hydrant can start a route.",
  },
  {
    name: "Raja Jerebu",
    area: "The haze throne",
    kind: "boss",
    hp: 12,
    guide:
      "Douse both vents, then Burst Jet the core. It stays open through the next player turn. Normal seeded draws apply in the campaign: plan your Burst Jets and refills around the opening.",
  },
] as const;

export function campaignBoard(day: number, night = false): Tile[] {
  const b: Tile[] = Array.from({ length: 36 }, () => ({
    terrain: "ground",
    fire: 0,
    wet: 0,
    foam: 0,
  }));
  b[32].terrain = "hydrant";
  [0, 5, 24].forEach((i) => (b[i].terrain = "tree"));
  b[23].terrain = "rock";
  b[17].terrain = "house";
  const fires = (indices: number[]) => indices.forEach((i) => (b[i].fire = 2));
  const peat = (indices: number[]) =>
    indices.forEach((i) => {
      b[i].terrain = "peat";
      b[i].fire = 2;
    });
  if (night) {
    fires([28]);
    b[17].rescued = true;
    return b;
  }
  if (day === 1) fires([20, 25, 28]);
  if (day === 2) {
    fires([20, 14, 28]);
    b[26].wet = 2;
  }
  if (day === 3) {
    b[14].terrain = "core";
    fires([25, 28]);
  }
  if (day === 4) {
    peat([26]);
    fires([20, 28]);
  }
  if (day === 5) {
    b[35].terrain = "hydrant";
    b[9].terrain = "core";
    peat([26, 28]);
  }
  if (day === 6) {
    b[35].terrain = "hydrant";
    fires([20, 14, 28]);
  }
  if (day === 7) {
    b[2].terrain = "core";
    [7, 10].forEach((i) => {
      b[i].terrain = "vent";
      b[i].fire = 2;
    });
  }
  return b;
}

export function campaignIntent(
  day: number,
  turn: number,
  night: boolean,
): Intent | undefined {
  if (night) return { kind: "ember", tiles: [30, 31, 32], rotated: false };
  if (day === 1) return { kind: "ember", tiles: [15, 16, 17], rotated: false };
  if (day === 2)
    return {
      kind: turn % 2 ? "ember" : "dry",
      tiles: turn % 2 ? [15, 16, 17] : [0, 6, 12, 18, 24, 30],
      rotated: false,
    };
  if (day === 3)
    return { kind: "ember", tiles: [24, 25, 26, 27, 28, 29], rotated: false };
  if (day === 4)
    return {
      kind: turn % 2 ? "pop" : "dry",
      tiles: turn % 2 ? [18] : [0, 6, 12, 18, 24, 30],
      rotated: false,
    };
  if (day === 5)
    return {
      kind: turn % 2 ? "pop" : "dry",
      tiles: turn % 2 ? [18, 19] : [0, 6, 12, 18, 24, 30],
      rotated: false,
    };
  if (day === 6)
    return {
      kind: turn % 2 ? "ember" : "dry",
      tiles: turn % 2 ? [15, 16, 17] : [0, 6, 12, 18, 24, 30],
      rotated: false,
    };
  return undefined;
}

export function monsterArt(kind: string): string {
  if (kind === "bara")
    return `<div class="mini-monster bara" role="img" aria-label="Bara Bebola: a smug ember ball"><i class="mini-eye"></i><i class="mini-eye"></i><span class="mini-mouth">⌣</span><b class="mini-arm left">〜</b><b class="mini-arm right">〜</b></div>`;
  if (kind === "gambut")
    return `<div class="mini-monster gambut" role="img" aria-label="Gambut Gempal: a grumpy peat mound"><i class="mini-eye"></i><i class="mini-eye"></i><span class="mini-mouth">⌢</span><b class="peat-seam"></b><b class="mini-arm left">⌁</b><b class="mini-arm right">⌁</b></div>`;
  return "";
}
