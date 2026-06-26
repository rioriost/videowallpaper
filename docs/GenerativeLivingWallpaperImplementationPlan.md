# Generative Living Wallpaper Implementation Plan

## Purpose

This document describes a concrete implementation plan for a macOS app that turns natural-language visual descriptions into deterministic, loopable abstract wallpaper videos.

The intended product is not only a video wallpaper player. It is a generative visual editor for macOS:

1. The user describes an atmosphere such as "sci-fi", "nostalgic", "cosmic", "virtual", "future city", or "fantasy".
2. An LLM translates that language into structured visual intent and renderer parameters.
3. Swift/Metal renders an interactive real-time preview.
4. The user adjusts parameters directly until the result feels right.
5. The same renderer exports a full-resolution seamless loop video.
6. The generated video is passed to the existing VideoWallpaper playback/wallpaper system.

The core product value is the semantic translation layer: turning ambiguous human mood words into stable, reproducible rendering parameters.

## Product Positioning

This sits between three existing categories:

- Video wallpaper players: good at playback, weak at creation.
- VJ/live visual tools: powerful, but too complex for wallpaper users.
- AI image/video generators: expressive, but weak at deterministic looping, performance, and local editability.

The app should feel like a consumer-grade "ambient VJ for your desktop": language-guided, parameter-driven, deterministic, and fast enough to explore interactively.

## Non-Goals For The First Version

- Do not generate video frames with an image/video diffusion model.
- Do not depend on Siri's ChatGPT or Gemini integration as an internal app backend.
- Do not attempt to become a full VJ suite with clip decks, MIDI control, projection mapping, Syphon, or multi-layer live performance.
- Do not build a public marketplace in the MVP.
- Do not require continuous GPU rendering as the wallpaper. Render once, then play the resulting video.

## Recommended MVP Architecture

```text
User prompt
    |
    v
LanguageToIntentService
    |
    v
VisualIntent
    |
    v
IntentToRenderParameters
    |
    v
GenerativeRenderer
    |
    +--> MTKView realtime preview
    |
    +--> OfflineVideoExporter
             |
             v
          MP4/MOV file
             |
             v
          VideoWallpaper playback/wallpaper layer
```

The same `GenerativeRenderer` must be used for both preview and export. Preview and export may use different output resolution and timing mechanics, but they must share shader code, parameter interpretation, random seed handling, and loop logic.

## Main Modules

### 1. App Shell

Technology:

- SwiftUI for the main UI.
- AppKit where required for window behavior, file dialogs, and integration with the existing VideoWallpaper app.
- `MTKView` embedded in SwiftUI for live Metal preview.

Responsibilities:

- Prompt input and generated intent display.
- Parameter controls.
- Preview viewport.
- Preset/seed management.
- Export queue UI.
- "Set as wallpaper" action.

Suggested UI layout:

- Left sidebar: prompt, style chips, seed, presets, generation history.
- Center: live preview.
- Right inspector: renderer parameters grouped by palette, composition, motion, particles, lines, post effects, loop/export.
- Bottom toolbar: randomize, mutate, preview resolution, export, set wallpaper.

### 2. LanguageToIntentService

Responsible for converting user language into a typed `VisualIntent`.

Inputs:

- User prompt.
- Current `VisualIntent` if this is an edit command.
- Current renderer family and supported parameter ranges.
- Optional user preferences such as "avoid flashing", "subtle motion", or "OLED dark".

Outputs:

- Strict typed `VisualIntent`.
- Human-readable interpretation summary.
- Confidence/warnings for incompatible requests.

Provider options:

- MVP: OpenAI Responses API with Structured Outputs.
- Later: Apple Foundation Models framework on supported macOS versions.
- Later: provider abstraction for OpenAI, Apple Foundation Models, Gemini, Claude, or user-supplied local models.

Important design point:

Do not ask the LLM for final Metal uniforms directly. Ask it for a mid-level visual intent. Then deterministic app code maps the intent to renderer parameters. This keeps output stable, testable, and compatible across LLM providers.

### 3. VisualIntent Model

`VisualIntent` is the semantic intermediate representation. It should be stable across renderer versions.

Example:

```json
{
  "schemaVersion": 1,
  "title": "Cosmic Nostalgic Signal",
  "summary": "A slow cosmic field with nostalgic neon-magenta and cyan trails.",
  "moodTags": ["cosmic", "nostalgic", "sci_fi", "virtual"],
  "palette": {
    "hueBaseDegrees": 232,
    "hueSpreadDegrees": 88,
    "saturation": 0.78,
    "brightness": 0.92,
    "contrast": 0.74,
    "warmth": 0.22
  },
  "composition": {
    "density": 0.70,
    "symmetry": 0.42,
    "depth": 0.68,
    "centerPull": 0.54,
    "negativeSpace": 0.34
  },
  "motion": {
    "loopSeconds": 12.0,
    "speed": 0.36,
    "turbulence": 0.44,
    "regularity": 0.62,
    "trailLength": 0.66
  },
  "elements": {
    "particleAmount": 0.82,
    "lineAmount": 0.68,
    "objectAmount": 0.18,
    "gridAmount": 0.22,
    "glowAmount": 0.75
  },
  "styleWeights": {
    "sciFi": 0.84,
    "fantasy": 0.08,
    "nostalgia": 0.55,
    "virtual": 0.72,
    "futureCity": 0.24,
    "cosmic": 0.91
  },
  "safety": {
    "flashIntensity": 0.12,
    "motionIntensity": 0.44
  },
  "seedHint": "cosmic-nostalgic-signal"
}
```

All numeric fields should be normalized to `0.0...1.0` unless there is a specific reason not to, such as hue degrees or loop seconds.

### 4. IntentToRenderParameters Mapper

This is deterministic application code. It converts `VisualIntent` into shader and engine parameters.

