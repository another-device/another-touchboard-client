extends Button


@export var key_code: Key = KEY_UNKNOWN


func _ready() -> void:
	if key_code == KEY_UNKNOWN:
		var key_string = text.strip_edges().split(" ")[0]
		key_code = OS.find_keycode_from_string(key_string)
	text = " %s " % text


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
