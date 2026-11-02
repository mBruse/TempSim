"""Generate patent-style technical drawings for TempSim (1D transient heat conduction).

Every figure is rendered in two variants:
  * numbered  - classic patent style: reference numerals with curved lead lines
  * labelled  - direct labelling: plain-text callouts with straight leader lines
Each variant is saved as a vector PDF and a PNG, and all of them are collected
in one summary PDF (cover, index with file names, one page per drawing).

Run:  python3 make_drawings.py   (requires matplotlib)
"""
import math
import os
from datetime import date

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.patches import (Rectangle, Circle, FancyArrowPatch, FancyBboxPatch,
                                Polygon, Ellipse, Arc)

OUT = os.path.dirname(os.path.abspath(__file__))
LW = 1.3          # object lines
LW_THIN = 0.7     # lead lines, hatching, dimension lines
FS_NUM = 11       # reference numeral font size
FS_LBL = 8.5      # direct label font size
plt.rcParams.update({"font.family": "DejaVu Sans", "hatch.linewidth": 0.6,
                     "pdf.fonttype": 42})


# --------------------------------------------------------------------------- helpers
def rect(ax, x, y, w, h, hatch=None, lw=LW, fc="white", z=2, ls="-"):
    ax.add_patch(Rectangle((x, y), w, h, fill=True, fc=fc, ec="black", lw=lw,
                           hatch=hatch, zorder=z, ls=ls))


def line(ax, xs, ys, lw=LW, ls="-", z=3):
    ax.plot(xs, ys, color="black", lw=lw, ls=ls, zorder=z, solid_capstyle="butt")


def arrow(ax, p, q, lw=LW, style="-|>", ms=12, z=4, rad=0.0):
    ax.add_patch(FancyArrowPatch(p, q, arrowstyle=style, mutation_scale=ms, lw=lw,
                                 color="black", zorder=z,
                                 connectionstyle=f"arc3,rad={rad}"))


def dim(ax, p, q, text, off=(0, 0.25), fs=10):
    """Dimension line with arrowheads on both ends and a text above."""
    arrow(ax, p, q, lw=LW_THIN, style="<|-|>", ms=8)
    ax.text((p[0] + q[0]) / 2 + off[0], (p[1] + q[1]) / 2 + off[1], text,
            ha="center", va="center", fontsize=fs, style="italic", zorder=6,
            bbox=dict(fc="white", ec="none", pad=0.5))


def callout(ax, mode, num, text, target, pos, rad=0.25, arrowhead=False):
    """Numbered: numeral + curved lead line.  Labelled: text + straight leader with dot."""
    tx, ty = target
    px, py = pos
    if mode == "numbered":
        ax.text(px, py, str(num), ha="center", va="center", fontsize=FS_NUM, zorder=8,
                bbox=dict(fc="white", ec="none", pad=0.6))
        style = "-|>" if arrowhead else "-"
        ax.add_patch(FancyArrowPatch((px, py), (tx, ty), arrowstyle=style,
                                     mutation_scale=9, lw=LW_THIN, color="black",
                                     shrinkA=7, shrinkB=0, zorder=7,
                                     connectionstyle=f"arc3,rad={rad}"))
    else:
        dx, dy = tx - px, ty - py
        if abs(dx) >= abs(dy):
            ha, va = ("right" if dx > 0 else "left"), "center"
        else:
            ha, va = "center", ("top" if dy > 0 else "bottom")
        ax.text(px, py, text, ha=ha, va=va, fontsize=FS_LBL, zorder=8,
                bbox=dict(fc="white", ec="none", pad=0.8), linespacing=1.1)
        ax.add_patch(FancyArrowPatch((px, py), (tx, ty), arrowstyle="-", lw=LW_THIN,
                                     color="black", shrinkA=4, shrinkB=0, zorder=7))
        if not arrowhead:
            ax.add_patch(Circle((tx, ty), 0.06, color="black", zorder=7))
        else:
            arrow(ax, ((px + tx * 3) / 4, (py + ty * 3) / 4), (tx, ty), lw=LW_THIN, ms=8)


def box_label(ax, mode, num, text, x, y, w, h, lead=(0.35, 0.35), fs=None, rounded=False):
    """Box whose meaning is either written inside (labelled) or given by a numeral (numbered)."""
    if rounded:
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0,rounding_size=%g" % (h / 2),
                                    fc="white", ec="black", lw=LW, zorder=2))
    else:
        rect(ax, x, y, w, h)
    if mode == "labelled":
        ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fs or FS_LBL,
                zorder=6, linespacing=1.15)
    else:
        callout(ax, mode, num, text, (x + w - 0.05, y + h - 0.05),
                (x + w + lead[0], y + h + lead[1]), rad=-0.3)


def finish(ax, xlim, ylim):
    ax.set_xlim(*xlim)
    ax.set_ylim(*ylim)
    ax.set_aspect("equal")
    ax.axis("off")