Responsibilities:

- Clamp all values.
- Apply style presets.
- Resolve conflicts.
- Generate defaults.
- Convert semantic values to actual shader uniforms.
- Preserve compatibility when renderers evolve.

Example mapping:

```text
sciFi high:
  hue range -> cyan / blue / magenta
  line sharpness -> high
  glow -> medium-high
  gridAmount -> medium
  turbulence -> lower, more synthetic
  symmetry -> medium

fantasy high:
  hue range -> green / gold / violet
  glow -> soft
  particles -> dust-like
  turbulence -> higher, organic
  line sharpness -> lower

nostalgia high:
  saturation -> slightly lower
  contrast -> softer
  hue drift -> warmer
  trail persistence -> longer
  motion speed -> lower

cosmic high:
  negative space -> higher
  particle field -> higher
  depth -> higher
  center pull -> medium
  glow -> high
```

This mapper should be unit-tested heavily. The LLM can vary; the mapper is the source of product consistency.

### 5. GenerativeRenderer

Core rendering engine.

Targets:

- Interactive preview through `MTKView`.
- Offline render to `MTLTexture` for video export.

Suggested renderer structure:

```text
GenerativeRenderer
  RendererState
  RendererParameters
  RenderClock
  SeededRandom
  ParticlePass
  LineFieldPass
  ShapePass
  FeedbackPass
  BloomPass
  ToneMapPass
```

The renderer should operate on normalized loop time:

```swift
let t = Double(frameIndex) / Double(totalFrames)
let phase = 2.0 * .pi * t
```

All procedural time functions must be loop-aware. Prefer `sin`, `cos`, periodic noise, torus-domain noise, or seeded cyclic curves. Avoid unbounded time accumulation for anything that affects visible output.

### 6. Preview Pipeline

Preview can run with compromises:

- Lower internal render scale.
- Variable display frame rate.
- Skipped expensive export-only passes.
- Reduced particle count.

Preview must preserve the same semantic output:

- Same seed.
- Same parameter mapping.
- Same loop period.
- Same approximate composition.

The preview UI should support:

- Play/pause.
- Scrub loop time.
- Preview current loop cut.
- Toggle "show seam check" to rapidly jump between last and first frames.
- Preview at 1x, 2x, 4x internal resolution if the hardware allows.

### 7. Offline Export Pipeline

Offline export should be deterministic and fixed-step.

Inputs:

- `RendererParameters`
- seed
- resolution
- fps
- loop seconds
- output codec/profile
- warmup loop count

Steps:

1. Create offscreen `MTLTexture` at target resolution.
2. Run warmup frames without writing. Use at least one full loop for feedback/trail effects.
3. Render frame `0...totalFrames-1`.
4. Copy/bridge each frame into `CVPixelBuffer`.
5. Append frames to `AVAssetWriter`.
6. Finalize file.
7. Register output in local library.
8. Optionally set it as wallpaper through the VideoWallpaper playback system.

Do not append a duplicate first frame at the end. Seamless video loops should contain exactly `fps * loopSeconds` frames. Duplicating frame 0 creates a visible pause.

### 8. Video Encoding

Recommended MVP codec:

- H.264 for compatibility.
- HEVC option for higher quality/smaller files.
- `yuv420p` equivalent for broad playback compatibility.

Recommended output presets:

- 1920x1080, 30fps, 10-20 seconds.
- 2560x1440, 30fps, 10-20 seconds.
- 3840x2160, 30fps, 10-20 seconds.
- Later: 5K/6K and 60fps.

Quality controls:

- Draft: lower bitrate, faster encode.
- High: default wallpaper export.
- Archive: HEVC/high bitrate, slower.

### 9. Wallpaper Integration

The app should not rely on `NSWorkspace.setDesktopImageURL` for video wallpapers. That API is for desktop images. For generated videos, reuse or integrate with the VideoWallpaper playback approach:

- Place a borderless, non-activating window behind desktop icons or at the appropriate desktop level.
- One player per screen.
- Support independent display assignment.
- Pause when fullscreen apps are active.
- Pause/reduce frame rate on battery if configured.
- Restore wallpaper on app launch.

The generative app should export a video and hand it to the wallpaper playback layer as a local asset.

Potential integration shapes:

- Monorepo module: VideoWallpaper playback code becomes a framework target consumed by the generative app.
- Companion app: generative app exports to a shared application support folder and asks VideoWallpaper to set the asset.
- Unified app: VideoWallpaper gains a "Generate" tab and uses the existing playback engine.

Recommended direction:

Start by adding the generative workflow as a new feature area in VideoWallpaper if the codebase is clean enough. If the current VideoWallpaper project is intentionally small, create a separate `GenerativeWallpaperKit` framework and import it.

## LLM Integration Plan

### Provider Abstraction

Create a provider-neutral interface:

```swift
protocol VisualIntentProvider {
    func generateIntent(
        prompt: String,
        currentIntent: VisualIntent?,
        rendererCapabilities: RendererCapabilities
    ) async throws -> VisualIntentResponse
}
```

Implementations:

- `OpenAIVisualIntentProvider`
- `AppleFoundationModelsIntentProvider`
- `MockVisualIntentProvider`
- Later: `GeminiVisualIntentProvider`

The UI should not care which provider is active.

### OpenAI Provider

Use the Responses API with Structured Outputs.

Request style:

- System/developer instructions define the visual parameter vocabulary.
- User input contains the natural language prompt and optional current state.
- `text.format` uses a strict JSON schema matching `VisualIntent`.
- `store: false` unless product analytics or history explicitly require otherwise.

Why:

- The task is schema generation, not open-ended conversation.
- Structured Outputs reduce invalid JSON and hallucinated fields.
- The app can validate and clamp every returned field before preview.

Operational note:

Do not embed a production OpenAI API key in the shipped macOS app. Use one of:

