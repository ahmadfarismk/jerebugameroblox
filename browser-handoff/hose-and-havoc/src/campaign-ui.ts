import { days, monsterArt } from "./campaign";
import { isBoss, needsRescue, type State } from "./engine";
import { upgrades, type Upgrade } from "./data";
const art = (key: string, cls = "") =>
  `<img class="${cls}" src="/assets/${key}.webp" alt="">`;
export function stageName(s: State) {
  return s.encounter === "night"
    ? `Malam ${s.day} · Keep the camp safe`
    : s.mode === "campaign"
      ? days[s.day - 1].name
      : s.encounter === "tutorial"
        ? "Welcome to the kampung."
        : "Raja Jerebu";
}
export function stageGuide(s: State) {
  if (s.encounter === "night")
    return "One defense round. Protect the hydrant at (5,2): Foam Line includes its source tile, or Wind Turn rotates the lane away. Clear the fire to lower API. End Turn resolves the night even if fires remain. No new deck; water was refilled at dusk. Surviving the night clears up to 30 API through camp ventilation.";
  if (s.mode === "campaign") return days[s.day - 1].guide;
  return s.encounter === "tutorial"
    ? days[0].guide
    : "Douse both vents. Keep a wet path up the middle. Burst Jet the core before the window closes. Intro assistance guarantees a Burst Jet during each opening.";
}
export function progress(s: State) {
  return s.mode === "campaign"
    ? `<nav class="campaign-track" aria-label="Seven-day campaign">${days.map((d, i) => `<span class="${i + 1 === s.day ? "current" : s.history.some((h) => h.day === i + 1 && h.period === "day") ? "done" : ""}" aria-label="Hari ${i + 1}: ${d.name}"><b>${s.history.some((h) => h.day === i + 1 && h.period === "day") ? "✓" : i + 1}</b><small>${i === 2 ? "Bara" : i === 4 ? "Gambut" : i === 6 ? "Raja" : "Hari"}</small></span>`).join("")}</nav>`
    : "";
}
export function objectives(s: State) {
  if (s.encounter === "night")
    return "DEFEND · 1 round remaining · Night reward: +2 fund if no integrity lost, otherwise +1.";
  if (isBoss(s))
    return s.encounter === "bara"
      ? "COUNTER · Block 2+ ember tiles in one resolution → 4 recoil damage."
      : s.encounter === "gambut"
        ? `ARMOR · ${s.board.filter((t) => t.terrain === "peat" && t.cleared).length}/2 peat patches cleared.`
        : `VENTS · ${s.board.filter((t) => t.terrain === "vent" && !t.fire).length}/2 doused.`;
  return `OBJECTIVE · ${s.board.filter((t) => t.fire || (t.terrain === "peat" && !t.cleared)).length} fires / peat remaining${needsRescue(s) ? ` · Rescue ${s.board.filter((t) => t.terrain === "house" && t.rescued).length}/${s.board.filter((t) => t.terrain === "house").length}` : ""}`;
}
export function bossPanel(s: State) {
  if (!isBoss(s)) return "";
  const hp = s.encounter === "boss" ? 12 : 8;
  const name =
    s.encounter === "boss"
      ? "Raja Jerebu"
      : s.encounter === "bara"
        ? "Bara Bebola"
        : "Gambut Gempal";
  const status = s.openUntil
    ? "NOZZLE OPEN"
    : s.encounter === "gambut"
      ? "PEAT ARMOR"
      : "CORE SHIELDED";
  const hint = s.openUntil
    ? s.encounter === "gambut"
      ? "Armor broken permanently. Burst Jet the nozzle."
      : `Burst Jet now! Open through turn ${s.openUntil}.`
    : s.encounter === "bara"
      ? "Block two ember impacts to counter for 4 damage."
      : s.encounter === "gambut"
        ? "Clear both peat patches to break the armor."
        : "Douse both vents to expose the core.";
  return `<div class="boss-strip ${s.bossHP < hp / 2 ? "angry" : ""}">${s.encounter === "boss" ? art("boss.rajaJerebu") : monsterArt(s.encounter)}<div><b>${name} · ${s.bossHP}/${hp} HP</b><div class="health"><i style="width:${(s.bossHP / hp) * 100}%"></i></div><small><strong>${status}</strong> · ${hint}</small></div></div>`;
}
export function interlude(s: State) {
  const track = progress(s);
  if (s.phase === "dayComplete")
    return `<section class="interlude">${track}<p class="eyebrow">HARI ${s.day} / MISSION COMPLETE</p><h1>${s.encounter === "bara" ? "The ball has lost its bounce." : s.encounter === "gambut" ? "Grump successfully soaked." : "Day saved. Night incoming."}</h1>${isBoss(s) ? `<div class="defeated-mini">${monsterArt(s.encounter)}</div>` : ""}<p>${s.message}</p><div class="result-stats"><b>${s.integrity}/5 integrity</b><b>${s.api} API</b><b>${s.fund} Camp Fund</b></div><p>Next: defend the camp for one announced enemy resolution.<br>Same deck. Full water. No ticking clock.</p><button class="primary" id="continue">Begin Malam ${s.day} →</button><button id="interlude-home">Save & menu</button></section>`;
  if (s.phase === "camp")
    return `<section class="interlude">${track}<p class="eyebrow">KEM ${s.campVisit} / A BREATHER BEFORE THE STORM</p><h1>${s.mode === "campaign" ? "Night watch complete." : "Good work, crew."}</h1><p>${s.message}</p><div class="fund">${art("hud.coins")}<b>${s.fund} Camp Fund</b><span>${s.coins} personal coins · ${s.integrity}/5 integrity</span></div><div class="upgrade-grid">${Object.entries(
      upgrades,
    )
      .map(
        ([id, u]) =>
          `<button class="upgrade" data-upgrade="${id}" ${s.purchaseMade || s.fund < u.cost || s.upgrades.includes(id as Upgrade) ? "disabled" : ""}>${art(u.art)}<h2>${u.name}</h2><p>${u.text}</p><b>${s.upgrades.includes(id as Upgrade) ? "Installed" : s.purchaseMade ? "One choice already made" : s.fund < u.cost ? `Need ${u.cost - s.fund} more fund` : `${u.cost} Camp Fund`}</b></button>`,
      )
      .join(
        "",
      )}</div><p>Next: ${s.mode === "campaign" ? `Hari ${s.day + 1} — ${days[s.day].name.replace(/\.$/, "")}` : "Raja Jerebu"}. Water refilled at departure.<br>Your deck and remaining API carry over. ${s.mode === "campaign" ? "Ventilation removes up to 30 API; " : ""}Kitchen healing happens once per camp visit.</p><button class="primary" id="continue">${s.purchaseMade ? "Continue" : "Skip upgrade & continue"} →</button><button id="interlude-home">Save & menu</button><p class="small">${s.upgrades.includes("shelter") ? `Shelter charge: ${s.shelter ? "ready" : "spent"}. ` : ""}Saved on this device. Reloading does not repeat rewards.</p></section>`;
  return `<section class="interlude finale ${s.phase}">${track}${art("boss.rajaJerebu", "final-boss")}<p class="eyebrow">${s.phase === "victory" ? "LANGIT CERAH / CLEAR SKIES" : `RETREAT / ${s.encounter === "night" ? "MALAM" : "HARI"} ${s.day}`}</p><h1>${s.phase === "victory" ? "Kampung saved!" : "Time to regroup."}</h1><p>${s.message}</p><div class="result-stats"><b>${s.coins} coins</b><b>${s.integrity}/5 integrity</b><b>${s.totalTurns} resolutions</b></div><p class="small">Seed ${s.seed} · ${s.log.length} commands · ${s.mode === "campaign" ? "Seven-day campaign" : "Quick tutorial + Raja slice"}</p><button class="primary" id="again">Play again ↗</button><button id="interlude-home">Main menu</button>${s.history.length ? `<details class="run-journal"><summary>Run journal · ${s.history.length} encounters</summary><ol>${s.history.map((h) => `<li><b>${h.period === "day" ? "Hari" : "Malam"} ${h.day}</b> · ${h.turns} turn(s) · ${h.integrity}/5 integrity · API ${h.api}<br>${h.summary}</li>`).join("")}</ol></details>` : ""}</section>`;
}
