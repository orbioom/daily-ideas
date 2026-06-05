# Diffusion Canvas

A real-time Gray-Scott reaction-diffusion simulation — organic patterns emerging from pure mathematics.

## The Idea

Two chemicals (U and V) react and diffuse across a 256×256 grid according to three parameters:
feed rate (f), kill rate (k), and two diffusion coefficients. The results are startlingly organic:
worms, coral, cell membranes, maze-like structures, spots. All emerge from the same equations with
slightly different parameters.

Click anywhere to seed new reaction points. Adjust sliders to sculpt the pattern in real time.
Save the result as a PNG at any moment.

## How to Run

Open `index.html` in any browser. The simulation runs immediately in the browser using Canvas 2D API.
No install, no WebGL required.

**Controls:**
- **Pattern presets**: worms, spots, coral, cells, maze, chaos
- **f** slider: feed rate (how fast U is added)
- **k** slider: kill rate (how fast V is removed)
- **Du / Dv**: diffusion rates for each chemical
- **Click canvas**: seed new V at that point
- **pause / reset / save PNG**: playback controls

## The Science

Gray-Scott is Alan Turing's reaction-diffusion mechanism made computational. In 1952 Turing published
"The Chemical Basis of Morphogenesis" — a mathematical model of how biological patterns like zebra
stripes and leopard spots arise from chemical interactions. The Gray-Scott model (1983) is a
simplified, numerically stable version that produces the widest range of patterns.

This implementation runs 4 iterations per animation frame using typed arrays (Float32Array) for
performance — no WebGL needed for 256×256 at interactive speeds.

## Parameter Space

| Preset | f | k | Result |
|--------|---|---|--------|
| worms  | 0.055 | 0.062 | long branching worm-like patterns |
| spots  | 0.035 | 0.065 | isolated spots, self-organizing |
| coral  | 0.058 | 0.065 | coral-like branching structures |
| cells  | 0.026 | 0.051 | cell membrane-like divisions |
| maze   | 0.029 | 0.057 | labyrinthine maze patterns |
| chaos  | 0.026 | 0.061 | turbulent, unpredictable |

## Orbioom Feeling

Dark canvas stage. The color mapping goes from deep ink (#1a1b22) through muted blue-gray to
near-white glass — the Orbioom mist palette rendered as chemical concentration. Controls in
a glass-dark bottom panel. Live green dot for the running state. The canvas itself is the product.
