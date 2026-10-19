export type Card =
  | "spray"
  | "burst"
  | "foam"
  | "soak"
  | "wind"
  | "rescue"
  | "emergency";
export const cards: Record<
  Card,
  {
    name: string;
    actions: number;
    base: number;
    damage: number;
    art: string;
    text: string;
  }
> = {
  spray: {
    name: "Spray",
    actions: 1,
    base: 0,
    damage: 2,
    art: "card.spray",
    text: "Douse a fire or vent. 2 damage.",
  },
  burst: {
    name: "Burst Jet",
    actions: 2,
    base: 1,
    damage: 4,
    art: "card.burstJet",
    text: "4 damage. The only shot that hits an open core.",
  },
  foam: {
    name: "Foam Line",
    actions: 1,
    base: 1,
    damage: 0,
    art: "card.foamLine",
    text: "Route to an empty tile. Protect every hose tile for 2 resolutions.",
  },
  soak: {
    name: "Soak",
    actions: 1,
    base: 1,
    damage: 0,
    art: "card.soak",
    text: "Soak peat on two consecutive turns to clear it.",
  },
  wind: {
    name: "Wind Turn",
    actions: 1,
    base: 0,
    damage: 0,
    art: "card.windTurn",
    text: "Rotate the announced ember lane clockwise. Once per turn.",
  },
  rescue: {
    name: "Rescue",
    actions: 1,
    base: 0,
    damage: 0,
    art: "card.rescue",
    text: "Tap a house with a safe path to a hydrant. +2 Camp Fund.",
  },
  emergency: {
    name: "Emergency Spray",
    actions: 1,
    base: 1,
    damage: 1,
    art: "card.spray",
    text: "Always available. 1 damage; costs more water.",
  },
};
export const deck: Card[] = [
  "spray",
  "spray",
  "spray",
  "burst",
  "burst",
  "foam",
  "foam",
  "soak",
  "soak",
  "wind",
  "rescue",
];
export const upgrades = {
  tower: {
    name: "Water Tower",
    cost: 3,
    art: "camp.waterTower",
    text: "+4 water capacity. Refill restores 7.",
  },
  kitchen: {
    name: "Field Kitchen",
    cost: 3,
    art: "camp.fieldKitchen",
    text: "Restore 2 integrity now; +1 on later camp visits.",
  },
  shelter: {
    name: "Rescue Shelter",
    cost: 4,
    art: "camp.rescueShelter",
    text: "Once this run, survive a fatal integrity hit at 1.",
  },
};
export type Upgrade = keyof typeof upgrades;
export function apiBand(api: number) {
  return api <= 50
    ? ["Good", "#398cce", "api.good"]
    : api <= 100
      ? ["Moderate", "#45a765", "api.moderate"]
      : api <= 200
        ? ["Unhealthy", "#d6ac27", "api.unhealthy"]
        : api <= 300
          ? ["Very unhealthy", "#e28536", "api.veryUnhealthy"]
          : ["Hazardous", "#d34b56", "api.hazardous"];
}
