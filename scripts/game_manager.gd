extends Node3D

const CarScene = preload("res://scenes/car.tscn")
const TrackScene = preload("res://scenes/race_track.tscn")
const EnvironmentBuilder = preload("res://scripts/environment_builder.gd")
const CameraController = preload("res://scripts/camera_controller.gd")
const RaceManager = preload("res://scripts/race_manager.gd")
const HudSceneScript = preload("res://scripts/ui/driving_hud.gd")
const ResultsScreenScript = preload("res://scripts/ui/results_screen.gd")
const GarageController = preload("res://scripts/garage_controller.gd")
const SettingsManager = preload("res://scripts/settings_manager.gd")

var ui_layer: CanvasLayer
var ui_root: Control
var world_root: Node3D
var menu_camera: Camera3D
var world_light: DirectionalLight3D
var menu_car: Node3D
var player_car: CharacterBody3D
var camera_rig: Node3D
var race_manager: Node
var hud: Control
var selected_car: int = 0
var current_screen: String = "menu"
var _sound_button: Button
var _active_results: Dictionary = {}

func _ready() -> void:
    selected_car = int(SaveManager.setting("selected_car", 0))
    _setup_world()
    _setup_ui_layer()
    AudioManager.apply_settings()
    _show_main_menu()

func _setup_world() -> void:
    world_root = Node3D.new()
    world_root.name = "GeneratedWorld"
    add_child(world_root)
    var world_environment := WorldEnvironment.new()
    world_environment.name = "WorldLighting"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.018, 0.033, 0.055)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.47, 0.57, 0.67)
    env.ambient_light_energy = 0.72
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = env
    add_child(world_environment)
    world_light = DirectionalLight3D.new()
    world_light.name = "KeySunlight"
    world_light.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
    world_light.light_energy = 1.28
    world_light.shadow_enabled = true
    world_light.directional_shadow_max_distance = 90.0
    add_child(world_light)
    menu_camera = Camera3D.new()
    menu_camera.name = "ShowcaseCamera"
    menu_camera.position = Vector3(6.5, 5.4, 18.0)
    menu_camera.fov = 48.0
    menu_camera.near = 0.08
    menu_camera.far = 650.0
    add_child(menu_camera)
    menu_camera.look_at(Vector3(0.0, 1.0, -14.0), Vector3.UP)
    menu_camera.make_current()
    _apply_graphics_setting()

func _setup_ui_layer() -> void:
    ui_layer = CanvasLayer.new()
    ui_layer.name = "GameUI"
    add_child(ui_layer)
    ui_root = Control.new()
    ui_root.name = "UIRoot"
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
    ui_layer.add_child(ui_root)

func _process(delta: float) -> void:
    if current_screen in ["menu", "garage", "settings"] and is_instance_valid(menu_car):
        menu_car.rotate_y(delta * 0.13)
    if current_screen in ["race", "free_drive"] and is_instance_valid(race_manager):
        race_manager.call("tick", delta)

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        if current_screen in ["race", "free_drive"]:
            if get_tree().paused:
                get_tree().paused = false
                _show_main_menu()
            elif is_instance_valid(hud):
                hud.call("_toggle_pause")
        else:
            _show_main_menu()

