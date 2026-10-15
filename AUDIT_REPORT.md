# Project audit and repair notes

## Changes applied
- Added a real Godot `AudioBusLayout` resource with `Master`, `Engine`, `SFX`, and `Music` buses. The previous resource was effectively empty, so individual audio volume settings could not be routed as intended.
- Fixed a lifecycle issue in `scripts/game_manager.gd`: returning to the main menu now queues the previous camera rig for deletion instead of leaving stale camera nodes behind.
- Expanded the garage from three to six selectable original procedural vehicles with distinct performance values and paint colors.
- Strengthened `tools/validate_project.py` to check the audio bus layout and detect empty critical project assets.
- Updated `.github/workflows/build-android.yml` to run preflight validation before installing the Android toolchain and to run a headless Godot startup smoke test before exporting the APK.
- Updated the README to match the current vehicle count and CI checks.
- Fixed the steering-wheel drag variables with explicit `float` types to avoid GDScript inference failures.
- Replaced the kinked track control points with a smooth closed loop and placed the player at the loop start facing the initial straight.
- Disabled back-face culling on the procedural asphalt material so the road remains visible if triangle winding varies.
- Reworked city decoration sampling so buildings, lamps, and trees are actually distributed along both sides of the track; added window geometry to multiple building facades.
- Corrected the audio bus setting to Godot 4's `audio/buses/default_bus_layout` project setting.
- Made the GitHub Actions import step fail when the log contains script/parse/import errors, rather than relying only on process exit status.
- Removed the stray empty `tools/4` file.

## Verification status
- `python3 tools/validate_project.py`: **PASS** in this environment after the latest repairs.
- Project resource reference scan and WAV integrity checks: included in the preflight validator and passed.
- Static inspection confirms the previous steering type-inference issue and the city decoration modulo/step mismatch have been corrected.
- Godot editor parsing, runtime smoke test, and Android APK export: **not run in this editing environment** because a Godot executable/Android export toolchain is not installed here. The GitHub Actions workflow now runs those checks; a successful workflow run is still required to confirm the APK builds.

## Asset note
The vehicle models and city are procedural, original in-game geometry. The project does not contain licensed photorealistic Ferrari, Lamborghini, or Toyota 3D models or manufacturer logos. The six garage vehicles are fictional designs rather than representations of real manufacturer models.