# --------------------------------------------------------------------------- FIG. 1
def fig1(ax, mode):
    """Wall layer discretised into six nodes (cross-section)."""
    x0, x1, yb, yt, yc = 2, 10, 2.5, 5.5, 4.0
    rect(ax, x0, yb, x1 - x0, yt - yb, hatch="///", z=1)
    xs = [x0 + 1.6 * i for i in range(6)]
    line(ax, [x0 - 0.3, x1 + 0.3], [yc, yc], lw=LW_THIN, ls=(0, (8, 2, 1, 2)))
    for i, x in enumerate(xs):
        ax.add_patch(Circle((x, yc), 0.2, fc="white", ec="black", lw=LW, zorder=5))
        ax.text(x, yc, str(i), ha="center", va="center", fontsize=7, zorder=6)
    # time-varying source on the left (wavy arrow)
    import numpy as np
    xx = np.linspace(-0.2, 1.5, 200)
    line(ax, xx, yc + 0.25 * np.sin((xx + 0.2) * 2 * math.pi / 0.57), lw=LW)
    arrow(ax, (1.5, yc), (1.95, yc), ms=12)
    # fixed boundary on the right (earth symbol)
    line(ax, [x1 + 0.3, x1 + 0.3], [yb, yt], lw=2.2)
    for k in range(7):
        y = yb + 0.15 + k * 0.45
        line(ax, [x1 + 0.3, x1 + 0.7], [y, y + 0.35], lw=LW_THIN)
    # dimensions
    for x in (xs[2], xs[3]):
        line(ax, [x, x], [yb - 0.1, 1.35], lw=LW_THIN)
    dim(ax, (xs[2], 1.6), (xs[3], 1.6), "Δx", off=(0, -0.3))
    for x in (x0, x1):
        line(ax, [x, x], [yt + 0.1, 6.85], lw=LW_THIN)
    dim(ax, (x0, 6.6), (x1, 6.6), "L")
    C = [(10, "wall layer", (3.2, 5.1), (3.0, 8.1)),
         (12, "first (exposed) surface", (2.0, 3.0), (0.9, 1.0)),
         (14, "second surface", (10.0, 5.1), (11.5, 7.6)),
         (20, "boundary node i = 0", (2.12, 4.15), (0.4, 6.2)),
         (22, "interior node i = 1…4", (3.6, 3.8), (3.4, 0.4)),
         (24, "boundary node i = 5", (9.88, 3.85), (12.3, 5.2)),
         (30, "time-varying\ntemperature source T₀(t)", (0.6, 4.25), (-0.4, 2.2)),
         (32, "constant-temperature\nboundary T₅", (10.6, 3.2), (12.3, 1.8)),
         (40, "node spacing", (6.5, 1.6), (7.8, 0.5)),
         (42, "wall thickness", (8.4, 6.6), (8.6, 8.1))]
    for n, t, tg, p in C:
        callout(ax, mode, n, t, tg, p)
    finish(ax, (-1.6, 13.6), (-0.3, 8.7))
    return C