- User-supplied API key.
- A small backend service owned by the app developer.
- Apple Foundation Models as the default local provider, with OpenAI as an optional enhanced provider.

### Apple Foundation Models Provider

Use when targeting macOS versions that expose the Foundation Models framework.

Advantages:

- On-device or Apple-managed model access.
- Better privacy story.
- No per-request app developer API cost for on-device models.
- Native Swift guided generation for Swift data structures.

Risks:

- OS-version dependency.
- Model availability varies by hardware, region, and language.
- The exact capability level may be lower than cloud LLMs for nuanced aesthetic interpretation.

Recommended behavior:

- Use Apple Foundation Models for simple prompt-to-intent conversion when available.
- Offer OpenAI as an optional "enhanced interpretation" mode.
- Cache successful prompt-to-intent results locally.

### Siri And App Intents

Siri integration should be an interaction layer, not the internal LLM backend.

Useful App Intents:

- "Generate a cosmic wallpaper."
- "Make this wallpaper more nostalgic."
- "Increase particles."
- "Export this as a 4K wallpaper."
- "Set the latest generated wallpaper on all displays."

Siri can trigger app actions through App Intents. The app still owns the actual prompt interpretation and rendering pipeline.

Do not depend on Siri's ChatGPT/Gemini extension to return app-internal structured parameters. That integration is user-facing and confirmation/privacy controlled, not a stable programmatic API for this product.

## Parameter Editing UX

Generated results should always remain editable.

Controls:

- Text prompt.
- Style chips: sci-fi, fantasy, cosmic, nostalgic, virtual, future city, organic, minimal, energetic, calm.
- Sliders: density, speed, particle amount, line amount, glow, color spread, trail length, symmetry, turbulence.
- Seed controls: lock seed, randomize seed, mutate seed.
- Loop controls: seconds, fps, seam preview.

Suggested interaction:

1. User types "cosmic but nostalgic, like an old sci-fi computer dreaming".
2. App generates `VisualIntent`.
3. Preview updates.
4. UI shows derived style chips and sliders.
5. User drags "particle amount" or asks "make it quieter".
6. The app either applies deterministic local edits or calls the LLM with current intent.

For simple commands like "more particles", do not call the LLM. Apply local parameter deltas. Use the LLM for ambiguous semantic edits.

## Renderer Families

Do not make one universal shader too early. Build several renderer families with shared parameters:

### Field Lines

The current feasibility study maps here.

Features:

- Parametric rings and lines.
- Particle field.
- Feedback/trails.
- Additive glow.
- Good for cosmic, sci-fi, virtual, energy, aurora.

### Soft Volumetric

Features:

- Layered noise fields.
- Slow color drift.
- Low contrast motion.
- Good for calm, dreamy, fantasy, underwater, nebula.

### Grid City

Features:

- Perspective grid.
- Light streaks.
- Synthetic skyline hints.
- Good for future city, cyberpunk, virtual, terminal.

### Symbolic/Orbital

Features:

- Orbiting shapes.
- Glyph-like points and arcs.
- Good for mystic, fantasy, scientific, ritual, celestial.

The LLM can select a renderer family plus normalized intent. Each renderer family maps shared semantics differently.

## Looping Requirements

Loop quality is a first-class feature.

Rules:

- Use fixed frame count: `totalFrames = fps * loopSeconds`.
- Render frames `0..<totalFrames`.
- Use normalized loop time `t = frame / totalFrames`.
- Ensure all visible time functions are periodic.
- Warm up feedback buffers before export.
- Do not append duplicate first frame.
- Provide seam preview in UI.

Feedback/trail handling:

- For preview, let the buffer settle naturally.
- For export, run `warmupLoops * totalFrames` frames without writing.
- Default `warmupLoops = 1`.
- If trail length is extreme, use `warmupLoops = 2`.

## Persistence

Save generated wallpapers as projects, not only videos.

Project file should contain:

- App version.
- Renderer family and renderer version.
- `VisualIntent`.
- `RendererParameters`.
- Seed.
- Export settings.
- Prompt history.
- Thumbnail.
- Output video path, if exported.

Example file extension:

- `.generativewallpaper`
- or plain `.json` inside an application support library.

This allows future re-export at higher resolution.

## Suggested Data Types

```swift
struct WallpaperProject: Codable, Identifiable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var appVersion: String
    var rendererFamily: RendererFamily
    var rendererVersion: Int
    var promptHistory: [PromptEntry]
    var visualIntent: VisualIntent
    var renderParameters: RenderParameters
    var seed: UInt64
    var exportSettings: ExportSettings
    var assets: ProjectAssets
}
```

```swift
struct ExportSettings: Codable {
    var width: Int
    var height: Int
    var fps: Int
    var loopSeconds: Double
    var codec: VideoCodec
    var quality: ExportQuality
    var warmupLoops: Int
}
```

## Implementation Phases

### Current Implementation Status (2026-06-24)

Implemented in the repository:

