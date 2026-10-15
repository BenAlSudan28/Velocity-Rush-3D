#!/usr/bin/env python3
"""Lightweight static preflight for the Godot project; Godot itself parses scripts in CI."""
from pathlib import Path
import re
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required = [
    "project.godot",
    "export_presets.cfg",
    "icon.png",
    "icon.svg",
    "scenes/main.tscn",
    "scenes/car.tscn",
    "scenes/race_track.tscn",
    "scenes/free_drive.tscn",
    ".github/workflows/build-android.yml",
    "scripts/game_manager.gd",
    "scripts/car_controller.gd",
    "scripts/environment_builder.gd",
    "scripts/camera_controller.gd",
    "scripts/race_manager.gd",
    "scripts/audio_manager.gd",
    "scripts/save_manager.gd",
    "scripts/ui/driving_hud.gd",
    "scripts/ui/steering_wheel.gd",
    "scripts/ui/pedal_control.gd",
    "scripts/ui/results_screen.gd",
]
for rel in required:
    path = ROOT / rel
    if not path.is_file():
        errors.append(f"Missing required file: {rel}")
    elif path.stat().st_size == 0:
        errors.append(f"Empty required file: {rel}")

# Verify literal res:// references from project/resource/source files.
scan_suffixes = {".gd", ".tscn", ".tres", ".godot", ".cfg"}
ref_pattern = re.compile(r"res://([^\"'\s,)]+)")
for path in ROOT.rglob("*"):
    if not path.is_file() or path.suffix not in scan_suffixes:
        continue
    try:
        source = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for ref in ref_pattern.findall(source):
        ref = ref.rstrip(".;]")
        target = ROOT / ref
        if not target.exists():
            errors.append(f"Broken res:// reference in {path.relative_to(ROOT)}: {ref}")

# Every locally used sound should be an actual, non-trivial WAV file.
for wav_path in sorted((ROOT / "assets" / "sounds").rglob("*.wav")):
    try:
        with wave.open(str(wav_path), "rb") as stream:
            frames = stream.getnframes()
            rate = stream.getframerate()
            if frames < int(rate * 0.05):
                errors.append(f"Audio file is too short: {wav_path.relative_to(ROOT)}")
            if stream.getnchannels() != 1 or stream.getsampwidth() != 2:
                errors.append(f"Expected mono 16-bit PCM audio: {wav_path.relative_to(ROOT)}")
    except (wave.Error, OSError) as exc:
        errors.append(f"Invalid WAV {wav_path.relative_to(ROOT)}: {exc}")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
if 'run/main_scene="res://scenes/main.tscn"' not in project:
    errors.append("Main scene is not configured in project.godot")
if 'buses/default_bus_layout="res://assets/sounds/default_bus_layout.tres"' not in project:
    errors.append("Godot audio bus setting must use audio/buses/default_bus_layout")
if '\ndefault_bus_layout=' in project:
    errors.append("Legacy/incorrect default_bus_layout key found in project.godot")
if 'name="Android"' not in (ROOT / "export_presets.cfg").read_text(encoding="utf-8"):
    errors.append("Android export preset name must be exactly Android")

# The game uses three named audio buses. A blank/invalid layout silently
# routes them incorrectly and makes the individual volume settings ineffective.
bus_layout_path = ROOT / "assets" / "sounds" / "default_bus_layout.tres"
if not bus_layout_path.is_file() or bus_layout_path.stat().st_size < 100:
    errors.append("Audio bus layout is missing or empty: assets/sounds/default_bus_layout.tres")
else:
    bus_layout = bus_layout_path.read_text(encoding="utf-8")
    for bus_name in ("Master", "Engine", "SFX", "Music"):
        if f'&"{bus_name}"' not in bus_layout:
            errors.append(f"Audio bus layout is missing bus: {bus_name}")

# Avoid shipping empty scene/resource files, which can be overlooked by
# reference-only checks.
for path in ROOT.rglob("*"):
    if path.is_file() and path.suffix in {".gd", ".tscn", ".tres", ".wav"} and path.stat().st_size == 0:
        errors.append(f"Empty project asset: {path.relative_to(ROOT)}")

if errors:
    print("PROJECT PREFLIGHT FAILED:")
    for error in errors:
        print(" - " + error)
    sys.exit(1)

print("PROJECT PREFLIGHT PASSED")
print(f"Project: {ROOT.name}")
print(f"Local WAV assets: {len(list((ROOT / 'assets' / 'sounds').rglob('*.wav')))}")
print("Godot script parsing and APK export are verified separately by the GitHub Actions workflow.")
