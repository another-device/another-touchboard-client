extends Button

@export var key_code: Key = KEY_UNKNOWN

const TOGGLE_BUTTON_THEME: Theme = preload("res://themes/toggle_button.tres")

var real_toggle_mode: bool = false

func _ready() -> void:
	if key_code == KEY_UNKNOWN:
		var key_string = text.strip_edges().split(" ")[0]
		key_code = OS.find_keycode_from_string(key_string)

	if toggle_mode:
		real_toggle_mode = true
		theme = TOGGLE_BUTTON_THEME
	toggle_mode = true


func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Client.press_key(key_code)
	else:
		Client.release_key(key_code)


func _on_button_down() -> void:
	if toggle_mode:
		return
	Client.press_key(key_code)


func _on_button_up() -> void:
	if toggle_mode:
		return
	Client.release_key(key_code)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		print_debug("Touch event: %s" % [str(event)])
		if event.is_pressed():
			if real_toggle_mode:
				button_pressed = not button_pressed
				toggled.emit(button_pressed)
			else:
				button_pressed = true
				button_down.emit()
		else:
			if not real_toggle_mode:
				button_pressed = false
				button_up.emit()