- Phase 0 core path: SwiftUI editor shell, `MTKView` preview, `FieldLinesRenderer`, deterministic seeded render clock, loop transport controls including seam preview, and editable Field Lines parameters.
- Phase 1 core path: offscreen Metal export through `AVAssetWriter`, warmup frames, progress/cancel UI, App Store screenshot export presets, exported video metadata validation, and generated thumbnails.
- Phase 2 first path: generated asset library, export-to-library flow, history list, cleanup of orphaned generated assets, "Set as Wallpaper" handoff to the existing playback path, and per-display video assignment for local wallpaper playback.
- Phase 3 local semantic path: `VisualIntent`, deterministic intent-to-render mapping, style presets, local provider, example provider, provider cache/resolver with transient retry and local fallback, provider selection persistence, validation, photosensitivity/reduced-motion safety clamps, project sanitization on load, and provider-agnostic strict `VisualIntent` JSON Schema/request/response helpers.
- Phase 4 first OpenAI path: optional OpenAI Responses API provider with Structured Outputs, user-supplied API key storage in Keychain, `store: false` requests, HTTP/error mapping, local fallback through the shared resolver, and nonblocking prompt resolution from the editor UI.
- Phase 6 renderer families: Orbital, Soft Volumetric, and Grid City renderer families with project JSON support, editor renderer switching, semantic intent mapping, safety clamping, thumbnails, and MP4 export through the shared render pipeline.
- Hardening path: playback suspend policy for sleeping displays and frontmost fullscreen-style windows, low-power preview frame-rate reduction, hidden-window preview pause, deterministic renderer/export tests, and generated asset cleanup tests.
- App Store support: privacy policy/review notes describe local generated wallpaper behavior and optional off-device prompt interpretation only when the user selects OpenAI and saves their own API key.

Not yet implemented:

- Phase 4 remaining OpenAI work: live credential validation UX, App Store privacy nutrition updates for optional prompt transmission, and final provider policy decision for whether OpenAI ships enabled in the App Store build.
- Phase 5 Apple Foundation Models/App Intents.
- Export/performance verification for sustained 10-second 2560 x 1600 and 4K-class renders on the target MacBook Air thermal profile.

### Phase 0: Port Feasibility Study To Metal

Goal:

Reproduce the current Processing/Python visual style in Swift/Metal preview.

Deliverables:

- SwiftUI app shell.
- `MTKView` preview.
- One `FieldLinesRenderer`.
- Manual sliders for current known parameters.
- Seeded deterministic output.
- Loop-time based animation.

Exit criteria:

- Runs at interactive frame rate at preview resolution.
- Looks recognizably similar to the feasibility study.
- First/last loop preview is visually continuous after warmup.

### Phase 1: Offline Export

Goal:

Render the same output to MP4/MOV at selected resolution.

Deliverables:

- Offscreen Metal render target.
- Fixed-step export clock.
- Warmup frame support.
- `AVAssetWriter` exporter.
- Export progress and cancellation.
- 1080p and 4K presets.

Exit criteria:

- 10-second 4K 30fps export works.
- Exported loop has no visible seam.
- Preview and exported video match within expected resolution differences.

### Phase 2: VideoWallpaper Integration

Goal:

Use generated videos as wallpapers.

Deliverables:

- Generated asset library folder.
- "Set as wallpaper" command.
- Integration with existing multi-monitor playback.
- Per-display assignment.
- Relaunch restore.

Exit criteria:

- Generate, export, set as wallpaper flow works without manual file selection.
- Existing user-selected video wallpaper behavior still works.

### Phase 3: VisualIntent And Local Mapping

Goal:

Introduce semantic data model and deterministic mapping before adding cloud calls.

Deliverables:

- `VisualIntent` model.
- `IntentToRenderParameters` mapper.
- Built-in style chips.
- Mock provider with hardcoded examples.
- Unit tests for mapping.

Exit criteria:

- Selecting "sci-fi", "fantasy", "nostalgic", and "cosmic" produces meaningfully different previews without LLM calls.
- Parameters remain editable after style application.

### Phase 4: OpenAI Prompt-To-Intent

Goal:

Convert arbitrary user language into `VisualIntent`.

Deliverables:

- Provider abstraction.
- OpenAI provider.
- Structured Outputs schema.
- Error handling and retry strategy.
- User API key or backend proxy decision.
- Local cache keyed by prompt + renderer capabilities.

Exit criteria:

- User prompt reliably produces valid `VisualIntent`.
- Invalid or irrelevant prompts return a useful fallback.
- UI shows interpretation summary.
- User can refine by typing follow-up instructions.

### Phase 5: Apple Foundation Models And App Intents

Goal:

Integrate platform-native AI and Siri actions where available.

Deliverables:

- Apple Foundation Models provider.
- App Intents for common commands.
- Siri/Shortcuts actions for generate, mutate, export, and set wallpaper.

Exit criteria:

- On supported macOS versions, basic semantic generation works without external API.
- Siri can trigger app actions, while the app still owns rendering and parameter generation.

### Phase 6: Additional Renderer Families

Goal:

Expand beyond one visual style.

Deliverables:

- Symbolic/Orbital renderer. Implemented with selectable Orbital parameters, intent mapping, thumbnail generation, and export through the shared pipeline.
- Soft Volumetric renderer. Implemented with selectable cloud/layer/spread/glow parameters, intent mapping, thumbnail generation, and export through the shared pipeline.
- Grid City renderer. Implemented with selectable perspective grid/tower parameters, intent mapping, thumbnail generation, and export through the shared pipeline.
- Renderer-family selection in `VisualIntent`.
- Shared export pipeline.

Exit criteria:

- At least three distinct visual families export seamless loops.
- LLM can choose a renderer family from prompt semantics.

## Concrete Execution Roadmap

This section turns the architecture above into implementation-sized work. It assumes the first production path is a unified app: the current VideoWallpaper app gains a generative workflow while preserving the existing "choose local video and play it as wallpaper" behavior.

### Product And Architecture Decisions For The First Build

Decisions:

- Build inside the existing `VideoWallpaper` app first.
- Add a normal SwiftUI editor window opened from the menu bar.
- Keep the current wallpaper playback path as the final "Set as wallpaper" mechanism.
- Build one renderer family first: `FieldLinesRenderer`.
- Do not add OpenAI, Apple Foundation Models, Siri, or App Intents until preview and export are trustworthy.
- Store generated videos and project JSON under Application Support.
- Keep generated video export local-only.

Initial non-decisions:

- Do not split out `GenerativeWallpaperKit` until the codebase has real module pressure.
- Do not design multiple renderer families in code before the first renderer is stable.
- Do not add account systems, subscriptions, cloud sync, marketplace, or remote render workers.

