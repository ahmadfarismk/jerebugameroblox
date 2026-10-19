#!/usr/bin/env python3
"""Jerebu economy simulator.

Run:  python design/economy_sim.py            (CURRENT vs PROPOSED, every scenario)
      python design/economy_sim.py --quiet    (skip the per-day tables)

Model (calibrated to reports/game-tester-report.md):
  * One run = 7 days x 240 s, ~30.5 min wall time (20 s intermission + 7*(240+14) + 30 s ending).
  * Fires spawned per day = (burst + 240/spawnEvery) x 1.15 from Day 2 (spread). Measured: D1 11, D2 16.
  * A player's capacity (fires/day) = 240 / seconds_per_fire, with
        seconds_per_fire = travel + spray + peat soak + refill
        travel  = (D - 0.6*(range-40)) / speed (+2 s hop on/off a ride), D ~ 320 studs growing with spawn radius
        spray   = 84 / (24 * pressure * hose.power)          (~3.5 s at base, measured 30-39 s per 10 fires)
        refill  = (water_per_fire / tank) * (60/walk + 3/refillMul)
    Calibration: base player D1 -> ~24 s/fire -> ~10 fires/day (tester: 10 out of 11 spawned);
    walking is ~70% of the day.
  * Fires put out = min(sum of capacities, 0.92 * spawned), split by capacity share
    (the server splits each reward by damage contribution).
  * Coins per fire = FireReward / PeatReward weighted by the day's peat chance, x coinMul,
    plus the end-of-run bonus (clear 60 / survived 35 / emergency 15) chosen from average catch rate.
  * Shopping happens between days. Policy "greedy" = always buy the cheapest next item (N95 is bought
    directly; Progression.buyMask allows tier jumps). Policy "guided" = N95, Bicycle, Kapcai pinned first,
    then best capacity-gain per coin (an efficient player following the in-game tips).
  * coop_scale (>0) models an OPTIONAL server change: spawned fires x (1 + coop_scale*(players-1)).
"""
import sys
import math
import copy

# --------------------------------------------------------------------------- config sets
BASE = dict(
    name="CURRENT",
    FireReward=10, PeatReward=16, run_bonus=(60, 35, 15),
    TrackCostGrowth=1.45,
    tracks={  # id: (min, max, base)
        "Speed": (18, 27, 40), "Pressure": (1, 2.2, 50), "Tank": (100, 550, 40),
        "Range": (40, 70, 45), "Refill": (1, 3, 30), "Lungs": (0, 0.6, 35)},
    hoses=[(1.00, 1.0, 0), (1.15, 1.0, 300), (1.30, 1.0, 900), (1.45, 1.0, 2200), (1.60, 1.5, 4500), (1.80, 1.5, 9000)],
    peatSoak=[1, 1, 1, 2, 2, 2],
    masks=[(0.25, 30), (0.45, 80), (0.70, 160), (0.90, 400)],
    rides={"Bicycle": (32, 250), "Kapcai": (48, 1500)},
    spawn_every=[26, 22, 17, 15, 13, 11, 10], burst=[2, 3, 3, 4, 4, 5, 6],
    peat=[.15, .20, .25, .30, .35, .40, .45],
    day_len=240,
)

PROPOSED = copy.deepcopy(BASE)
PROPOSED.update(
    name="PROPOSED",
    FireReward=12, PeatReward=20, run_bonus=(100, 60, 25),
    TrackCostGrowth=1.45,
    hoses=[(1.00, 1.0, 0), (1.15, 1.0, 300), (1.30, 1.0, 900), (1.45, 1.0, 2200), (1.60, 1.5, 5000), (1.80, 1.5, 10000)],
    masks=[(0.25, 30), (0.45, 80), (0.70, 140), (0.90, 400)],
    rides={"Bicycle": (32, 200), "Kapcai": (48, 1200)},
)

HAZE_SLOW = [0, 0, 3, 5, 7]
DAY_BAND = [1, 2, 2, 3, 3, 4, 4]       # typical API band (0-based) on each day of a decently played run
RADIUS = [320, 360, 420, 520, 520, 520, 520]
SPREAD_MUL = [1.0, 1.15, 1.15, 1.15, 1.15, 1.15, 1.15]
CATCH = 0.92
RUN_SECONDS = 20 + 7 * (240 + 14) + 30


