extends Button

signal pressure_changed(value: float)

@export_range(0.0, 1.0, 0.05) var strength: float = 1.0
var _held := false

func _ready() -> void:
    focus_mode = Control.FOCUS_NONE
    mouse_filter = Control.MOUSE_FILTER_STOP
    action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    button_down.connect(_press)
    button_up.connect(_release)
    # Keep the pedal active while a finger is held on it. Releasing outside the
    # button is handled by button_up; mouse_exited is unreliable on touchscreens.

func _press() -> void:
    _held = true
    pressure_changed.emit(strength)

func _release() -> void:
    if _held:
        _held = false
        pressure_changed.emit(0.0)

func cancel_pressure() -> void:
    _release()