# --------------------------------------------------------------------------- FIG. 2
def fig2(ax, mode):
    """Laboratory test rig for validating the simulation (side elevation, partly in section)."""
    import numpy as np
    rect(ax, 0, 0, 14, 0.6)                                   # base plate
    rect(ax, 1.6, 0.6, 0.8, 1.8); rect(ax, 11.6, 0.6, 0.8, 1.8)   # supports
    rect(ax, 0.8, 2.4, 2.4, 3.2)                              # heater block
    zz_x = np.linspace(1.2, 2.8, 13)
    for yy in (3.0, 4.0, 5.0):                                # heating element (zigzag)
        line(ax, zz_x, yy + 0.18 * np.array([(-1) ** k for k in range(13)]), lw=LW_THIN)
    rect(ax, 3.2, 3.4, 7.6, 1.2, z=2)                         # specimen rod
    line(ax, [2.9, 11.1], [4.0, 4.0], lw=LW_THIN, ls=(0, (8, 2, 1, 2)))
    rect(ax, 3.2, 2.8, 7.6, 0.6, hatch="xxx")                 # insulation (section)
    rect(ax, 3.2, 4.6, 7.6, 0.6, hatch="xxx")
    rect(ax, 10.8, 2.4, 2.4, 3.2)                             # cooling block
    for yy in (3.0, 5.0):                                     # coolant channels (hidden)
        line(ax, [11.0, 13.0], [yy, yy], lw=LW_THIN, ls=(0, (4, 2)))
    rect(ax, 13.2, 4.8, 0.9, 0.35); rect(ax, 13.2, 2.85, 0.9, 0.35)   # pipes
    arrow(ax, (15.0, 4.98), (14.15, 4.98), ms=10)
    arrow(ax, (14.15, 3.03), (15.0, 3.03), ms=10)
    # thermocouples + cables
    px = [3.5 + 1.4 * i for i in range(6)]
    for i, x in enumerate(px):
        rect(ax, x - 0.07, 4.25, 0.14, 2.45, z=4)
        ax.add_patch(Circle((x, 4.2), 0.11, color="black", zorder=5))
        yc = 7.4 + 0.22 * (5 - i)
        line(ax, [x, x, 10.8], [6.7, yc, yc], lw=LW_THIN)
    # data logger
    rect(ax, 10.8, 7.2, 4.6, 3.0)
    rect(ax, 11.2, 8.4, 3.0, 1.5)
    xx = np.linspace(11.4, 14.0, 60)
    line(ax, xx, 9.1 + 0.35 * np.sin((xx - 11.4) * 2.3), lw=LW_THIN)
    for k in range(3):
        ax.add_patch(Circle((11.5 + 0.6 * k, 7.7), 0.18, fc="white", ec="black", lw=LW, zorder=3))
    rect(ax, 14.5, 7.5, 0.6, 2.4)                             # terminal strip
    # temperature controller
    rect(ax, 0.0, 7.4, 3.4, 2.2)
    rect(ax, 0.3, 8.5, 1.8, 0.8)
    ax.text(1.2, 8.9, "20.0", ha="center", va="center", fontsize=8, family="monospace")
    ax.add_patch(Circle((2.8, 8.0), 0.3, fc="white", ec="black", lw=LW, zorder=3))
    line(ax, [2.8, 2.8], [8.0, 8.3], lw=LW)
    line(ax, [1.6, 1.6], [7.4, 5.6], lw=LW_THIN)
    line(ax, [2.4, 2.4], [7.4, 5.6], lw=LW_THIN)
    lab = mode == "labelled"
    C = [(100, "base plate", (7.0, 0.3), (7.5, -1.1)),
         (102, "support", (2.0, 1.4), (0.6, -0.8)),
         (110, "heater block", (1.0, 5.3), (-1.2, 6.2)),
         (112, "heating element", (2.4, 3.15), (-1.2, 3.6)),
         (120, "specimen rod", (4.4, 3.7), (4.0, -0.9)),
         (122, "thermal insulation", (9.4, 3.1), (10.0, 1.2)),
         (130, "thermocouple", (4.97, 6.0) if lab else (6.3, 6.0), (4.3, 11.0) if lab else (5.4, 7.6)),
         (132, "measuring junction", (7.7, 4.2), (6.8, 1.8)),
         (134, "signal cable", (9.6, 8.5), (8.4, 10.6)),
         (140, "data logger", (15.4, 7.8), (16.4, 7.0)),
         (142, "display", (13.6, 9.9), (14.4, 11.0)),
         (150, "cooling block", (12.9, 2.6), (15.0, 1.0)),
         (152, "coolant inlet", (14.1, 5.15), (15.4, 6.2)),
         (154, "coolant outlet", (14.1, 2.85), (15.6, 2.3)),
         (160, "temperature controller", (0.2, 9.4), (-1.0, 10.4)),
         (162, "power lines", (1.6, 6.5), (0.4, 6.6) if lab else (-1.2, 7.2))]
    for n, t, tg, p in C:
        callout(ax, mode, n, t, tg, p)
    finish(ax, (-2.2, 17.8), (-1.6, 11.6))
    return C


# --------------------------------------------------------------------------- FIG. 3
def fig3(ax, mode):
    """Block diagram of the simulation system."""
    ax.add_patch(Rectangle((0, 0), 14, 9, fill=False, ec="black", lw=LW, ls=(0, (6, 3)), zorder=1))
    def blk(num, text, x, y, w, h, lead=(0.35, 0.35)):
        box_label(ax, mode, num, text, x, y, w, h, lead=lead)
    ax.add_patch(Rectangle((4.3, 2.9), 5.4, 5.1, fill=False, ec="black", lw=LW, zorder=1))
    blk(210, "Input unit\n(α, T_init, Δx,\nΔt, n)", 0.5, 5.6, 3.0, 1.8)
    blk(212, "Sensor\ninterface", 0.5, 3.0, 3.0, 1.4)
    blk(222, "Boundary-condition\nmodule", 4.7, 6.3, 3.8, 1.2, lead=(0.5, 0.25))
    blk(224, "Explicit finite-\ndifference solver", 4.7, 4.7, 3.8, 1.2, lead=(0.5, 0.25))
    blk(226, "Time-step\ncontroller", 4.7, 3.2, 3.8, 1.0, lead=(0.5, 0.25))
    blk(230, "Memory\nT_old[i], T_new[i]", 4.7, 0.6, 3.8, 1.6)
    blk(240, "Display unit\n(temperature-\ntime chart)", 10.6, 5.6, 2.9, 1.8, lead=(-0.3, 0.45))
    blk(242, "Data export\n(file / log)", 10.6, 3.0, 2.9, 1.4, lead=(-0.3, 0.45))
    blk(250, "Temperature\nsensors", -3.6, 3.0, 2.6, 1.4, lead=(0.3, 0.45))
    arrow(ax, (-1.0, 3.7), (0.5, 3.7))
    arrow(ax, (3.5, 6.5), (4.3, 6.5)); arrow(ax, (3.5, 3.7), (4.3, 3.7))
    arrow(ax, (9.7, 6.5), (10.6, 6.5)); arrow(ax, (9.7, 3.7), (10.6, 3.7))
    arrow(ax, (6.6, 6.3), (6.6, 5.9)); arrow(ax, (6.6, 4.2), (6.6, 4.7))
    arrow(ax, (5.6, 2.2), (5.6, 2.9), style="<|-|>"); arrow(ax, (7.6, 2.2), (7.6, 2.9), style="<|-|>")
    C = [(200, "simulation system", (13.9, 8.5), (15.2, 9.5)),
         (220, "processor", (9.6, 7.9), (10.3, 8.6))]
    for n, t, tg, p in C:
        callout(ax, mode, n, t, tg, p)
    if mode == "numbered":
        lst = [(210, "input unit"), (212, "sensor interface"), (222, "boundary-condition module"),
               (224, "explicit finite-difference solver"), (226, "time-step controller"),
               (230, "memory (temperature arrays)"), (240, "display unit"), (242, "data export"),
               (250, "temperature sensors")]
        C = C + [(n, t, None, None) for n, t in lst]
    finish(ax, (-4.2, 17.2), (-0.6, 10.2))
    return sorted(C)