def cost(cfg, tid, lvl):
    """cost to go lvl -> lvl+1 (mirrors Config.TrackCost)"""
    base = cfg["tracks"][tid][2]
    return math.floor(base * cfg["TrackCostGrowth"] ** (lvl - 1) / 5 + 0.5) * 5


def tv(cfg, tid, lvl):
    mn, mx, _ = cfg["tracks"][tid]
    return mn + (mx - mn) * (lvl - 1) / 9


class Player:
    def __init__(self, coin_mul=1, truck=False, godspeed=False, inf_tank=False, boost=False):
        self.coins = 0
        self.lv = {k: 1 for k in BASE["tracks"]}
        self.hose = 1
        self.mask = 0
        self.rides = set()
        self.coin_mul = coin_mul
        self.truck = truck
        self.godspeed = godspeed
        self.inf_tank = inf_tank
        self.boost = 1.25 if boost else 1.0
        self.log = []          # (label, run, day, coins_left, price)
        self.earned_total = 0

    def stats(self, cfg):
        hose = cfg["hoses"][self.hose - 1]
        resist_l = tv(cfg, "Lungs", self.lv["Lungs"])
        mres = cfg["masks"][self.mask - 1][0] if self.mask else 0
        resist = 1 - (1 - resist_l) * (1 - mres)
        walk = tv(cfg, "Speed", self.lv["Speed"])
        if self.godspeed:
            walk = min(walk * 1.5, 40)
        return dict(
            walk=walk * self.boost,
            power=24 * tv(cfg, "Pressure", self.lv["Pressure"]) * hose[0] * self.boost,
            tank=tv(cfg, "Tank", self.lv["Tank"]) * hose[1],
            rng=tv(cfg, "Range", self.lv["Range"]),
            refill=tv(cfg, "Refill", self.lv["Refill"]),
            resist=resist,
            noslow=self.godspeed or self.mask == 4,
            peatsoak=cfg["peatSoak"][self.hose - 1],
        )

    def capacity(self, cfg, day):
        """fires per day this player can put out if fires are plentiful"""
        s = self.stats(cfg)
        D = 320 * (RADIUS[day] / 320) ** 0.5
        pp = cfg["peat"][day]
        slow = 0 if s["noslow"] else HAZE_SLOW[DAY_BAND[day]] * (1 - s["resist"])
        walk = max(8, s["walk"] - slow)
        if self.truck:
            # truck: 40 u/s, 80 dmg/s within 30 studs, 45 s of water, 20 s refill; peat only smoulders
            # -> the owner still hops off and soaks peat on foot (+2.5 s soak, +2 s on/off)
            t_truck = max(40, D - 30) / 40 + 84 / 80 + 0.5
            t = t_truck + pp * (2.5 + 2.0)
            return cfg["day_len"] / t
        return cfg["day_len"] / self.foot_time(cfg, s, D, pp, walk)

    def foot_time(self, cfg, s, D, pp, walk):
        speed, mount = walk, 0.0
        for ride in ("Kapcai", "Bicycle"):
            if ride in self.rides:
                rs = cfg["rides"][ride][0]
                if D / rs + 2.0 < D / walk:
                    speed, mount = rs, 2.0
                break
        travel = max(60, D - 0.6 * (s["rng"] - 40)) / speed + mount
        spray = 84 / s["power"]
        soak = (2.5 / s["peatsoak"]) * pp
        water = (spray + soak) * 9
        trips = 0 if self.inf_tank else water / s["tank"]
        refill = trips * (60 / walk + 3.0 / s["refill"])
        return travel + spray + soak + refill


def fires_spawned(cfg, day):
    return (cfg["burst"][day] + cfg["day_len"] / cfg["spawn_every"][day]) * SPREAD_MUL[day]


def coins_per_fire(cfg, day):
    p = cfg["peat"][day]
    return (1 - p) * cfg["FireReward"] + p * cfg["PeatReward"]


