extends Node

# 网络相关配置
const BROADCAST_PORT := 47126 # 与PC端广播端口一致

# 网络对象
var udp := PacketPeerUDP.new()
var tcp := StreamPeerTCP.new()

# 状态变量
var discovered_servers: Array[Dictionary] = []
var is_server_connected := false

# 信号 - 用于通知UI更新
signal server_discovered(servers)
signal connection_status_changed(connected, message)

func _ready():
	# 初始化UDP用于监听PC端的广播（仅监听，不发送广播）
	var err = udp.bind(BROADCAST_PORT)
	if err != OK:
		connection_status_changed.emit(false, "无法绑定UDP端口: %d" % BROADCAST_PORT)
		return
	
	connection_status_changed.emit(false, "正在监听局域网中的服务器...")

func _process(_delta: float):
	# 持续检查是否有PC端发送的广播包
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		
		var message = packet.get_string_from_utf8()
		# 验证是否是PC服务器的广播消息（格式：AnotherTouchboardServer;IP;端口）
		if message.begins_with("a-touchboard-server;"):
			var parts = message.split(";")
			if parts.size() == 3:
				var server_info = {
					ip = parts[1],
					port = parts[2].to_int()
				}
				
				# 避免重复添加同一服务器
				var exists = false
				for s in discovered_servers:
					if s.ip == server_info.ip and s.port == server_info.port:
						exists = true
						break
				
				if not exists:
					discovered_servers.append(server_info)
					connection_status_changed.emit(false,
								"发现服务器: %s:%d" % [server_info.ip, server_info.port])
					server_discovered.emit(discovered_servers[0])

# 连接到指定服务器
func connect_to_server(server_ip: String, server_port: int):
	if is_server_connected:
		disconnect_from_server()
	
	var err = tcp.connect_to_host(server_ip, server_port)
	if err == OK:
		connection_status_changed.emit(false,
					"正在连接到 %s:%d..." % [server_ip, server_port])
		# 启动协程等待连接结果
		start_connection_checker(server_ip, server_port)
	else:
		connection_status_changed.emit(false, "连接失败: 无法解析地址")

# 检查连接状态的协程
func start_connection_checker(server_ip: String, server_port: int):
	var timeout = 50.0 # 50秒超时
	var elapsed = 0.0
	
	while elapsed < timeout:
		tcp.poll()
		var status = tcp.get_status()
		
		if status == StreamPeerTCP.STATUS_CONNECTING:
			print_debug("正在连接中...")
		elif status == StreamPeerTCP.STATUS_CONNECTED:
			is_server_connected = true
			connection_status_changed.emit(true,
						"已连接到 %s:%d" % [server_ip, server_port])
			return
		elif status == StreamPeerTCP.STATUS_ERROR:
			connection_status_changed.emit(false, "连接错误")
			discovered_servers.clear()
			return
		
		elapsed += 1
		await get_tree().create_timer(1).timeout
	
	# 超时处理
	tcp.disconnect_from_host()
	connection_status_changed.emit(false, "连接超时")
	discovered_servers.clear()

# 断开连接
func disconnect_from_server():
	if is_server_connected:
		tcp.disconnect_from_host()
		is_server_connected = false
		connection_status_changed.emit(false, "已断开连接")
		discovered_servers.clear()

# 发送按键信息（格式：KeyCode,IsPressed）
func send_key_event(key_code: String, is_pressed: bool):
	if not is_server_connected:
		connection_status_changed.emit(false, "未连接，无法发送按键")
		return
	
	var message: String = "%s,%d" % [key_code, 1 if is_pressed else 0]
	tcp.put_data(message.to_utf8_buffer())

# 发送心跳包
func send_heartbeat():
	if is_server_connected:
		tcp.put_data("<3".to_utf8_buffer())

func _exit_tree():
	disconnect_from_server()
	udp.close()


func _on_server_discovered(server: Dictionary) -> void:
	print_debug("Discovered servers: %s" % [str(server)])
	connect_to_server(server.ip, server.port)

func _on_connection_status_changed(connected: Variant, message: Variant) -> void:
	print_debug("Connection status changed: %s - %s" % [str(connected), str(message)])


func _on_poll_timer_timeout() -> void:
	if is_server_connected:
		tcp.poll()
		if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			disconnect_from_server()


const KEYCODE_DICT: Dictionary[Key, int] = {
	# 功能键
	KEY_ENTER: 13,
	KEY_BACKSPACE: 8,
	KEY_TAB: 9,
	KEY_SHIFT: 16,
	KEY_CTRL: 17,
	KEY_ALT: 18,
	KEY_CAPSLOCK: 20,
	KEY_ESCAPE: 27,
	KEY_META: 91,

	# 符号键
	KEY_COMMA: 188,
	KEY_PERIOD: 110,
	KEY_SLASH: 191,
	KEY_BRACELEFT: 219,
	KEY_BRACERIGHT: 221,
	KEY_SEMICOLON: 186,
	KEY_APOSTROPHE: 222,
	KEY_MINUS: 189,
	KEY_EQUAL: 187,
	KEY_BACKSLASH: 220,
}


static func get_keycode(key: Key) -> int:
	if key in KEYCODE_DICT:
		return KEYCODE_DICT[key]
	return int(key)


func press_key(key_code: int) -> void:
	print_debug("Press key: %d <%s>" % [get_keycode(key_code), OS.get_keycode_string(key_code)])
	Client.send_key_event(str(get_keycode(key_code)), true)
	$Typing.play()

func release_key(key_code: int) -> void:
	print_debug("Release key: %d <%s>" % [get_keycode(key_code), OS.get_keycode_string(key_code)])
	Client.send_key_event(str(get_keycode(key_code)), false)
	$Releasing.play()


func _on_heart_beat_timeout() -> void:
	Client.send_heartbeat()