### Proposed Source Layout

Keep the current app small by grouping the new feature under a clear folder boundary:

```text
VideoWallpaper/
  App/
    VideoWallpaperApp.swift
    AppDelegate.swift                  # later split out from current app file
  WallpaperPlayback/
    VideoWindowController.swift
    WallpaperPlaybackController.swift  # extracted facade around existing behavior
    VideoAssetDiagnostics.swift
  Generative/
    Model/
      WallpaperProject.swift
      VisualIntent.swift
      RenderParameters.swift
      ExportSettings.swift
      RendererFamily.swift
    Mapping/
      IntentToRenderParameters.swift
      FieldLinesPresetMapper.swift
    Rendering/
      GenerativeRenderer.swift
      FieldLinesRenderer.swift
      MetalRenderContext.swift
      RenderClock.swift
      SeededRandom.swift
      Shaders/
        FieldLines.metal
    Preview/
      MetalPreviewView.swift
      GenerativeEditorView.swift
      GenerativeInspectorView.swift
      PreviewControlsView.swift
    Export/
      OfflineVideoExporter.swift
      MetalFrameReader.swift
      PixelBufferPool.swift
      GeneratedAssetLibrary.swift
    Services/
      VisualIntentProvider.swift
      MockVisualIntentProvider.swift
```

The exact filenames can change, but these boundaries should remain stable:

- `WallpaperPlayback` owns desktop-level windows and AVPlayer behavior.
- `Generative/Rendering` owns Metal state, shaders, render targets, and deterministic frame rendering.
- `Generative/Export` owns fixed-step rendering and AVAssetWriter.
- `Generative/Model` owns Codable project state and versioned schemas.
- `Generative/Mapping` owns deterministic interpretation from semantic intent to renderer parameters.
- SwiftUI views should not contain rendering math or export logic.

### Feasibility Study Port Map

The Python script `docs/render_processing_loop.py` is the behavior reference for the first renderer.

Python concepts and their Swift/Metal equivalents:

| Python feasibility study | Swift/Metal implementation |
| --- | --- |
| `Renderer.width`, `height` | Render target size in `MetalRenderContext` |
| `total_frames` | `RenderClock(totalFrames:)` |
| `phase = tau * frame / total_frames` | `RenderClock.phase` and `RenderClock.normalizedLoopTime` |
| `canvas *= 1.0 - fade_alpha` | Feedback fade pass over previous frame texture |
| `bands` | `FieldLinesParameters.bandCount` |
| `points_per_band` | Generated polyline vertex count or compute thread count |
| `particle_count` | Particle instance count |
| `line_step` | Segment sampling density or line rasterization step |
| `gaussian_kernel` for lines/particles | Point sprites or additive fragment shader falloff |
| `draw_polyline` | Metal draw calls for sampled line points or instanced segments |
| `hsv_to_rgb` | Metal shader utility |
| PNG frame output | `CVPixelBuffer` frames appended to `AVAssetWriter` |
| `warmup_loops` | Unsaved fixed-step render iterations before export frame 0 |

Important parity requirements:

- The first Metal renderer does not need pixel-perfect parity with Python.
- It must preserve the same visual grammar: cyclic line bands, particle field, additive trails, hue drift, and warmup-fed feedback.
- It must use the same loop-time rule: frame `0..<totalFrames`, no duplicate first frame.
- It must be deterministic for the same parameters and seed.

### Renderer Implementation Strategy

Implement the first renderer in three internal passes:

1. Feedback pass:
   - Input: previous accumulated texture.
   - Output: current accumulated texture.
   - Operation: multiply previous color by `1 - fadeAlpha`.
   - Purpose: replaces Python's persistent `canvas`.

2. Field line pass:
   - Generate band points from the same periodic equations as Python.
   - Render additive points or short segments into the current accumulated texture.
   - Use a smooth radial falloff in the fragment shader instead of CPU Gaussian kernels.
   - Start with point sprites because they are simpler than thick polyline joins.

3. Particle pass:
   - Generate deterministic particle positions from particle id, seed, and loop phase.
   - Render additive point sprites.
   - Use the same periodic particle angle approach as Python.

The first implementation can use CPU-generated vertex buffers each frame if that gets preview working quickly. Move point generation to a compute shader only after profiling shows the CPU path is a bottleneck.

Renderer state:

```swift
struct FieldLinesParameters: Codable, Equatable {
    var bandCount: Int
    var pointsPerBand: Int
    var particleCount: Int
    var fadeAlpha: Float
    var lineStep: Float
    var hueBaseDegrees: Float
    var hueDriftDegrees: Float
    var saturation: Float
    var brightness: Float
    var lineAlpha: Float
    var particleAlpha: Float
    var lineWeight: Float
    var speed: Float
    var turbulence: Float
}
```

Initial defaults should match the Python script closely:

- `bandCount = 9`
- `pointsPerBand = 720`
- `particleCount = 2200`
- `fadeAlpha = 0.18`
- `lineStep = 1.7`
- `loopSeconds = 10`
- `fps = 30`

### Milestone 0: Project Preparation

Goal:

Make room for the larger feature without changing current wallpaper behavior.

Tasks:

- Split `AppDelegate` out of `VideoWallpaperApp.swift` when practical.
- Extract existing playback operations behind a small facade:
  - `setVideoURL(_:)`
  - `restoreSavedVideoURL()`
  - `changeVideoFromOpenPanel()`
  - `setPlaybackSuspended(_:)`
- Add a "Generate Wallpaper..." command to the menu bar.
- Open a normal app window for the generative editor.
- Add empty model types and compile-only tests.

Exit criteria:

- Existing local-video wallpaper flow still works.
- The menu can open and close the generative editor window.
- The project builds without adding rendering behavior.