# --------------------------------------------------------------------------- FIG. 4
def fig4(ax, mode):
    """Flow chart of the simulation method."""
    steps = [("S300", "Start", "term"),
             ("S302", "Read parameters\nα, T_init, Δx, Δt, n", "io"),
             ("S304", "Initialise all nodes\nT_i = T_init, t = 0", "proc"),
             ("S306", "Advance time\nt = t + Δt", "proc"),
             ("S308", "Set boundary node\nT₀ = T_init + 5·cos(π t / 3600 s)", "proc"),
             ("S310", "Update interior nodes i = 1…4\nT_i' = T_i + αΔt/Δx²·(T_{i-1} − 2T_i + T_{i+1})", "proc"),
             ("S312", "Hold far boundary\nT₅ = T_init", "proc"),
             ("S314", "Output T_i(t) to chart", "io"),
             ("S316", "Copy T' → T", "proc"),
             ("S318", "Step < n ?", "dec"),
             ("S320", "End", "term")]
    W, H, gap = 6.6, 1.0, 0.55
    cx = 5.0
    ys = []
    y = 0
    for i, (num, txt, kind) in enumerate(steps):
        h = 1.4 if kind == "dec" else H
        ys.append((y, h))
        y -= h + gap
    for i, (num, txt, kind) in enumerate(steps):
        yt, h = ys[i]
        yb = yt - h
        if kind == "term":
            ax.add_patch(FancyBboxPatch((cx - 1.6, yb), 3.2, h, boxstyle="round,pad=0,rounding_size=0.5",
                                        fc="white", ec="black", lw=LW, zorder=2))
        elif kind == "io":
            sk = 0.35
            ax.add_patch(Polygon([(cx - W / 2 + sk, yt), (cx + W / 2 + sk, yt), (cx + W / 2 - sk, yb),
                                  (cx - W / 2 - sk, yb)], fc="white", ec="black", lw=LW, zorder=2))
        elif kind == "dec":
            ax.add_patch(Polygon([(cx, yt), (cx + 2.4, yb + h / 2), (cx, yb), (cx - 2.4, yb + h / 2)],
                                 fc="white", ec="black", lw=LW, zorder=2))
        else:
            rect(ax, cx - W / 2, yb, W, h)
        if mode == "labelled":
            ax.text(cx, yb + h / 2, txt, ha="center", va="center", fontsize=7.6, zorder=6, linespacing=1.2)
            ax.text(cx + W / 2 + 0.5, yb + h / 2, num, ha="left", va="center", fontsize=8, zorder=6)
        else:
            ax.text(cx, yb + h / 2, num, ha="center", va="center", fontsize=FS_NUM, zorder=6)
        if i < len(steps) - 1 and kind != "dec":
            arrow(ax, (cx, yb), (cx, yb - gap))
    # decision branches
    yt, h = ys[9]
    ymid = yt - h / 2
    arrow(ax, (cx, yt - h), (cx, yt - h - gap))
    ax.text(cx + 0.15, yt - h - 0.25, "no", fontsize=8, ha="left", va="center")
    y306 = ys[3][0] - ys[3][1] / 2
    line(ax, [cx - 2.4, -0.6, -0.6], [ymid, ymid, y306])
    arrow(ax, (-0.6, y306), (cx - W / 2, y306))
    ax.text(cx - 2.6, ymid + 0.25, "yes", fontsize=8, ha="right", va="center")
    finish(ax, (-1.5, 11.8), (y + gap - 0.4, 0.4))
    return [(int(s[0][1:]), s[1].replace("\n", " "), None, None) for s in steps]


