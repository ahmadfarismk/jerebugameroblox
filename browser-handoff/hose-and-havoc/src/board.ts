import Phaser from "phaser";
import type { State } from "./engine";
export class Board extends Phaser.Scene {
  gfx!: Phaser.GameObjects.Graphics;
  labels: Phaser.GameObjects.GameObject[] = [];
  state?: State;
  route: number[] = [];
  previewTiles?: number[];
  ready = false;
  reduced = false;
  constructor() {
    super("board");
  }
  preload() {
    this.load.on("loaderror", () =>
      window.dispatchEvent(new Event("game-asset-error")),
    );
    for (const name of ["board.fire", "board.hydrant", "board.peat"])
      this.load.image(name, `/assets/${name}.webp`);
  }
  create() {
    if (
      ["board.fire", "board.hydrant", "board.peat"].some(
        (key) => !this.textures.exists(key),
      )
    )
      window.dispatchEvent(new Event("game-asset-error"));
    this.gfx = this.add.graphics();
    this.ready = true;
    this.paint();
  }
  updateBoard(s: State, route: number[], previewTiles?: number[]) {
    this.state = s;
    this.route = route;
    this.previewTiles = previewTiles;
    if (this.ready) this.paint();
  }
  paint() {
    if (!this.state) return;
    const s = this.state,
      g = this.gfx;
    g.clear();
    this.labels.forEach((o) => o.destroy());
    this.labels = [];
    const text = (
      x: number,
      y: number,
      t: string,
      size = 18,
      color = "#5b3d7d",
    ) =>
      this.labels.push(
        this.add
          .text(x, y, t, {
            fontFamily: "Segoe UI, sans-serif",
            fontSize: size,
            fontStyle: "bold",
            color,
          })
          .setOrigin(0.5),
      );
    s.board.forEach((t, i) => {
      const x = (i % 6) * 80 + 4,
        y = Math.floor(i / 6) * 80 + 4;
      g.fillStyle(0x5b3d7d, 0.25);
      g.fillRoundedRect(x, y + 3, 72, 72, 12);
      g.fillStyle(
        t.wet
          ? 0xc5edf6
          : t.terrain === "rock"
            ? 0xc5bbc9
            : t.terrain === "peat"
              ? 0xddc3a1
              : (i + Math.floor(i / 6)) % 2
                ? 0xe1efc8
                : 0xedf5d9,
      );
      g.fillRoundedRect(x, y, 72, 70, 12);
      if ((this.previewTiles ?? s.intent.tiles).includes(i)) {
        g.lineStyle(3, s.intent.kind === "dry" ? 0xa06cc6 : 0xe88b42, 1);
        g.strokeRoundedRect(x + 3, y + 3, 66, 64, 10);
        text(x + 61, y + 12, "!", 16, "#a74c19");
      }
      if (t.foam) {
        g.lineStyle(4, 0xffffff, 1);
        g.strokeRoundedRect(x + 8, y + 8, 56, 54, 10);
        text(x + 12, y + 58, "○", 18);
      }
      const key = t.fire
        ? "board.fire"
        : t.terrain === "hydrant"
          ? "board.hydrant"
          : t.terrain === "peat"
            ? "board.peat"
            : "";
      if (key && this.textures.exists(key))
        this.labels.push(
          this.add.image(x + 36, y + 31, key).setDisplaySize(50, 50),
        );
      else if (key) text(x + 36, y + 31, t.fire ? "FIRE" : "TAP", 15);
      if (t.terrain === "tree" && !t.fire) {
        g.fillStyle(0x6aaa68);
        g.fillCircle(x + 35, y + 27, 17);
        g.fillStyle(0x946b58);
        g.fillRoundedRect(x + 31, y + 37, 8, 16, 2);
      }
      if (t.terrain === "rock") text(x + 36, y + 31, "◆", 36, "#80728b");
      if (t.terrain === "house") {
        g.fillStyle(0xd8af87);
        g.fillRoundedRect(x + 18, y + 29, 38, 26, 3);
        g.fillStyle(0x986283);
        g.fillTriangle(x + 12, y + 30, x + 37, y + 10, x + 62, y + 30);
        text(x + 36, y + 45, t.rescued ? "✓" : "⌂", 18);
      }
      if (t.terrain === "vent") text(x + 36, y + 60, `VENT ${t.fire}`, 12);
      else if (t.terrain === "core")
        text(x + 36, y + 34, s.openUntil ? "CORE ◉" : "CORE ▣", 14);
      else if (t.fire) text(x + 36, y + 60, `${t.fire} HP`, 12);
      if (t.terrain === "peat")
        text(
          x + 36,
          y + 60,
          t.cleared
            ? "CLEARED"
            : t.soaked === s.turn
              ? "SOAK 1/2"
              : t.soaked === s.turn - 1
                ? "SOAK NOW"
                : "PEAT",
          11,
        );
      if (t.wet) text(x + 12, y + 13, "~", 20, "#247aab");
    });
    if (this.route.length) {
      g.lineStyle(11, 0x5b3d7d, 1);
      this.line(g);
      g.lineStyle(6, 0x63d6ef, 1);
      this.line(g);
      for (const i of this.route) {
        g.fillStyle(0xe8fcff);
        g.fillCircle((i % 6) * 80 + 40, Math.floor(i / 6) * 80 + 40, 5);
      }
    }
  }
  line(g: Phaser.GameObjects.Graphics) {
    g.beginPath();
    this.route.forEach((i, k) =>
      k
        ? g.lineTo((i % 6) * 80 + 40, Math.floor(i / 6) * 80 + 40)
        : g.moveTo((i % 6) * 80 + 40, Math.floor(i / 6) * 80 + 40),
    );
    g.strokePath();
  }
  splash(route: number[]) {
    if (this.reduced || !this.ready) return;
    route.forEach((i, k) => {
      const drop = this.add.circle(
        (i % 6) * 80 + 40,
        Math.floor(i / 6) * 80 + 40,
        8,
        0x56d5f3,
      );
      drop.setAlpha(0);
      this.tweens.add({
        targets: drop,
        alpha: { from: 1, to: 0 },
        scale: { from: 0.3, to: 2 },
        delay: k * 25,
        duration: 220,
        onComplete: () => drop.destroy(),
      });
    });
  }
}