Suggested first PR:

- Only app shell extraction and a blank generative editor window.
- No Metal yet.

### Milestone 1: FieldLines Preview Prototype

Goal:

Display the feasibility-study visual in a live `MTKView`.

Tasks:

- Add `MetalPreviewView` as an `NSViewRepresentable` wrapping `MTKView`.
- Add `MetalRenderContext` to own device, command queue, pipeline state, and render targets.
- Add `RenderClock` with:
  - play/pause
  - loop seconds
  - normalized loop time
  - fixed frame index mode for export later
- Add `FieldLinesRenderer`.
- Add `FieldLines.metal`.
- Render feedback, field lines, and particles.
- Add minimal sliders:
  - bands
  - particles
  - fade/trail
  - speed
  - hue
  - glow/alpha
  - seed
  - loop seconds
- Add "seam check" controls:
  - jump to frame 0
  - jump to last frame
  - continuously alternate first/last frames for loop seam inspection

Exit criteria:

- Preview visibly resembles the Python feasibility study.
- Same seed and parameters produce stable output after restart.
- Preview remains responsive while sliders move.
- Loop seam is not obvious for default settings after warmup.

Implementation note:

If exact line rendering is slow or complex, use additive point sprites for line samples in the first pass. The visual can be improved later with segment joins, bloom, and post effects.

### Milestone 2: Project Persistence And Generated Asset Library

Goal:

Save generative work as editable projects, not only exported videos.

Tasks:

- Implement `WallpaperProject`, `RenderParameters`, and `ExportSettings`.
- Add schema version fields.
- Add Application Support storage:
  - `Projects/`
  - `Videos/`
  - `Thumbnails/`
- Save project JSON on meaningful edits.
- Save a thumbnail from the current preview texture.
- Add a simple project list/history in the editor sidebar.
- Add duplicate, rename, and delete operations.

Exit criteria:

- A generated project survives app restart.
- Opening a project restores parameters and seed.
- Existing generated videos remain linked from project metadata.

Suggested project format:

```json
{
  "schemaVersion": 1,
  "rendererFamily": "fieldLines",
  "rendererVersion": 1,
  "seed": 123456789,
  "visualIntent": null,
  "renderParameters": {},
  "exportSettings": {},
  "assets": {}
}
```

### Milestone 3: Offline Export MVP

Goal:

Export the same renderer to a loopable MP4/MOV.

Tasks:

- Add offscreen render target creation for arbitrary output sizes.
- Add fixed-step export clock.
- Add warmup frame loop.
- Add `PixelBufferPool` for target size and pixel format.
- Add `MetalFrameReader` to copy GPU texture data into `CVPixelBuffer`.
- Add `OfflineVideoExporter` using `AVAssetWriter`.
- Add export presets:
  - 1280x800, 30fps, 10s draft
  - 1920x1200, 30fps, 10s standard
  - 2560x1600, 30fps, 10s high
  - 3840x2160 or 3840x2400 later if performance allows
- Add export progress, cancellation, and error display.
- Add output registration in `GeneratedAssetLibrary`.

Exit criteria:

- A 10-second 1280x800 export succeeds.
- A 10-second 2560x1600 export succeeds on the target Apple Silicon machines.
- Exported file duration and frame count are correct.
- The exported loop has no duplicate first frame.
- Preview and export are visually aligned.

Validation commands:

```sh
ffprobe -hide_banner -show_streams -show_format GeneratedVideo.mp4
```

If `ffprobe` is not guaranteed on user machines, add an AVFoundation metadata validator in tests.

### Milestone 4: Set Generated Video As Wallpaper

Goal:

Close the loop from generation to actual desktop wallpaper.

Tasks:

- Add "Set as Wallpaper" to the export completion UI.
- Feed exported video URL into the existing playback controller.
- Save generated video URL as the selected wallpaper asset.
- Preserve security-scoped behavior for user-selected videos, but do not require it for app-owned generated files.
- Add restore-on-launch for generated assets.
- Add per-display behavior only after all-displays behavior works.

Exit criteria:

- User can generate, export, and set the exported video as wallpaper without using an open panel.
- Relaunch restores the generated wallpaper.
- Existing "Change Video..." still works with arbitrary local files.

### Milestone 5: VisualIntent Without LLM

Goal:

Introduce semantic modeling and deterministic mapping while all behavior remains local.

Tasks:

- Add `VisualIntent` model with schema version.
- Add `RendererCapabilities`.
- Add `IntentToRenderParameters`.
- Add built-in style chips:
  - sci-fi
  - cosmic
  - nostalgic
  - fantasy
  - virtual
  - calm
  - energetic
  - minimal
- Add `MockVisualIntentProvider` with several hardcoded prompt examples.
- Add local command handling for simple edits:
  - "more particles"
  - "slower"
  - "more blue"
  - "less bright"
  - "longer trails"
- Add mapper unit tests.

Exit criteria:

- Style chips produce visibly different but stable outputs.
- The same intent maps to the same parameters across launches.
- Invalid or extreme values are clamped before rendering.
- The editor can show both semantic intent and low-level parameters.

### Milestone 6: Prompt-To-Intent Provider

Goal:

Add natural-language generation after rendering/export are stable.

Tasks:

- Add `VisualIntentProvider` protocol.
- Add provider selection UI.
- Add OpenAI provider or local Apple provider depending on product decision.
- Use strict structured output for `VisualIntent`.
- Add validation and fallback path:
  - decode failure
  - unsupported renderer family
  - unsafe flash/motion settings
  - unavailable network/provider
- Add prompt result cache keyed by:
  - prompt
  - current intent
  - renderer capabilities version
  - provider id/version
- Add privacy copy explaining what text is sent when cloud providers are used.

Exit criteria:

