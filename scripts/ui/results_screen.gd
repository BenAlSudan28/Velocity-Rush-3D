extends Control

signal retry_requested
signal menu_requested

func setup(results: Dictionary) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.005, 0.011, 0.02, 0.84)
    add_child(shade)
    var card := PanelContainer.new()
    card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    card.offset_left = -345
    card.offset_right = 345
    card.offset_top = -300
    card.offset_bottom = 300
    card.add_theme_stylebox_override("panel", _stylebox(Color(0.023, 0.043, 0.063, 0.98), Color(0.07, 0.79, 0.88), 22))
    add_child(card)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    content.alignment = BoxContainer.ALIGNMENT_CENTER
    card.add_child(content)
    content.add_child(_label("RACE COMPLETE", 35, Color(0.95, 0.98, 1.0)))
    content.add_child(_label("SOLO SPRINT  •  VERIFIED SESSION DATA", 12, Color(0.34, 0.82, 0.90)))
    var divider := HSeparator.new()
    content.add_child(divider)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 25)
    grid.add_theme_constant_override("v_separation", 8)
    grid.add_child(_label("FINAL TIME", 13, Color(0.58, 0.69, 0.77)))
    grid.add_child(_label(_format_time(float(results.get("duration", 0.0))), 22, Color(0.98, 0.77, 0.35)))
    grid.add_child(_label("DISTANCE", 13, Color(0.58, 0.69, 0.77)))
    grid.add_child(_label("%d m" % int(results.get("distance", 0.0)), 22, Color(0.96, 0.98, 1.0)))
    grid.add_child(_label("TOP SPEED", 13, Color(0.58, 0.69, 0.77)))
    grid.add_child(_label("%d km/h" % int(results.get("max_speed", 0.0)), 22, Color(0.96, 0.98, 1.0)))
    grid.add_child(_label("IMPACTS", 13, Color(0.58, 0.69, 0.77)))
    grid.add_child(_label(str(int(results.get("collisions", 0))), 22, Color(0.96, 0.98, 1.0)))
    grid.add_child(_label("SCORE", 13, Color(0.58, 0.69, 0.77)))
    grid.add_child(_label("%07d" % int(results.get("score", 0)), 24, Color(0.12, 0.84, 0.90)))
    content.add_child(grid)
    var note := _label("Score = distance × 8 + pace bonus − 250 per impact.", 11, Color(0.52, 0.63, 0.71))
    content.add_child(note)
    var retry := _button("RETRY SPRINT", true)
    retry.pressed.connect(func(): retry_requested.emit())
    content.add_child(retry)
    var menu := _button("MAIN MENU", false)
    menu.pressed.connect(func(): menu_requested.emit())
    content.add_child(menu)

func _format_time(value: float) -> String:
    return "%02d:%04.1f" % [int(value / 60.0), fmod(value, 60.0)]

func _label(text_value: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text_value
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label

func _button(text_value: String, accent: bool) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(280, 45)
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", Color.WHITE)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.03, 0.60, 0.68, 0.96) if accent else Color(0.04, 0.07, 0.10, 0.96)
    normal.border_color = Color(0.08, 0.78, 0.87, 0.8)
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(10)
    button.add_theme_stylebox_override("normal", normal)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(0.15, 0.78, 0.84) if accent else Color(0.08, 0.15, 0.19)
    button.add_theme_stylebox_override("hover", hover)
    return button

func _stylebox(color: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 24.0
    style.content_margin_right = 24.0
    style.content_margin_top = 18.0
    style.content_margin_bottom = 18.0
    return style
