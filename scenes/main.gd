extends Control


@export var info: Label


func _ready() -> void:
	if OS.has_feature("mobile"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _process(_delta: float) -> void:
	if Client.is_server_connected:
		info.text = "Connected -> %s:%d" % [Client.discovered_servers[0].ip, Client.discovered_servers[0].port]
	else:
		info.text = "Unconnected..."
