# Project audit and repair notes

## Changes applied
- Deferred Garage navigation and changed dynamic UI/world cleanup to queued deletion, avoiding immediate destruction of the button/control currently dispatching a touch event.
- Hardened touch pedals by relying on button-down/button-up signals instead of the unreliable `mouse_exited` path on mobile.
- Added four procedural AI opponents in Race Mode. Each opponent follows the generated loop, waits for the start countdown, and stops when the race ends.
- Added a finite nitro charge with boost acceleration, gradual recharge, live percentage text, and a HUD charge bar.
- Replaced the night-black world background with a procedural blue daytime sky, brighter ambient/sun lighting, a lighter asphalt material, brighter building palettes, and greener landscape.
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
- Python project preflight and resource-reference checks were rerun after these changes and passed.
- A Godot executable is not installed in this editing environment, so the modified GDScript still needs the GitHub Actions headless parse/startup step to confirm engine-level syntax and runtime behavior.
- `python3 tools/validate_project.py`: **PASS** in this environment after the latest repairs.
- Project resource reference scan and WAV integrity checks: included in the preflight validator and passed.
- Static inspection confirms the previous steering type-inference issue and the city decoration modulo/step mismatch have been corrected.
- Godot editor parsing, runtime smoke test, and Android APK export: **not run in this editing environment** because a Godot executable/Android export toolchain is not installed here. The GitHub Actions workflow now runs those checks; a successful workflow run is still required to confirm the APK builds.

## Asset note
The vehicle models and city are procedural, original in-game geometry. The project does not contain licensed photorealistic Ferrari, Lamborghini, or Toyota 3D models or manufacturer logos. The six garage vehicles are fictional designs rather than representations of real manufacturer models.


## Mobile control hotfix after device testing
- Found a concrete runtime bug in `scripts/ui/driving_hud.gd`: the HUD declared `nitro_bar` but did not instantiate it, then assigned `nitro_bar.value` each frame. That null-instance error interrupted `_process()` before it forwarded throttle, brake, steering, and nitro inputs to the car.
- Instantiated and styled the nitro charge bar; reordered the HUD update so `vehicle.set_inputs()` is called before optional telemetry widgets are updated; added validity checks around HUD elements.
- Changed the nitro button to use the same pressure-aware pedal component as the throttle/brake, so it also receives direct touch-index tracking.
- Updated `scripts/ui/pedal_control.gd` to track `InputEventScreenTouch.index` in addition to desktop mouse signals. This lets the throttle/brake/nitro hold state work independently of a second finger steering, while still releasing the correct pedal when its finger lifts.
- Aligned the four race opponents to the first track tangent and placed them in two rows ahead of the player, within the chase camera view, instead of fixed world-axis offsets that could place them beside/ahead of the player on a curved starting segment.
- Extended `tools/validate_project.py` to detect a missing nitro progress bar, ensure controls are forwarded before HUD updates, verify multitouch tracking, and check race-AI hookup.
- Validation performed here: Python preflight/resource checks and static source checks. The Godot executable is not installed in this editing environment, so engine parsing, device multitouch, AI driving, and the Android APK still require a new successful GitHub Actions run and on-device play test.