# --------------------------------------------------------------------------- FIG. 5
def simulate():
    alpha = 0.5 / 1e6       # m²/s  (0.5 mm²/s)
    dx, dt, n, Tinit = 0.01, 60.0, 300, 20.0
    T = [Tinit] * 6
    t = 0.0
    hist = [[Tinit] for _ in range(6)]
    times = [0.0]
    for _ in range(n):
        t += dt
        Tn = T[:]
        Tn[0] = math.cos(math.pi * t / 3600) * 5 + Tinit
        for i in range(1, 5):
            a = alpha * (T[i - 1] - T[i]) / dx
            b = alpha * (T[i] - T[i + 1]) / dx
            Tn[i] = (a - b) / dx * dt + T[i]
        Tn[5] = Tinit
        T = Tn
        times.append(t / 60)
        for i in range(6):
            hist[i].append(T[i])
    return times, hist


def fig5(ax, mode):
    """Temperature–time diagram produced by the method (curves per node)."""
    times, hist = simulate()
    sx, sy, y0 = 12.0 / 300, 0.75, 13.0     # scale: 300 min -> 12 units, °C -> 0.75 unit
    T = lambda v: (v - y0) * sy
    arrow(ax, (0, 0), (13.0, 0), ms=12)
    arrow(ax, (0, 0), (0, T(27.5)), ms=12)
    styles = ["-", (0, (6, 2)), (0, (1.5, 1.5)), (0, (6, 2, 1.5, 2)), (0, (10, 3)), "-"]
    widths = [1.6, 1.2, 1.2, 1.2, 1.2, 0.8]
    for i in range(6):
        ax.plot([t * sx for t in times], [T(v) for v in hist[i]], color="black",
                ls=styles[i], lw=widths[i], zorder=3)
    for v in (15, 20, 25):
        line(ax, [-0.12, 0], [T(v), T(v)], lw=LW_THIN)
        ax.text(-0.25, T(v), f"{v}", ha="right", va="center", fontsize=8)
    for m in (0, 60, 120, 180, 240, 300):
        line(ax, [m * sx, m * sx], [-0.12, 0], lw=LW_THIN)
        ax.text(m * sx, -0.3, f"{m}", ha="center", va="top", fontsize=8)
    ax.text(13.0, -0.75, "t [min]", ha="right", va="top", fontsize=9, style="italic")
    ax.text(-0.25, T(27.5), "T [°C]", ha="right", va="top", fontsize=9, style="italic")
    def pt(i, m):
        k = int(m)
        return (times[k] * sx, T(hist[i][k]))
    names = ["node 0 – excited surface", "node 1", "node 2", "node 3", "node 4",
             "node 5 – constant boundary"]
    ends = sorted(range(6), key=lambda i: hist[i][-1])
    C = [(500, "time axis", (11.0, 0), (11.6, -1.3)),
         (502, "temperature axis", (0, T(23)), (-1.7, T(23.8))),
         (520, "temperature amplitude ±5 K", (120 * sx, T(15.0)), (6.6, T(13.7)))]
    for rank, i in enumerate(ends):
        C.append((510 + i, names[i], (12.0, T(hist[i][-1])), (13.3, T(14.6 + rank * 1.75))))
    C.sort()
    for n, t, tg, p in C:
        callout(ax, mode, n, t, tg, p, rad=0.0 if 510 <= n <= 515 else 0.2)
    # amplitude marker
    dim(ax, (120 * sx, T(15.0)), (120 * sx, T(25.0)), "", fs=8)
    finish(ax, (-3.6, 14.4 if mode == 'numbered' else 18.4), (-2.0, T(28.3)))
    return C