func _show_main_menu() -> void:
    get_tree().paused = false
    current_screen = "menu"
    player_car = null
    camera_rig = null
    hud = null
    _free_race_manager()
    AudioManager.set_menu_audio()
    _rebuild_menu_stage()
    _clear_ui()
    _add_dark_overlay(0.37)
    var panel := _panel("MainMenuPanel", Vector2(28, 28), Vector2(425, 662), Color(0.018, 0.034, 0.052, 0.93), 18)
    ui_root.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 9)
    panel.add_child(content)
    content.add_child(_label("VELOCITY RUSH 3D", 38, Color(0.96, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label("SUPER STAR RACING EXPERIENCE", 13, Color(0.12, 0.82, 0.90), HORIZONTAL_ALIGNMENT_LEFT))
    var line := ColorRect.new()
    line.custom_minimum_size = Vector2(0, 3)
    line.color = Color(0.06, 0.75, 0.84)
    content.add_child(line)
    content.add_child(_label("FEEL THE LINE.\nOWN THE NIGHT.", 22, Color(0.79, 0.86, 0.91), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label("Choose your experience", 13, Color(0.48, 0.61, 0.70), HORIZONTAL_ALIGNMENT_LEFT))
    var race_button := _menu_button("01   RACE MODE", true)
    race_button.pressed.connect(func(): _start_game("race"))
    content.add_child(race_button)
    var free_button := _menu_button("02   FREE DRIVE", false)
    free_button.pressed.connect(func(): _start_game("free_drive"))
    content.add_child(free_button)
    var garage_button := _menu_button("03   CAR GARAGE", false)
    garage_button.pressed.connect(_show_garage)
    content.add_child(garage_button)
    var settings_button := _menu_button("04   SETTINGS", false)
    settings_button.pressed.connect(_show_settings)
    content.add_child(settings_button)
    _sound_button = _menu_button(_sound_button_text(), false)
    _sound_button.pressed.connect(_toggle_sound)
    content.add_child(_sound_button)
    var exit_button := _menu_button("EXIT GAME", false)
    exit_button.custom_minimum_size.y = 43
    exit_button.pressed.connect(func(): get_tree().quit())
    content.add_child(exit_button)
    content.add_child(_label("OFFLINE PLAY  •  SOLO SPRINT  •  BUILD 01", 10, Color(0.39, 0.50, 0.59), HORIZONTAL_ALIGNMENT_LEFT))
    _add_showcase_card()

func _show_garage() -> void:
    get_tree().paused = false
    current_screen = "garage"
    AudioManager.set_menu_audio()
    _rebuild_menu_stage()
    _clear_ui()
    _add_dark_overlay(0.34)
    var panel := _panel("GaragePanel", Vector2(35, 42), Vector2(440, 636), Color(0.015, 0.030, 0.048, 0.94), 20)
    ui_root.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    panel.add_child(content)
    content.add_child(_label("VEHICLE SELECT", 30, Color(0.95, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label("YOUR MACHINE. YOUR LINE.", 12, Color(0.12, 0.82, 0.90), HORIZONTAL_ALIGNMENT_LEFT))
    var spec: Dictionary = GarageController.car_spec(selected_car)
    content.add_child(_label("CAR %02d  /  %02d" % [selected_car + 1, GarageController.car_count()], 13, Color(0.55, 0.68, 0.77), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label(str(spec["name"]), 28, Color.from_string(str(spec["color"]), Color.WHITE), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label(str(spec["class"]), 13, Color(0.71, 0.79, 0.84), HORIZONTAL_ALIGNMENT_LEFT))
    var chooser := HBoxContainer.new()
    chooser.add_theme_constant_override("separation", 12)
    var previous := _menu_button("◀ PREVIOUS", false)
    previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    previous.pressed.connect(func():
        selected_car = GarageController.next_index(selected_car, -1)
        SaveManager.set_setting("selected_car", selected_car)
        _show_garage()
    )
    chooser.add_child(previous)
    var next := _menu_button("NEXT ▶", false)
    next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    next.pressed.connect(func():
        selected_car = GarageController.next_index(selected_car, 1)
        SaveManager.set_setting("selected_car", selected_car)
        _show_garage()
    )
    chooser.add_child(next)
    content.add_child(chooser)
    var performance := _panel("PerformancePanel", Vector2.ZERO, Vector2(0, 170), Color(0.035, 0.065, 0.085, 0.87), 12)
    content.add_child(performance)
    var perf_label := _label(GarageController.performance_summary(spec), 17, Color(0.83, 0.90, 0.94), HORIZONTAL_ALIGNMENT_LEFT)
    performance.add_child(perf_label)
    content.add_child(_label("All vehicles are original, procedural game models.", 11, Color(0.46, 0.58, 0.66), HORIZONTAL_ALIGNMENT_LEFT))
    var drive := _menu_button("DRIVE THIS CAR", true)
    drive.pressed.connect(func(): _start_game("free_drive"))
    content.add_child(drive)
    var back := _menu_button("BACK TO MAIN MENU", false)
    back.pressed.connect(_show_main_menu)
    content.add_child(back)
    _add_showcase_card()

func _show_settings() -> void:
    get_tree().paused = false
    current_screen = "settings"
    AudioManager.set_menu_audio()
    _rebuild_menu_stage()
    _clear_ui()
    _add_dark_overlay(0.48)
    var panel := _panel("SettingsPanel", Vector2(170, 34), Vector2(935, 650), Color(0.015, 0.031, 0.049, 0.97), 20)
    ui_root.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 8)
    panel.add_child(content)
    content.add_child(_label("DRIVE CONFIGURATION", 31, Color(0.95, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label("Tune sound, graphics and the way you drive.", 13, Color(0.45, 0.61, 0.70), HORIZONTAL_ALIGNMENT_LEFT))
    _add_slider_row(content, "ENGINE VOLUME", "engine_volume", 0.0, 1.0)
    _add_slider_row(content, "EFFECTS VOLUME", "sfx_volume", 0.0, 1.0)
    _add_slider_row(content, "MUSIC VOLUME", "music_volume", 0.0, 1.0)
    _add_slider_row(content, "STEERING SENSITIVITY", "steering_sensitivity", 0.45, 1.65)
    _add_slider_row(content, "TILT SENSITIVITY", "tilt_sensitivity", 0.45, 2.0)
    var choice_row := HBoxContainer.new()
    choice_row.add_theme_constant_override("separation", 22)
    var mode_box := VBoxContainer.new()
    mode_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mode_box.add_child(_label("CONTROL MODE", 13, Color(0.73, 0.82, 0.88), HORIZONTAL_ALIGNMENT_LEFT))
    var mode_option := OptionButton.new()
    mode_option.add_item("HYDRAULIC STEERING")
    mode_option.add_item("BUTTON STEERING")
    mode_option.add_item("TILT STEERING")
    mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var current_mode := str(SaveManager.setting("control_mode", "HYDRAULIC STEERING"))
    for i in range(mode_option.item_count):
        if mode_option.get_item_text(i) == current_mode:
            mode_option.select(i)
    mode_option.item_selected.connect(func(index: int):
        SaveManager.set_setting("control_mode", mode_option.get_item_text(index))
    )
    mode_box.add_child(mode_option)
    choice_row.add_child(mode_box)
    var quality_box := VBoxContainer.new()
    quality_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    quality_box.add_child(_label("GRAPHICS QUALITY", 13, Color(0.73, 0.82, 0.88), HORIZONTAL_ALIGNMENT_LEFT))
    var quality_option := OptionButton.new()
    quality_option.add_item("HIGH • SHADOWS + AA", 0)
    quality_option.add_item("LOW • PERFORMANCE", 1)
    quality_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    quality_option.select(1 if str(SaveManager.setting("graphics_quality", "high")) == "low" else 0)
    quality_option.item_selected.connect(func(index: int):
        SaveManager.set_setting("graphics_quality", "low" if index == 1 else "high")
        _apply_graphics_setting()
    )
    quality_box.add_child(quality_option)
    choice_row.add_child(quality_box)
    content.add_child(choice_row)
    var music_toggle := CheckButton.new()
    music_toggle.text = "MAIN MENU MUSIC"
    music_toggle.button_pressed = bool(SaveManager.setting("music_enabled", true))
    music_toggle.toggled.connect(func(value: bool):
        SaveManager.set_setting("music_enabled", value)
        AudioManager.apply_settings()
    )
    content.add_child(music_toggle)
    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 14)
    var reset := _menu_button("RESET DEFAULTS", false)
    reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    reset.pressed.connect(func():
        SaveManager.reset_settings()
        selected_car = int(SaveManager.setting("selected_car", 0))
        AudioManager.apply_settings()
        _apply_graphics_setting()
        _show_settings()
    )
    buttons.add_child(reset)
    var back := _menu_button("SAVE & RETURN", true)
    back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    back.pressed.connect(_show_main_menu)
    buttons.add_child(back)
    content.add_child(buttons)
    content.add_child(_label("Settings are saved locally on this device.", 11, Color(0.43, 0.55, 0.64), HORIZONTAL_ALIGNMENT_LEFT))

func _start_game(mode: String) -> void:
    get_tree().paused = false
    _free_race_manager()
    current_screen = mode
    AudioManager.set_tire_skid(false)
    _clear_ui()
    _clear_world()
    player_car = null
    menu_car = null
    if is_instance_valid(camera_rig):
        camera_rig.queue_free()
        camera_rig = null
    menu_camera.make_current()
    var track: Node3D = TrackScene.instantiate()
    track.name = "RaceTrack"
    world_root.add_child(track)
    var track_config: Dictionary = track.get("track_config")
    player_car = CarScene.instantiate() as CharacterBody3D
    player_car.set("preview_mode", false)
    player_car.call("configure", selected_car)
    player_car.position = track_config.get("start_position", Vector3(0, 0.02, 7.5))
    player_car.rotation.y = 0.0
    world_root.add_child(player_car)
    camera_rig = CameraController.new()
    camera_rig.call("set_target", player_car)
    world_root.add_child(camera_rig)
    menu_camera.current = false
    race_manager = RaceManager.new()
    race_manager.name = "RaceSession"
    add_child(race_manager)
    var target_distance := float(track_config.get("target_distance", 850.0))
    race_manager.call("setup", player_car, mode, target_distance)
    race_manager.connect("race_finished", _on_race_finished)
    hud = HudSceneScript.new()
    hud.name = "DrivingHUD"
    hud.call("setup", player_car, race_manager, mode)
    hud.connect("menu_requested", _show_main_menu)
    hud.connect("camera_requested", _toggle_camera)
    ui_root.add_child(hud)
    AudioManager.engine_active(true)
    if mode == "free_drive":
        player_car.set("input_enabled", true)

func _on_race_finished(results: Dictionary) -> void:
    if current_screen != "race":
        return
    _active_results = results.duplicate(true)
    current_screen = "results"
    AudioManager.engine_active(false)
    AudioManager.set_tire_skid(false)
    get_tree().paused = false
    _clear_ui()
    var results_ui = ResultsScreenScript.new()
    results_ui.name = "RaceResults"
    results_ui.call("setup", results)
    results_ui.connect("retry_requested", func(): _start_game("race"))
    results_ui.connect("menu_requested", _show_main_menu)
    ui_root.add_child(results_ui)

func _toggle_camera() -> void:
    if is_instance_valid(camera_rig):
        var cockpit := bool(camera_rig.call("toggle_camera"))
        if is_instance_valid(hud):
            var camera_node: Camera3D = camera_rig.get_node_or_null("RaceCamera") as Camera3D
            if is_instance_valid(camera_node) and cockpit:
                camera_node.fov = 76.0

func _free_race_manager() -> void:
    if is_instance_valid(race_manager):
        race_manager.queue_free()
    race_manager = null

func _rebuild_menu_stage() -> void:
    _clear_world()
    menu_camera.make_current()
    var builder = EnvironmentBuilder.new()
    builder.build_menu(world_root)
    menu_car = CarScene.instantiate() as Node3D
    menu_car.name = "GarageShowcaseVehicle"
    menu_car.set("preview_mode", true)
    menu_car.call("configure", selected_car)
    menu_car.position = Vector3(3.2, 0.0, -8.5)
    menu_car.rotation.y = PI
    world_root.add_child(menu_car)
    menu_camera.position = Vector3(7.2, 5.4, 18.0)
    menu_camera.look_at(Vector3(0.0, 1.0, -16.0), Vector3.UP)
    menu_camera.fov = 48.0
    menu_camera.make_current()

func _add_showcase_card() -> void:
    var spec: Dictionary = GarageController.car_spec(selected_car)
    var panel := _panel("ShowcaseInfo", Vector2(824, 478), Vector2(420, 190), Color(0.012, 0.027, 0.043, 0.82), 17)
    ui_root.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 5)
    panel.add_child(content)
    content.add_child(_label("CURRENT MACHINE  /  %02d" % (selected_car + 1), 11, Color(0.13, 0.82, 0.90), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label(str(spec["name"]), 24, Color.from_string(str(spec["color"]), Color.WHITE), HORIZONTAL_ALIGNMENT_LEFT))
    content.add_child(_label(str(spec["class"]), 11, Color(0.72, 0.80, 0.85), HORIZONTAL_ALIGNMENT_LEFT))
    var stats := HBoxContainer.new()
    stats.add_theme_constant_override("separation", 20)
    stats.add_child(_stat_block("TOP SPEED", "%d" % int(spec["max_speed"]), "KM/H"))
    stats.add_child(_stat_block("ACCELERATION", "%d" % int(float(spec["acceleration"])), "POWER"))
    stats.add_child(_stat_block("HANDLING", "%d" % int(float(spec["steering"]) * 50.0), "GRIP"))
    content.add_child(stats)

func _stat_block(caption: String, value: String, suffix: String) -> VBoxContainer:
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_child(_label(caption, 9, Color(0.45, 0.60, 0.69), HORIZONTAL_ALIGNMENT_LEFT))
    box.add_child(_label(value, 20, Color(0.94, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    box.add_child(_label(suffix, 9, Color(0.13, 0.82, 0.90), HORIZONTAL_ALIGNMENT_LEFT))
    return box

func _add_slider_row(parent: VBoxContainer, caption: String, key: String, min_value: float, max_value: float) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    var title := _label(caption, 12, Color(0.73, 0.82, 0.88), HORIZONTAL_ALIGNMENT_LEFT)
    title.custom_minimum_size = Vector2(205, 28)
    row.add_child(title)
    var slider := HSlider.new()
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = 0.01
    slider.value = clampf(float(SaveManager.setting(key, 0.8)), min_value, max_value)
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.custom_minimum_size = Vector2(300, 30)
    slider.value_changed.connect(func(value: float):
        SaveManager.set_setting(key, value)
        AudioManager.apply_settings()
    )
    row.add_child(slider)
    var value_label := _label("%d%%" % int(round((slider.value - min_value) / maxf(0.001, max_value - min_value) * 100.0)), 12, Color(0.12, 0.82, 0.90), HORIZONTAL_ALIGNMENT_RIGHT)
    value_label.custom_minimum_size = Vector2(44, 28)
    slider.value_changed.connect(func(value: float):
        value_label.text = "%d%%" % int(round((value - min_value) / maxf(0.001, max_value - min_value) * 100.0))
    )
    row.add_child(value_label)
    parent.add_child(row)

func _toggle_sound() -> void:
    var next_value := not bool(SaveManager.setting("sound_enabled", true))
    SaveManager.set_setting("sound_enabled", next_value)
    AudioManager.apply_settings()
    if is_instance_valid(_sound_button):
        _sound_button.text = _sound_button_text()

func _sound_button_text() -> String:
    return "SOUND  /  ON" if bool(SaveManager.setting("sound_enabled", true)) else "SOUND  /  OFF"

func _apply_graphics_setting() -> void:
    SettingsManager.apply_graphics(get_viewport(), str(SaveManager.setting("graphics_quality", "high")), world_light)

func _clear_ui() -> void:
    for child in ui_root.get_children():
        ui_root.remove_child(child)
        child.free()
    _sound_button = null

func _clear_world() -> void:
    menu_car = null
    for child in world_root.get_children():
        world_root.remove_child(child)
        child.free()

func _add_dark_overlay(alpha: float) -> void:
    var overlay := ColorRect.new()
    overlay.name = "InterfaceDarken"
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.color = Color(0.004, 0.010, 0.018, alpha)
    ui_root.add_child(overlay)

func _panel(panel_name: String, at: Vector2, dimensions: Vector2, color: Color, radius: int) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.name = panel_name
    panel.position = at
    panel.size = dimensions
    panel.add_theme_stylebox_override("panel", _stylebox(color, Color(0.07, 0.68, 0.78, 0.55), radius))
    return panel

func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var label := Label.new()
    label.text = text_value
    label.horizontal_alignment = alignment
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    label.clip_text = true
    return label

func _menu_button(text_value: String, accent: bool) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(0, 48)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
    button.add_theme_color_override("font_hover_color", Color(0.03, 0.07, 0.10))
    var normal := _stylebox(Color(0.035, 0.58, 0.66, 0.94) if accent else Color(0.027, 0.053, 0.074, 0.96), Color(0.07, 0.70, 0.80, 0.55), 10)
    var hover := _stylebox(Color(0.26, 0.86, 0.89) if accent else Color(0.08, 0.17, 0.21, 0.98), Color(0.44, 0.91, 0.95), 10)
    var pressed := _stylebox(Color(0.02, 0.39, 0.46), Color(0.44, 0.91, 0.95), 10)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    return button

func _stylebox(color: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 18.0
    style.content_margin_right = 18.0
    style.content_margin_top = 10.0
    style.content_margin_bottom = 10.0
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
    style.shadow_size = 6
    return style