- Free-form prompts produce valid intents.
- Follow-up edits can mutate the current intent.
- Provider failures do not break local parameter editing.
- Cloud API keys are not embedded in the app bundle.

### Milestone 7: Quality, Performance, And App Store Hardening

Goal:

Make the feature shippable rather than only impressive in demos.

Tasks:

- Add export cancellation reliability tests.
- Add renderer determinism tests.
- Add generated asset cleanup policy.
- Add battery/thermal behavior:
  - pause preview when window hidden
  - lower preview scale on battery if needed
  - continue wallpaper playback through AVFoundation hardware decode
- Add photosensitivity safety clamps:
  - max brightness oscillation
  - max contrast pulse
  - max strobe-like frequency
  - reduced motion mode
- Add reviewer notes explaining:
  - generated videos are local
  - no account required
  - no third-party content included
  - cloud prompt provider behavior if enabled
- Update privacy policy if cloud prompt providers ship.

Exit criteria:

- App remains responsive during export.
- No significant CPU work continues after preview window closes.
- Generated video files are discoverable and deletable.
- App Store review notes accurately describe the feature.

### Suggested Issue Breakdown

Use these as implementation tickets.

Foundation:

- GLW-001: Split app delegate and preserve current menu behavior.
- GLW-002: Extract wallpaper playback facade.
- GLW-003: Add generative editor window shell.
- GLW-004: Add model skeletons and compile-only tests.

Preview:

- GLW-010: Add MTKView SwiftUI bridge.
- GLW-011: Add Metal render context and shader loading.
- GLW-012: Add render clock and loop controls.
- GLW-013: Implement feedback fade pass.
- GLW-014: Implement field line point rendering.
- GLW-015: Implement particle rendering.
- GLW-016: Add preview sliders and seed controls.
- GLW-017: Add seam check controls. Implemented with first frame, last frame, and continuous loop seam preview controls.

Persistence:

- GLW-020: Add project JSON schema.
- GLW-021: Add application support generated asset library.
- GLW-022: Save/load projects.
- GLW-023: Generate and store thumbnails.
- GLW-024: Add project history UI.

Export:

- GLW-030: Add offscreen render target.
- GLW-031: Add fixed-step exporter clock.
- GLW-032: Add warmup render support.
- GLW-033: Add Metal texture to CVPixelBuffer bridge.
- GLW-034: Add AVAssetWriter MP4 export.
- GLW-035: Add export progress/cancel UI.
- GLW-036: Add export metadata validation.

Wallpaper integration:

- GLW-040: Set exported video as wallpaper.
- GLW-041: Restore generated wallpaper on launch.
- GLW-042: Preserve user-selected video flow.
- GLW-043: Add per-display assignment. Implemented with per-display stored video selections, security-scoped bookmarks for display-specific local files, menu commands for assigning one display or resetting all displays, generated-wallpaper assignment to a selected display, and shared playback sessions per unique video URL.

Semantic layer:

- GLW-050: Add VisualIntent schema.
- GLW-051: Add RendererCapabilities.
- GLW-052: Add IntentToRenderParameters mapper.
- GLW-053: Add style chips and local semantic presets.
- GLW-054: Add mock provider.
- GLW-055: Add mapper tests.

LLM/provider:

- GLW-060: Add VisualIntentProvider protocol. Implemented for local and bundled example providers.
- GLW-061: Add provider settings. Implemented as editor provider selection with persisted provider kind; external-provider settings remain future work.
- GLW-062: Add structured prompt provider. Implemented for the optional OpenAI Responses API path with Structured Outputs, Keychain-backed user API key storage, `store: false`, response parsing, HTTP error classification, retry/fallback integration, and nonblocking editor resolution. Apple/local structured providers remain future work.
- GLW-063: Add prompt result cache. Implemented for current provider requests through a shared resolver that owns cache hits, cached provider metadata, retry policy execution, validation, and local fallback.
- GLW-064: Add provider privacy/error UI. Implemented for local/example providers and fallback/error messages; external-provider consent copy remains future work.

Renderer families:

- GLW-080: Add Orbital renderer family. Implemented with renderer selection, Orbital project parameters, semantic mapping, safety limits, thumbnail rendering, and MP4 export via the shared render pipeline.
- GLW-081: Add Soft Volumetric renderer family. Implemented with renderer selection, cloud/layer project parameters, semantic mapping, safety limits, thumbnail rendering, and MP4 export via the shared render pipeline.
- GLW-082: Add Grid City renderer family. Implemented with renderer selection, Grid City project parameters, semantic mapping, safety limits, thumbnail rendering, and MP4 export via the shared render pipeline.

Hardening:

- GLW-070: Add renderer determinism tests. Implemented through seeded RNG and thumbnail render determinism checks.
- GLW-071: Add export smoke tests. Implemented through MP4 export and AVFoundation metadata validation checks.
- GLW-072: Add photosensitivity clamps. Implemented through intent validation, reduced-motion policy, and project sanitization tests.
- GLW-073: Add battery/hidden-window behavior. Implemented for wallpaper playback suspension, hidden/minimized preview pause, Low Power Mode preview frame-rate reduction, and playback suspension policy tests.
- GLW-074: Update App Store review notes and privacy policy. Implemented with local-only prompt handling, no-account/no-purchase/no-UGC review flow notes, no sensitive permission requests, no network transmission, and generated asset deletion notes.

### Critical Path

The shortest path to a convincing technical demo is:

1. GLW-003 editor window shell.
2. GLW-010 MTKView bridge.
3. GLW-011 Metal context.
4. GLW-013 feedback fade pass.
5. GLW-014 field line rendering.
6. GLW-015 particle rendering.
7. GLW-016 controls.
8. GLW-030 offscreen target.
9. GLW-034 AVAssetWriter export.
10. GLW-040 set exported video as wallpaper.

Do not start LLM/provider work until this path is complete.

