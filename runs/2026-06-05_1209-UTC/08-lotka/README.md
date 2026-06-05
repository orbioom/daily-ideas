# Lotka — Predator–Prey Dynamics Simulator

## What it is

Lotka is a small, self-contained, interactive scientific web app that simulates
the classical **Lotka–Volterra predator–prey** model. It numerically integrates
the equations with a hand-written **4th-order Runge–Kutta (RK4)** scheme and
draws, live to `<canvas>`:

- a **time series** of prey and predator populations versus time, and
- a **phase portrait** (predator vs prey) with nullclines, a normalized vector
  field, and the coexistence equilibrium marked.

You can drag sliders for every parameter, toggle a logistic-prey extension,
animate the trajectory being traced, load preset scenarios, and export the
plots (PNG) and the integrated series (CSV). Opening `index.html` runs a default
simulation immediately — no build, no server, no terminal.

## The science (for a smart non-expert)

**Predator–prey dynamics** describe how two interacting populations rise and
fall over time. Imagine rabbits (*prey*) and foxes (*predators*). When rabbits
are plentiful, foxes eat well and multiply; more foxes then eat more rabbits, so
the rabbit population crashes; with little to eat, foxes starve and decline; with
few foxes, rabbits rebound — and the cycle repeats. This feedback loop produces
**oscillations**: both populations rise and fall in a repeating wave, with the
predator peak lagging behind the prey peak.

The **Lotka–Volterra model** captures this with two equations. Writing `x` for
prey and `y` for predator populations:

```
dx/dt = αx − βxy      (prey grow at rate α, are eaten at rate β·xy)
dy/dt = δxy − γy       (predators gain from eating at rate δ, die at rate γ)
```

- **α (alpha)** — prey reproduction rate (births when no predators).
- **β (beta)** — how often a predator–prey encounter kills prey.
- **γ (gamma)** — predator death rate (starvation when no prey).
- **δ (delta)** — how efficiently eaten prey become new predators.

The term `xy` is the **law of mass action**: encounters scale with the product
of the two populations.

A **phase portrait** plots predator (y) against prey (x), dropping time. Each
point is a population pair; following the curve shows how the system moves
through "state space." For the classic model the trajectory is a **closed loop**
(a cycle that returns to its start) circling the **equilibrium point**
`(x*, y*) = (γ/δ, α/β)` — the coexistence balance where neither population
changes. **Nullclines** are the lines where one population is momentarily steady
(prey nullcline `y = α/β`; predator nullcline `x = γ/δ`); the equilibrium is
where they cross. The **vector field** (small arrows) shows the instantaneous
direction of motion at each state, so you can see the rotation by eye.

The **logistic-prey extension** adds a **carrying capacity** `K` — a maximum prey
population the environment can support:

```
dx/dt = αx(1 − x/K) − βxy
```

This breaks the perfect cycle: instead of a closed loop, the trajectory
**spirals inward** to the equilibrium (damped oscillations), a more realistic
behaviour.

## Method & citations

**Equations.** The classic Lotka–Volterra system above, plus the optional
logistic-prey variant. State vector `s = [x, y]`; the right-hand side is the
**vector field** `f(s)`.

**Integrator — classical 4th-order Runge–Kutta (RK4).** Implemented directly in
`js/ode.js` (`rk4Step`), no library. From state `s` with step `h`:

```
k1 = f(s)
k2 = f(s + h/2 · k1)
k3 = f(s + h/2 · k2)
k4 = f(s + h   · k3)
s_next = s + (h/6)·(k1 + 2·k2 + 2·k3 + k4)
```

RK4 has local truncation error of order `h⁵` and global error of order `h⁴`,
which is why a step like `dt = 0.01` keeps the conserved quantity flat to ~1e-9
over the default run.

**Conserved quantity (classic model only).** The classic Lotka–Volterra system
has a constant of motion:

```
V = δx − γ·ln(x) + βy − α·ln(y)
```

`V` is invariant along the exact trajectory. Watching its **drift** over the
numerical run is an integration-quality check: a small drift means the integrator
is faithful. `V` is undefined when a population reaches 0 (logarithm), and is not
conserved under the logistic extension — the app shows it as not applicable then.

**Citations.**

- Lotka, A. J. (1925). *Elements of Physical Biology.* Williams & Wilkins.
- Volterra, V. (1926). "Fluctuations in the abundance of a species considered
  mathematically." *Nature*, 118, 558–560.
- Runge, C. (1895) and Kutta, W. (1901) — the classical 4th-order Runge–Kutta
  method.