# --------------------------------------------------------------------------- shopping
def next_items(cfg, p, policy):
    items = []
    for tid in p.lv:
        if p.lv[tid] < 10:
            items.append((cost(cfg, tid, p.lv[tid]), f"{tid} Lv{p.lv[tid]+1}", ("track", tid)))
    if p.hose < 6:
        items.append((cfg["hoses"][p.hose][2], f"Hose{p.hose+1}", ("hose", None)))
    if p.mask < 3:
        items.append((cfg["masks"][2][1], "N95", ("mask", 3)))
    elif p.mask < 4:
        items.append((cfg["masks"][3][1], "Respirator", ("mask", 4)))
    if "Bicycle" not in p.rides:
        items.append((cfg["rides"]["Bicycle"][1], "Bicycle", ("ride", "Bicycle")))
    elif "Kapcai" not in p.rides:
        items.append((cfg["rides"]["Kapcai"][1], "Kapcai", ("ride", "Kapcai")))
    if policy == "greedy":
        items.sort(key=lambda x: x[0])
        return items
    # "guided": N95 -> Bicycle -> Kapcai first (the milestones the game wants players to hit),
    # then the item with the best capacity gain per coin (an efficient player)
    base_cap = sum(p.capacity(cfg, d) for d in range(7))

    def score(it):
        c, label, (kind, arg) = it
        q = copy.deepcopy(p)
        apply_item(q, kind, arg)
        gain = sum(q.capacity(cfg, d) for d in range(7)) - base_cap
        return max(gain, 0.0005) / c
    items.sort(key=score, reverse=True)
    for goal in ("Kapcai", "Bicycle", "N95"):
        g = [it for it in items if it[1] == goal]
        if g:
            items.remove(g[0])
            items.insert(0, g[0])
    return items


def apply_item(p, kind, arg):
    if kind == "track":
        p.lv[arg] += 1
    elif kind == "hose":
        p.hose += 1
    elif kind == "mask":
        p.mask = arg
    else:
        p.rides.add(arg)


def buy_all(cfg, p, run, day, policy):
    while True:
        items = next_items(cfg, p, policy)
        if not items:
            return
        c, label, (kind, arg) = items[0]
        if p.coins < c:
            return
        p.coins -= c
        apply_item(p, kind, arg)
        p.log.append((label, run, day + 1, p.coins, c))


# --------------------------------------------------------------------------- simulation
def run_bonus(cfg, avg_catch):
    return cfg["run_bonus"][0] if avg_catch >= 0.85 else (cfg["run_bonus"][1] if avg_catch >= 0.6 else cfg["run_bonus"][2])


def simulate_run(cfg, players, run, policy, coop_scale):
    n = len(players)
    mult = 1 + coop_scale * (n - 1)
    rows, catches = [], []
    for day in range(7):
        caps = [pl.capacity(cfg, day) for pl in players]
        spawned = fires_spawned(cfg, day) * mult
        total = sum(caps)
        out_total = min(total, CATCH * spawned)
        catches.append(out_total / spawned)
        for pl, c in zip(players, caps):
            out = out_total * c / total
            earned = out * coins_per_fire(cfg, day) * pl.coin_mul
            pl.coins += earned
            pl.earned_total += earned
            if pl is players[0]:
                rows.append(dict(day=day + 1, spawned=spawned, cap=c, out=out, earned=earned, share=c / total))
        for pl in players:
            buy_all(cfg, pl, run, day, policy)
        rows[-1]["coins_after_buy"] = players[0].coins
    b = run_bonus(cfg, sum(catches) / 7)
    for pl in players:
        pl.coins += b * pl.coin_mul
        pl.earned_total += b * pl.coin_mul
        buy_all(cfg, pl, run, 6, policy)
    return dict(run=run, rows=rows, bonus=b, catch=sum(catches) / 7, earned=players[0].earned_total)


def fmt_when(idx):
    if idx is None:
        return "never (60 runs)"
    return f"run {(idx - 1) // 7 + 1} day {(idx - 1) % 7 + 1}"


def first_idx(p, label):
    for lab, run, day, _, _ in p.log:
        if lab == label:
            return (run - 1) * 7 + day
    return None


