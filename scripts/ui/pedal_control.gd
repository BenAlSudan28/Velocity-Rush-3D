extends Button

signal pressure_changed(value: float)

@export_range(0.0, 1.0, 0.05) var strength: float = 1.0
var _held := false

func _ready() -> void:
    focus_mode = Control.FOCUS_NONE
    action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    button_down.connect(_press)
    button_up.connect(_release)
    mouse_exited.connect(_release_if_needed)

func _press() -> void:
    _held = true
    pressure_changed.emit(strength)

func _release() -> void:
    if _held:
        _held = false
        pressure_changed.emit(0.0)

func _release_if_needed() -> void:
    if _held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _release()

func cancel_pressure() -> void:
    _release()