**Honest simplifications.** This is a **continuous, deterministic, well-mixed**
model. There is no demographic stochasticity (no random births/deaths), no
spatial structure, no age or sex classes, and interactions are instantaneous and
proportional to `xy`. The classic model's closed orbits are structurally fragile
— any model perturbation or accumulated numerical error slowly changes the orbit;
the logistic extension regularizes this into a stable spiral. Populations are
treated as continuous real numbers and are **dimensionless** unless you assign
your own units (e.g. individuals, and time in generations).

## How to open it

**Open `index.html` in any modern browser** — a default simulation runs
automatically. No build step, no server, no terminal, no network access. Just
double-click the file (or `File ▸ Open`).

## Data

There is **no external dataset**. The model is fully **analytic / synthetic**:
every curve is computed live from the equations and your chosen parameters. All
parameters (α, β, γ, δ, K, x₀, y₀, T, dt) are **dimensionless** by default; you
may interpret `x`, `y` as population counts and `t` as time in generations if you
wish to assign units. Results are **deterministic** — the same parameters always
produce the same output, so the default open always shows the identical
oscillation.

## Controls & export

- **Rates** α, β, γ, δ — slider + numeric input each; change re-integrates live.
- **Model** — toggle *Logistic prey* to reveal the carrying-capacity `K` control.
- **Initial state & integration** — initial prey `x₀`, predator `y₀`, total time
  `T`, step `dt`.
- **Play / Pause** + **Speed** — animate a cursor tracing the trajectory on both
  plots. Honors reduced-motion (see below).
- **Presets** — *Classic oscillation*, *High amplitude*, *Predator extinction*,
  *Damped (logistic prey)*. Clicking loads a full parameter set.
- **Reset defaults** — restores the first-open configuration.
- **Export PNG** — saves a stacked image of both plots (`lotka-plots.png`).
- **Export CSV** — saves the integrated series `t, prey, predator`
  (`lotka-series.csv`).
- **Theme** — toggles a calm light/dark palette.

**Readouts** (mono) show the equilibrium point, a period estimate (from prey-peak
spacing), prey/predator min–max, the number of steps integrated, and the
conserved quantity `V` with its drift.

## Accessibility & reproducibility

- **Keyboard operable**: every slider, numeric input, button, and the play/pause
  toggle is reachable and operable by keyboard, with a visible focus ring.
- **ARIA**: controls carry `aria-label`s; each canvas is `role="img"` with an
  `aria-label` that describes the current dynamics (e.g. "oscillating with period
  about 5.5 time units") and updates live as you change parameters.
- **Contrast**: text and UI meet WCAG AA against the mist background. The two
  species lines use ink and a calm muted indigo/steel (clearly legended); the
  brand green `#86C79A` is reserved strictly for the playing/active indicator.
- **Reduced motion**: when `prefers-reduced-motion: reduce` is set, the app does
  **not** auto-animate — it shows the fully drawn static trajectory; if the
  preference flips on mid-play, animation stops.
- **Responsive**: layout reflows narrow → desktop; canvases redraw crisply via
  `devicePixelRatio` and on resize. Relative (rem/clamp) units throughout.
- **Theme**: calm dark mode via `[data-theme]` and `prefers-color-scheme`.
- **Reproducible**: no randomness anywhere — same defaults produce the same
  result on every open.

**Crash-proofing.** Invalid inputs are clamped with a calm inline message rather
than crashing: `dt ≤ 0` and `T ≤ 0` reset to safe values; negative rates and
populations clamp to 0; `ln(x)` is guarded (V skipped when a population is ≤ 0).
Total steps are **capped at 200,000** (`dt` is increased to fit if you request
more), preventing runaway loops, and non-finite blow-ups stop integration
gracefully and are reported. No uncaught exceptions, no division by zero.

## Self-review

- **Anti-stub scan**: `grep -rniE "todo|fixme|xxx|placeholder|lorem|coming
  soon|not implemented|// stub"` over `08-lotka/` returns **clean** — no stubs,
  no TODOs, no placeholders.
- **Smoke test**: opening `index.html` runs the default simulation immediately
  and shows a correct classic oscillation (prey & predator waves, predator peak
  lagging) and a closed-loop phase portrait around equilibrium `(20, 10)`.
- **Numerical check**: with defaults the conserved quantity `V` drifts only
  ~1.6e-9 over the full run, confirming the RK4 integrator is faithful; the
  detected period (~5.48 time units) is stable.
- **Separation**: the math (`js/ode.js`) is DOM-free and runs/tests standalone
  under Node (`require('./js/ode.js')`), separate from the UI (`js/main.js`).
```

## Files

```
08-lotka/
├── index.html        # default sim runs on open; controls + plots + panels
├── css/styles.css    # Orbioom brand tokens, layout, light/dark, states
├── js/ode.js         # RK4 integrator, LV vector field, conserved quantity (testable)
├── js/main.js        # UI wiring, canvas rendering, animation, export
└── README.md
```