# --------------------------------------------------------------------------- FIG. 6
def fig6(ax, mode):
    """Detail view of one control volume and the energy balance."""
    yb, yt = 0.0, 4.0
    rect(ax, -1, yb, 12, yt - yb, hatch="//", z=1)
    rect(ax, 3.0, yb, 4.0, yt - yb, z=2)                      # control volume, un-hatched
    line(ax, [3.0, 3.0], [yb - 0.6, yt + 0.6], lw=LW, ls=(0, (6, 3)))
    line(ax, [7.0, 7.0], [yb - 0.6, yt + 0.6], lw=LW, ls=(0, (6, 3)))
    # break lines on both ends
    for xe in (-1.0, 11.0):
        ax.add_patch(Rectangle((xe - 0.25, yb - 0.1), 0.5, yt - yb + 0.2, fc="white", ec="none", zorder=3))
        import numpy as np
        yy = np.linspace(yb - 0.1, yt + 0.1, 50)
        line(ax, xe + 0.15 * np.sin(yy * 3), yy, lw=LW_THIN, z=4)
    for x, lab in ((1.0, "i−1"), (5.0, "i"), (9.0, "i+1")):
        ax.add_patch(Circle((x, 2.0), 0.24, fc="white", ec="black", lw=LW, zorder=5))
        ax.text(x, 1.45, lab, ha="center", va="top", fontsize=8.5, style="italic", zorder=6,
                bbox=dict(fc="white", ec="none", pad=0.3))
    arrow(ax, (1.8, 2.9), (4.2, 2.9), lw=2.0, ms=16)
    arrow(ax, (5.8, 2.9), (8.2, 2.9), lw=2.0, ms=16)
    ax.text(2.4, 3.3, "q̇ᵢₙ", fontsize=11, ha="center", zorder=6, bbox=dict(fc="white", ec="none", pad=0.3))
    ax.text(7.6, 3.3, "q̇ₒᵤₜ", fontsize=11, ha="center", zorder=6, bbox=dict(fc="white", ec="none", pad=0.3))
    ax.add_patch(Arc((5.0, 2.0), 1.3, 1.3, theta1=200, theta2=520, lw=LW_THIN, zorder=5))
    arrow(ax, (4.55, 1.55), (4.4, 1.75), lw=LW_THIN, ms=7)
    dim(ax, (3.0, -0.9), (7.0, -0.9), "Δx")
    dim(ax, (1.0, 5.0), (5.0, 5.0), "Δx", fs=9); dim(ax, (5.0, 5.0), (9.0, 5.0), "Δx", fs=9)
    for x in (1.0, 9.0):
        line(ax, [x, x], [2.3, 5.2], lw=LW_THIN, ls=(0, (2, 2)))
    line(ax, [5.0, 5.0], [2.3, 5.2], lw=LW_THIN, ls=(0, (2, 2)))
    C = [(600, "control volume", (6.5, 0.4), (7.8, -2.0)),
         (602, "node i", (5.15, 2.18), (6.2, 1.2) if mode == "numbered" else (6.6, 1.5)),
         (604, "neighbour node i−1", (0.85, 1.85), (-0.4, 0.6) if mode == "numbered" else (0.3, -1.6)),
         (606, "neighbour node i+1", (9.15, 1.85), (10.6, -1.0)),
         (610, "incoming heat flux", (2.2, 2.9), (0.8, 6.2)),
         (612, "outgoing heat flux", (7.8, 2.9), (9.2, 6.2)),
         (614, "stored energy ρc·Δx·dT/dt", (5.6, 1.5), (5.4, -2.3) if mode == "numbered" else (4.4, -2.6)),
         (620, "cell face i−½", (3.0, 4.4), (3.6, 6.9)),
         (622, "cell face i+½", (7.0, 4.4), (6.4, 6.9)),
         (630, "adjacent solid material", (10.0, 0.6), (11.6, -1.0) if mode == "numbered" else (12.0, 0.4))]
    for n, t, tg, p in C:
        callout(ax, mode, n, t, tg, p)
    finish(ax, (-2.6, 13.4), (-3.1, 7.5))
    return C


# --------------------------------------------------------------------------- FIG. 7
def fig7(ax, mode):
    """Graphical user interface of the simulation program."""
    import numpy as np
    rect(ax, 0, 0, 14, 9.4)                                   # window
    rect(ax, 0, 8.8, 14, 0.6)                                 # title bar
    for k in range(3):
        rect(ax, 12.2 + 0.55 * k, 8.92, 0.4, 0.36)
    rect(ax, 0.2, 0.2, 4.0, 8.4)                              # parameter panel
    fields = ["T_init", "Δx", "Δt", "n"]
    for k, f in enumerate(fields):
        y = 7.4 - 1.0 * k
        if mode == "labelled":
            ax.text(0.5, y + 0.2, f, fontsize=8, va="center")
        else:
            line(ax, [0.5, 1.4], [y + 0.2, y + 0.2], lw=LW_THIN)
        rect(ax, 1.8, y, 2.0, 0.42)
    y = 3.4
    rect(ax, 1.8, y, 2.0, 0.42)
    ax.add_patch(Polygon([(3.45, y + 0.28), (3.7, y + 0.28), (3.575, y + 0.13)], color="black", zorder=4))
    line(ax, [3.3, 3.3], [y, y + 0.42], lw=LW_THIN)
    if mode == "labelled":
        ax.text(0.5, y + 0.2, "α", fontsize=8, va="center")
    else:
        line(ax, [0.5, 1.4], [y + 0.2, y + 0.2], lw=LW_THIN)
    ax.add_patch(FancyBboxPatch((0.6, 1.9), 3.2, 0.7, boxstyle="round,pad=0,rounding_size=0.12",
                                fc="white", ec="black", lw=LW, zorder=3))
    ax.add_patch(FancyBboxPatch((0.6, 0.8), 3.2, 0.7, boxstyle="round,pad=0,rounding_size=0.12",
                                fc="white", ec="black", lw=LW, zorder=3))
    if mode == "labelled":
        ax.text(2.2, 2.25, "Start", fontsize=8, ha="center", va="center", zorder=4)
        ax.text(2.2, 1.15, "Single step", fontsize=8, ha="center", va="center", zorder=4)
    # tabs + chart
    for k in range(3):
        rect(ax, 4.5 + 1.6 * k, 8.0, 1.5, 0.5, fc="white")
    rect(ax, 4.5, 0.2, 9.3, 7.8)
    arrow(ax, (5.3, 0.9), (13.3, 0.9), lw=LW_THIN, ms=8)
    arrow(ax, (5.3, 0.9), (5.3, 7.5), lw=LW_THIN, ms=8)
    xx = np.linspace(5.3, 13.0, 200)
    for k, (amp, ph, ls) in enumerate([(2.2, 0, "-"), (1.4, 0.5, (0, (5, 2))), (0.8, 1.0, (0, (1.5, 1.5))),
                                       (0.4, 1.5, (0, (6, 2, 1.5, 2))), (0.0, 0, "-")]):
        env = 1 - np.exp(-(xx - 5.3) * (1.5 - 0.25 * k)) if k else 1
        ax.plot(xx, 4.2 + amp * env * np.cos((xx - 5.3) * 0.82 - ph), color="black", ls=ls,
                lw=LW_THIN if k == 4 else 1.0, zorder=4)
    C = [(700, "program window", (0.3, 0.0), (-1.4, -1.2)),
         (702, "title bar", (10.5, 9.1), (10.4, 10.5)),
         (710, "parameter panel", (0.2, 8.0), (-1.4, 9.6)),
         (712, "numeric input fields", (3.8, 7.62), (4.4, 10.5)),
         (714, "diffusivity selector", (3.8, 3.6), (5.4, -1.1) if mode == "numbered" else (6.4, -1.3)),
         (716, "start button", (0.6, 2.3), (-1.4, 3.2)),
         (718, "single-step button", (0.6, 1.1), (-1.4, 1.2)),
         (720, "tab control", (6.85, 8.5), (7.0, 10.5) if mode == "numbered" else (7.4, 9.85)),
         (730, "chart area", (13.8, 6.8), (15.0, 7.6)),
         (732, "node temperature curves", (9.0, 4.2 + 2.2 * math.cos(3.7 * 0.82)), (15.0, 3.0)),
         (734, "time axis", (11.5, 0.9), (12.4, -1.1))]
    for n, t, tg, p in C:
        callout(ax, mode, n, t, tg, p)
    finish(ax, (-2.0, 16.6) if mode == 'numbered' else (-4.4, 19.4), (-1.8, 11.0))
    return C