### First Two-Week Slice

If work is time-boxed, the first slice should ignore persistence, LLM, and video export.

Scope:

- Blank generative editor window.
- `MTKView` preview.
- Field line pass.
- Particle pass.
- Feedback trail pass.
- Seed and three sliders.
- Seam check button.

Definition of done:

- The preview runs.
- It resembles the Python feasibility study.
- It is deterministic by seed.
- It can scrub or jump between first/last loop frames.
- Existing wallpaper playback is unaffected.

### Second Two-Week Slice

Scope:

- Offscreen render target.
- Warmup frames.
- 1280x800 and 2560x1600 export.
- Progress/cancel UI.
- Set exported video as wallpaper.

Definition of done:

- A generated 10-second video can be exported.
- The video can be set as wallpaper from inside the app.
- Relaunch restores that generated wallpaper.
- Exported frame count and duration validate correctly.

### Technical Risks To Retire Early

Retire these before investing in LLM UI:

- Metal feedback trails at export resolution.
- Texture-to-pixel-buffer throughput.
- AVAssetWriter color and pixel format correctness.
- Seam behavior with warmup buffers.
- App Store acceptability of the wallpaper window behavior with generated content.
- Thermal behavior during 4K export on MacBook Air.

## Testing Plan

### Unit Tests

- `VisualIntent` decode/encode.
- Parameter clamping.
- Intent mapping snapshots.
- Seed determinism.
- Loop frame count calculations.
- Export setting validation.

### Renderer Tests

- Render frame 0 and frame N after warmup; compare difference metrics.
- Render same seed twice; compare pixel hashes or tolerances.
- Validate no NaN/Inf values in parameter buffers.
- Validate supported resolutions.

### Export Tests

- Export 1-second smoke test.
- Export 10-second 1080p.
- Export 10-second 4K.
- Validate frame count, duration, codec, resolution with `ffprobe` or AVFoundation metadata.

### UX Tests

- Prompt: "sci-fi"
- Prompt: "cosmic and quiet"
- Prompt: "nostalgic computer dream"
- Prompt: "fantasy forest but abstract"
- Prompt: "future city, minimal, not too bright"
- Prompt: "make this slower and more blue"

For each prompt, verify:

- Intent is valid.
- Preview updates.
- Parameters are editable.
- Result is plausibly aligned with the language.

## Performance Targets

Preview:

- 60fps at reduced internal resolution on Apple Silicon where feasible.
- 30fps acceptable for heavy scenes.
- UI remains responsive during preview.

Export:

- 4K 30fps 10 seconds should complete in a reasonable time on Apple Silicon.
- Export can run slower than realtime.
- Export must be cancellable.

Wallpaper playback:

- Low CPU through hardware video decode.
- Pause or reduce load when fullscreen apps are active.
- Respect battery-saving settings.

## Privacy And Cost

OpenAI path:

- Natural-language prompts are sent to OpenAI unless using a user-provided or backend-mediated policy.
- Do not send rendered frames unless explicitly adding visual feedback features later.
- Use `store: false` for API calls unless there is a deliberate product reason otherwise.
- Do not embed secret API keys in the app bundle.

Apple Foundation Models path:

- Prefer on-device interpretation when available.
- Use as privacy-first default if quality is sufficient.

Local project data:

- Store prompts, parameters, seed, and generated video locally.
- Make cloud sync optional.

## Known Risks

### macOS Wallpaper Mechanics

There is no simple public API for setting arbitrary custom video as the native wallpaper. The project should reuse the existing VideoWallpaper playback strategy rather than depend on desktop image APIs.

### LLM Variability

Different providers will interpret mood words differently. Use a stable intermediate schema and deterministic mapper to preserve product consistency.

### Semantic Drift

If the LLM directly sets too many low-level parameters, prompts become hard to reason about. Keep the schema mid-level and let app code handle final rendering values.

### Export/Preview Mismatch

If preview and export use different render paths, users will lose trust. Keep one renderer with two targets.

### Photosensitive Motion

Generated visuals can accidentally create intense flashing. Include safety fields and clamp flash intensity, strobe frequency, brightness, and high-contrast oscillation.

### App Store Review

If using hidden desktop windows for wallpaper playback, test review implications early. Clearly communicate behavior and avoid private APIs.

## Open Questions

- Should this be a new app, or a feature area inside VideoWallpaper?
- Should OpenAI be user-key based, backend based, or omitted from App Store builds?
- What is the minimum macOS target?
- Should generated videos be H.264 by default, with HEVC as optional?
- Should the first release support only one display export at a time, or different generated videos per display?
- Should natural language edits always call the LLM, or use local command parsing for common edits?

## Recommended First Milestone

Build a small Swift/Metal prototype that does three things only:

1. Recreate the feasibility-study visual as a Metal `FieldLinesRenderer`.
2. Provide sliders for core parameters and seamless loop duration.
3. Export the preview as a 1080p and 4K MP4 using the same renderer.

Do not add LLM calls until this is stable. Once the rendering and export path is trustworthy, add `VisualIntent` and a mock provider, then replace the mock provider with OpenAI or Apple Foundation Models.

## Reference Notes

- OpenAI Structured Outputs: https://developers.openai.com/api/docs/guides/structured-outputs
- OpenAI Responses API migration/benefits: https://developers.openai.com/api/docs/guides/migrate-to-responses
- Apple ChatGPT extension behavior: https://support.apple.com/guide/mac-help/use-chatgpt-with-apple-intelligence-mchlfc5cf131/mac
- Apple Intelligence developer overview: https://developer.apple.com/apple-intelligence/
- Apple macOS 27 developer overview: https://developer.apple.com/macos/whats-new/
- Apple AVAssetWriter: https://developer.apple.com/documentation/avfoundation/avassetwriter
- Apple Metal drawables: https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html
