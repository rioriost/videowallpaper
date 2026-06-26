# Renderer Loop Mathematical Verification

This document records the loop contract for the 25 renderer families available in RioVideoWallpaper.

## Loop Model

`RenderClock` defines:

```text
N = round(fps * loopSeconds)
t(i) = (i mod N) / N
phi(i) = 2*pi*t(i)
```

The exporter writes frames `0...(N - 1)`. A seamless loop does not duplicate frame `0` at the end; playback continues from frame `N - 1` to the implied next frame `N`, and `phi(N) = phi(0)`.

For a stateless renderer, the mathematical requirement is:

```text
F(phi + 2*pi*k) = F(phi), for every integer k
```

For renderers with accumulation buffers, the emitted point input can be exactly periodic while the framebuffer state follows a recurrence:

```text
S(i + 1) = a*S(i) + I(phi(i))
```

where `0 <= a < 1`. This recurrence has a unique periodic steady state for periodic `I`, but finite warmup approaches it asymptotically. In practice the exporter uses warmup frames for visual continuity; strict equality of accumulation state requires either rendering from the periodic steady state or using no trail accumulation.

Floating-point rounding and video compression are excluded from the mathematical proof; they are implementation artifacts.

## Verification Summary

| Family | Phase source | Loop verdict |
| --- | --- | --- |
| Field Lines | Integer band phases, seed phase, sine/cosine flow terms over `phi` | Input geometry is exactly periodic. Trail buffer is conditionally periodic after warmup/steady state. |
| Orbital | Integer orbital rings and sine/cosine body motion over `phi` | Input geometry is exactly periodic. Trail buffer is conditionally periodic after warmup/steady state. |
| Soft Volumetric | Seeded deterministic cloud points with sine/cosine drift over `phi` | Exactly periodic as a stateless draw. |
| Grid City | Seeded deterministic skyline/grid coordinates with periodic scan and glow terms | Exactly periodic as a stateless draw. |
| Interference Field | Integer radial/wave harmonics sampled from sine/cosine phase | Exactly periodic as a stateless draw. |
| Periodic Noise | Torus-style sine/cosine noise coordinates using wrapped phase | Exactly periodic as a stateless draw. |
| Cyclic Automata | Cell state and palette are derived from wrapped frame phase and integer cycle counts | Exactly periodic for the sampled loop period. |
| Agent Swarm | Deterministic agents follow closed sine/cosine paths | Exactly periodic as a stateless draw. |
| Kaleidoscope | Rotational symmetry and palette shifts are integer harmonic phase functions | Exactly periodic as a stateless draw. |
| Voronoi Flow | Seeded cells orbit on closed phase paths | Exactly periodic as a stateless draw. |
| Reaction Diffusion | Pattern is analytic reaction-diffusion-inspired sampling over wrapped phase, not an open-ended simulation | Exactly periodic as a stateless draw. |
| Plasma Field | Plasma field samples are sums of sine/cosine terms over wrapped phase | Exactly periodic as a stateless draw. |
| Harmonic Tunnel | Camera/tunnel coordinates repeat with integer harmonic depth phase | Exactly periodic as a stateless draw. |
| Lissajous Weave | Lissajous parameters are integer harmonics of `phi` | Exactly periodic as a stateless draw. |
| Phyllotaxis Bloom | Golden-angle spatial order is static; bloom and hue are sine/cosine phase functions | Exactly periodic as a stateless draw. |
| Hex Pulse Lattice | Hex cell pulses and hue shifts are integer harmonic phase functions | Exactly periodic as a stateless draw. |
| Superformula Morph | Contours interpolate between formula endpoints with sine/cosine phase functions | Exactly periodic as a stateless draw. |
| Closed Flow Particles | Streamlines use closed vector-field sine/cosine terms and integer harmonic path offsets | Exactly periodic as a stateless draw. |
| SDF Tunnel | Radial bands and apparent camera flight use wrapped tunnel/depth phase | Exactly periodic as a stateless draw. |
| Feedback Synth | Visual feedback look is synthesized from finite repeated echoes, not framebuffer recursion | Exactly periodic as a stateless draw. |
| Guilloche Rose | Rose-engine curves use integer harmonic epicyclic phase terms | Exactly periodic as a stateless draw. |
| Instanced Geometry | Instance transforms use closed rotation/scale/orbit sine/cosine terms | Exactly periodic as a stateless draw. |
| Metaball Field | Blob centers orbit on closed sine/cosine paths and iso-contours are sampled deterministically | Exactly periodic as a stateless draw. |
| Penrose Tiling | Spatial quasi-tiling is static; color, rotation, and pulse terms are periodic phase functions | Exactly periodic as a stateless draw. |
| Wave Terrain | Height field ridges are sums of integer harmonic waves over wrapped phase | Exactly periodic as a stateless draw. |

## New Procedural Renderer Proof

The eight renderer families added in this phase share `ProceduralPatternRenderer`. It computes:

```text
cycleCount = integer clamp(round(speed * 2), 1...5)
theta = local parameter in [0, 2*pi]
phi' = cycleCount * phi + seedPhase
```

Every visible coordinate, scale, alpha pulse, hue offset, and rotation is composed from:

```text
sin(m*theta + n*phi' + c)
cos(m*theta + n*phi' + c)
```

where `m` and `n` are integers derived from clamped harmonic parameters and `c` is a seed-derived constant. Therefore:

```text
sin(x + 2*pi*q) = sin(x)
cos(x + 2*pi*q) = cos(x)
```

for integer `q`, so each generated vertex set at frame `N` is identical to frame `0`.

## Practical Cautions

- Stateful trail renderers (`Field Lines`, `Orbital`) are visually loopable with warmup, but their accumulation buffers are not strictly equal after finite warmup unless the trail term is disabled or the system is initialized at its periodic steady state.
- Video codecs can introduce small boundary differences even when renderer math is periodic.
- A renderer can be mathematically periodic and still look too static if its parameters use low modulation, low alpha, or a small drawing radius. That is a visual-quality issue, not a loop-contract failure.
