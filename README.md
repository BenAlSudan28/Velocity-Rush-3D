# VELOCITY RUSH 3D
### SUPER STAR RACING EXPERIENCE

**Godot 4.x · GDScript · Android 9+ · Offline-first · GitHub Actions APK build**

This is a self-contained Godot project with a playable procedural driving loop, a curved city sprint course, touch controls, local synthetic audio, and a GitHub Actions Android export workflow. Game geometry, materials and the six fictional vehicles are generated locally by GDScript; the game does not download resources when it runs.

> **Important scope note:** this is a developed, playable foundation—not a finished AAA commercial game. It does not bundle photorealistic licensed car models, real-world city scans, recordings of actual Ferrari/Lamborghini/Toyota engines, licensed music. The included car designs are original fictional procedural meshes; all supplied sounds are synthesized locally for the project. The city is a stylized procedural environment rather than a 1:1 replica of a real city. No real manufacturer names or logos are used as in-game vehicle branding.

## Implemented gameplay

- **Race Mode:** an 850 m sprint with countdown and four procedural AI rivals following the circuit; elapsed time, distance, top speed, collisions and session score are tracked.
- **Free Drive:** the same curved city circuit with no forced time limit or loss screen.
- **Garage:** six selectable procedural cars with different top speed, acceleration, braking and handling parameters. The selected car is saved locally.
- **Driving HUD:** live speed (km/h), RPM derived from the vehicle controller, time, distance and race progress; pause, camera switch, steering, throttle, brake and boost controls.
- **Three control modes:** HYDRAULIC STEERING (interactive touch wheel with gradual recentering), BUTTON STEERING (hold left/right), and TILT STEERING (phone sensor, with a clear warning when sensors are unavailable).
- **Cameras:** smoothed chase camera and a camera anchor attached to a simple 3D cockpit built into each car.
- **Driving and collision loop:** gradual acceleration/braking, drag, speed-limited steering response, nitro boost, wheel rotation, track collision and impact penalty.
- **Local audio:** engine loop whose pitch follows RPM, turbo burst, brake pulse, tire-skid loop, impact sound, UI/launch cues, and separately adjustable optional menu music. Audio is stored as WAV files and works offline.
- **Settings and save data:** engine/effects/music levels, master sound toggle, graphics preset, control mode, steering/tilt sensitivity, selected car, best score and best time stored in `user://velocity_rush_3d.cfg`.
- **Original app icon** and a custom audio bus layout with Master, Engine, SFX and Music buses.

## Project layout

```text
Velocity-Rush-3D/
├── project.godot
├── export_presets.cfg
├── icon.png / icon.svg
├── scenes/
│   ├── main.tscn
│   ├── car.tscn
│   ├── race_track.tscn
│   └── free_drive.tscn
├── scripts/
│   ├── game_manager.gd
│   ├── car_controller.gd
│   ├── environment_builder.gd
│   ├── race_track_scene.gd
│   ├── camera_controller.gd
│   ├── race_manager.gd
│   ├── garage_controller.gd
│   ├── settings_manager.gd
│   ├── save_manager.gd
│   ├── audio_manager.gd
│   └── ui/
│       ├── driving_hud.gd
│       ├── steering_wheel.gd
│       ├── pedal_control.gd
│       └── results_screen.gd
├── assets/sounds/       # Eight local synthesized WAV assets + bus layout
├── android/README.md
├── tools/validate_project.py
└── .github/workflows/build-android.yml
```

Menu, garage, settings, pause overlay and results UI are composed by GDScript at runtime so that they share the same style and callbacks without duplicated scene files.

## Build an Android APK from GitHub on your phone

1. Download and extract this ZIP on your phone. Open the extracted `Velocity-Rush-3D` folder.
2. Create an empty GitHub repository. Upload the **contents of this folder** to the repository root—not the enclosing folder. Confirm that `project.godot` and `.github/workflows/build-android.yml` are visible at the root paths.
3. Open the repository's **Actions** tab and select **Build VELOCITY RUSH 3D Android APK**. Use **Run workflow**, or push a commit to `main`/`master`.
4. Wait for the run to finish. In the successful run, download the artifact named **Velocity-Rush-3D-Android-APK**. It contains `VelocityRush3D.apk`.
5. Install that APK on the Android device. Android may ask you to allow installation from the browser/file manager you used.

The workflow downloads the pinned Godot 4.4.1 editor and its matching official Android export templates, configures Java 17 and the Android SDK, runs a local-resource/audio-bus preflight, imports the project, runs a headless startup smoke test and exports a debug APK. It does not require Android Studio on your phone. The APK is debug-signed for testing, not a production Play Store release.

## Run locally in Godot

Open `project.godot` in **Godot 4.4.1** and run the main scene. For an Android export from the editor, install the matching export templates and configure Java 17 and Android SDK paths in Editor Settings. The exported device build uses landscape orientation and targets Android 9/API 28 or later.

For a quick file/audio preflight from the project root:

```bash
python3 tools/validate_project.py
```

Godot itself is the source of truth for GDScript parsing and Android export. The preflight script checks required files, literal `res://` references and WAV integrity; the GitHub Actions workflow separately performs Godot import/parse and APK export. This environment did not have the Godot executable available, so a successful engine compile or APK has **not** been claimed here; the first Actions run is the build verification step.

## Controls

**Touch:** drag the steering wheel or hold left/right buttons; press and hold THROTTLE or BRAKE; hold N₂O BOOST for extra acceleration. Camera switches between chase and cockpit. Pause offers resume or main-menu return.

**Desktop testing:** `W` accelerate, `S` brake, `A`/`D` steer, `Shift` boost.

## Development notes

- Vehicle and city meshes are local/procedural. Add licensed `.glb`/`.gltf` assets under `assets/` when available, then update `car_controller.gd` and the garage metadata to use them.
- The physics is a lightweight arcade-style custom controller intended for Android performance, not a high-fidelity tire/vehicle dynamics simulator.
- The race is a solo distance/pace challenge. It does not simulate opponents.
- No network permission is requested and no external service is needed at runtime.
- See `LICENSE` for project source and generated-asset terms. Keep any future third-party asset attribution/licenses with the asset files.