FIGS = [
    (1, "wall_discretisation", "Wall layer discretised into nodes (cross-section)", fig1, (8.0, 4.8)),
    (2, "test_rig", "Laboratory test rig, side elevation partly in section", fig2, (8.0, 5.0)),
    (3, "block_diagram", "Block diagram of the simulation system", fig3, (8.0, 4.5)),
    (4, "flow_chart", "Flow chart of the simulation method", fig4, (5.6, 8.6)),
    (5, "temperature_diagram", "Temperature–time diagram of the nodes", fig5, (8.0, 4.9)),
    (6, "control_volume", "Detail of one control volume with energy balance", fig6, (8.0, 4.9)),
    (7, "user_interface", "Graphical user interface of the program", fig7, (8.0, 5.6)),
]
MODES = [("numbered", "reference numerals"), ("labelled", "direct labelling")]


def fname(num, slug, mode, ext):
    return f"fig{num:02d}_{slug}_{mode}.{ext}"


def render_single(num, slug, func, size, mode):
    fig = plt.figure(figsize=size)
    ax = fig.add_axes([0.02, 0.1, 0.96, 0.88])
    refs = func(ax, mode)
    fig.text(0.5, 0.03, f"FIG. {num}", ha="center", va="bottom", fontsize=14, weight="bold")
    for ext in ("pdf", "png"):
        fig.savefig(os.path.join(OUT, fname(num, slug, mode, ext)), dpi=200,
                    bbox_inches="tight", pad_inches=0.15, facecolor="white")
    plt.close(fig)
    return refs


def page_header(fig, title, sub, page):
    fig.text(0.08, 0.955, title, fontsize=13, weight="bold", va="top")
    fig.text(0.08, 0.93, sub, fontsize=9, va="top", family="monospace", color="#333333")
    fig.add_artist(plt.Line2D([0.08, 0.92], [0.915, 0.915], color="black", lw=0.6))
    fig.text(0.92, 0.03, f"Page {page}", ha="right", fontsize=8, color="#555555")
    fig.text(0.08, 0.03, "TempSim – patent-style drawings", fontsize=8, color="#555555")