def milestones(cfg, make_players, policy, coop_scale, runs=60):
    pls = make_players()
    p = pls[0]
    hist = [simulate_run(cfg, pls, r, policy, coop_scale) for r in range(1, runs + 1)]
    out = {}
    fb = next((x for x in p.log if x[4] >= 60), None)
    out["First upgrade costing >=60c"] = f"{fb[0]} @ {fmt_when((fb[1]-1)*7+fb[2])}" if fb else "none"
    for lab in ["N95", "Bicycle", "Kapcai", "Hose2", "Hose3", "Hose4", "Hose5", "Hose6"]:
        out[lab] = fmt_when(first_idx(p, lab))
    t10 = [(r - 1) * 7 + d for lab, r, d, _, _ in p.log if lab.endswith("Lv10")]
    out["All 6 tracks Lv10"] = fmt_when(max(t10)) if len(t10) == 6 else f"not in {runs} runs"
    complete = all(v == 10 for v in p.lv.values()) and p.hose == 6 and p.mask == 4 and len(p.rides) == 2
    idx = max((r - 1) * 7 + d for _, r, d, _, _ in p.log) if complete else None
    out["ALL-MAX"] = fmt_when(idx) + (f" (~{((idx-1)//7+1)*RUN_SECONDS/3600:.1f} h)" if idx else "")
    out["_hist"] = hist
    return out


def solo(): return [Player()]
def solo_2x(): return [Player(coin_mul=2)]
def solo_truck(): return [Player(truck=True)]
def duo(): return [Player(), Player()]
def quad(): return [Player(), Player(), Player(), Player()]
def free_plus_truck(): return [Player(), Player(truck=True)]


def day_table(cfg, policy, runs=3):
    pls = solo()
    L = ["| Run | Day | Spawned | Capacity | Put out | Coins earned | Banked after buying |", "|---|---|---|---|---|---|---|"]
    for r in range(1, runs + 1):
        h = simulate_run(cfg, pls, r, policy, 0)
        for x in h["rows"]:
            L.append(f"| {r} | {x['day']} | {x['spawned']:.1f} | {x['cap']:.1f} | {x['out']:.1f} | {x['earned']:.0f} | {x['coins_after_buy']:.0f} |")
        p = pls[0]
        L.append(f"| {r} | end | | | | +{h['bonus']} bonus | track Lv {list(p.lv.values())}, hose {p.hose}, mask {p.mask}, rides {sorted(p.rides)}, banked {p.coins:.0f} |")
    return "\n".join(L)


def total_cost(cfg):
    t = sum(cost(cfg, tid, l) for tid in cfg["tracks"] for l in range(1, 10))
    t += sum(h[2] for h in cfg["hoses"]) + cfg["masks"][2][1] + cfg["masks"][3][1]
    t += sum(v[1] for v in cfg["rides"].values())
    return t


def report(cfg, policy, coop_scale, quiet=False):
    print("=" * 90)
    print(f"{cfg['name']} | policy={policy} | co-op spawn scale={coop_scale} | all-max cost {total_cost(cfg):,} coins | run {RUN_SECONDS/60:.1f} min")
    print("=" * 90)
    if not quiet:
        print(day_table(cfg, policy))
        print()
    scen = [("Solo free", solo), ("Solo 2x", solo_2x), ("Solo+Truck", solo_truck),
            ("2 free", duo), ("4 free", quad), ("Free w/ Truck owner", free_plus_truck)]
    res = {n: milestones(cfg, mk, policy, coop_scale) for n, mk in scen}
    keys = [k for k in res["Solo free"] if not k.startswith("_")]
    print("| Milestone | " + " | ".join(n for n, _ in scen) + " |")
    print("|---|" + "---|" * len(scen))
    for k in keys:
        print(f"| {k} | " + " | ".join(res[n][k] for n, _ in scen) + " |")
    print()
    for n in ("Solo free", "Solo 2x", "4 free"):
        e = [h["earned"] for h in res[n]["_hist"]]
        per = [round(e[0])] + [round(e[i] - e[i - 1]) for i in range(1, 12)]
        print(f"{n}: coins earned per run, runs 1-12: {per}")
    print("Base capacity D1..D7:", [round(Player().capacity(cfg, d), 1) for d in range(7)],
          "| spawned:", [round(fires_spawned(cfg, d), 1) for d in range(7)])
    print("Truck capacity D1..D7:", [round(Player(truck=True).capacity(cfg, d), 1) for d in range(7)])
    h = res["Free w/ Truck owner"]["_hist"]
    for r in (1, 5, 15):
        print(f"  free player's share of fires next to a Truck owner, run {r}:", [round(x['share'], 2) for x in h[r - 1]['rows']])
    return res


if __name__ == "__main__":
    q = "--quiet" in sys.argv
    for pol in ("greedy", "guided"):
        report(BASE, pol, 0, q)
    for pol in ("greedy", "guided"):
        report(PROPOSED, pol, 0, q)
    report(PROPOSED, "guided", 0.5, q)
