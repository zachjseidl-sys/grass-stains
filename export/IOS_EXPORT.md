# Grass Stains — iOS Export

This vertical slice targets **Godot 4.3+** with the **Mobile** renderer (Metal).

## Prerequisites

1. Godot 4 editor with iOS export templates installed
2. macOS with Xcode
3. Apple Developer account (Team ID + signing)

## Steps

1. Open `project.godot` in Godot 4.
2. Let the editor import assets (audio, shaders, scene).
3. Project → Export → **iOS** preset (already configured in `export_presets.cfg`).
4. Set **Application/App Store Team ID** and signing identity in the export preset.
5. Export to `export/grass_stains.ipa` or **Export Project** for Xcode workflow.
6. Deploy to a physical iPhone — simulator Metal perf is not representative.

## Project settings already applied

- Landscape orientation (`window/handheld/orientation=4`)
- Mobile renderer + ASTC VRAM compression
- 60 FPS cap via `Engine.max_fps` in `scripts/main.gd`
- Bundle ID: `com.pinehollow.grassstains`

## Desktop testing (Windows)

Use **F5** in Godot or run the main scene:

- **WASD** — move / turn
- **Space** — pull starter cord / stop engine
- **Right mouse button** — orbit camera

Touch controls are mapped to the left/right halves of the screen for iOS.