def main():
    entries = []
    for num, slug, title, func, size in FIGS:
        for mode, mdesc in MODES:
            refs = render_single(num, slug, func, size, mode)
            entries.append(dict(num=num, slug=slug, title=title, func=func, size=size, mode=mode,
                                mdesc=mdesc, refs=refs))
    summary = os.path.join(OUT, "patent_drawings_summary.pdf")
    A4 = (8.27, 11.69)
    with PdfPages(summary) as pdf:
        # --- cover + index
        fig = plt.figure(figsize=A4)
        fig.text(0.08, 0.93, "Patent-Style Technical Drawings", fontsize=22, weight="bold", va="top")
        fig.text(0.08, 0.885, "TempSim – one-dimensional transient heat conduction (Temperatur1D)",
                 fontsize=11.5, va="top")
        intro = ("Seven drawings of the TempSim subject matter, each rendered in the two customary\n"
                 "patent drawing styles:\n"
                 "  • Numbered – black line art with reference numerals and curved lead lines;\n"
                 "    the numerals are explained in the reference list on each page.\n"
                 "  • Labelled – the same view with direct text labels and straight leader lines.\n"
                 "Hatching marks sectioned parts, dash-dot lines are centre lines, dashed lines are\n"
                 "hidden edges or cell faces. Every drawing is also stored as a separate vector PDF\n"
                 "and PNG under the file name given below (folder docs/patent_drawings/).")
        fig.text(0.08, 0.85, intro, fontsize=9.5, va="top", linespacing=1.5)
        fig.text(0.08, 0.66, "Index of drawings", fontsize=13, weight="bold", va="top")
        y = 0.625
        cols = [0.08, 0.16, 0.36]
        for x, h in zip(cols, ["FIG.", "Style", "File name (.pdf / .png)"]):
            fig.text(x, y, h, fontsize=8.5, weight="bold", va="top")
        fig.text(0.92, y, "Page", fontsize=8.5, weight="bold", va="top", ha="right")
        fig.add_artist(plt.Line2D([0.08, 0.92], [y - 0.017, y - 0.017], color="black", lw=0.6))
        y -= 0.03
        for k, e in enumerate(entries):
            if e["mode"] == "numbered":
                fig.text(cols[0], y, f"{e['num']}", fontsize=8.5, va="top", weight="bold")
                fig.text(cols[1], y, e["title"], fontsize=8.5, va="top", weight="bold")
                y -= 0.021
            fig.text(cols[1], y, e["mdesc"], fontsize=8, va="top")
            fig.text(cols[2], y, fname(e["num"], e["slug"], e["mode"], "pdf"), fontsize=7.8,
                     va="top", family="monospace")
            fig.text(0.92, y, str(k + 2), fontsize=8, va="top", ha="right")
            y -= 0.019
            if e["mode"] == "labelled":
                fig.add_artist(plt.Line2D([0.08, 0.92], [y + 0.004, y + 0.004], color="#bbbbbb", lw=0.4))
                y -= 0.01
        fig.text(0.08, y - 0.02, f"Summary file: patent_drawings_summary.pdf   ·   generated "
                 f"{date.today().isoformat()} by make_drawings.py", fontsize=8, va="top", color="#444444")
        fig.text(0.92, 0.03, "Page 1", ha="right", fontsize=8, color="#555555")
        pdf.savefig(fig); plt.close(fig)
        # --- one page per drawing
        for k, e in enumerate(entries):
            fig = plt.figure(figsize=A4)
            page_header(fig, f"FIG. {e['num']} – {e['title']}",
                        f"File: {fname(e['num'], e['slug'], e['mode'], 'pdf')}  (+ .png)   ·   "
                        f"Style: {e['mdesc']}", k + 2)
            w, h = e["size"]
            has_list = e["mode"] == "numbered"
            refs = e["refs"]
            rows = (len(refs) if max(len(r[1]) for r in refs) > 40 else math.ceil(len(refs) / 2))
            top, bottom = 0.89, (0.10 + 0.019 * rows + 0.08 if has_list else 0.17)
            avail_h = (top - bottom) * A4[1]
            avail_w = 0.84 * A4[0]
            s = min(avail_w / w, avail_h / h)
            aw, ah = w * s / A4[0], h * s / A4[1]
            ax = fig.add_axes([0.5 - aw / 2, top - ah, aw, ah])
            e["func"](ax, e["mode"])
            fig.text(0.5, top - ah - 0.01, f"FIG. {e['num']}", ha="center", va="top", fontsize=13,
                     weight="bold")
            if has_list:
                refs = e["refs"]
                ly = top - ah - 0.07
                fig.text(0.08, ly, "Reference list", fontsize=10.5, weight="bold", va="top")
                ncol = 1 if max(len(r[1]) for r in refs) > 40 else 2
                per = math.ceil(len(refs) / ncol)
                for j, r in enumerate(refs):
                    c, row = divmod(j, per)
                    num_s = f"S{r[0]}" if e["num"] == 4 else str(r[0])
                    fig.text(0.08 + c * 0.43, ly - 0.03 - row * 0.019, num_s, fontsize=8.5, va="top",
                             weight="bold")
                    fig.text(0.15 + c * 0.43, ly - 0.03 - row * 0.019, r[1].replace("\n", " "),
                             fontsize=8.5, va="top")
            else:
                fig.text(0.08, top - ah - 0.07, "Direct-labelling variant of the drawing on the previous "
                         "page: same view and part layout,\nwith the reference numerals replaced by "
                         "plain-text labels on straight leader lines.",
                         fontsize=8.5, va="top", color="#333333", linespacing=1.4)
            pdf.savefig(fig); plt.close(fig)
    print("wrote", summary)


if __name__ == "__main__":
    main()
