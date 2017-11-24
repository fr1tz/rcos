extends Node

const NET_INTERFACE_STATE_CLOSED = 0
const NET_INTERFACE_STATE_OPENING = 1
const NET_INTERFACE_STATE_OPEN = 2

var mTaskId = -1
var mMainGui = null
var mStatusScreen = null
var mVariables = Dictionary()
var mVrcHostApi = null
var mNetInterface = {
	state = NET_INTERFACE_STATE_CLOSED,
	udp = null,
	udp_port = 0,
	tcp_server = null,
	tcp_server_port = 0,
	connections = null,
	connections_group = "",
	remote_addr = null,
	remote_port = 0
}

func _init():
	_log_debug("_init()")
	add_user_signal("vrc_displayed")
	add_user_signal("vrc_concealed")
	add_user_signal("new_log_entry3")
	add_user_signal("var_changed1")
	add_user_signal("var_changed2")
	add_user_signal("var_changed3")
	mVrcHostApi = preload("vrc_host_api.gd").new(self)

func _ready():
	_log_debug("_ready()")
	get_node("network_input_timer").connect("timeout", self, "_process_network_io")
	get_node("main_canvas").connect("display", self, "_on_displayed")
	get_node("main_canvas").connect("conceal", self, "_on_concealed")
	mTaskId = rcos.add_task()
	var task_name = "VRC Host"
	var task_icon = get_node("icon").get_texture()
	var task_canvas = get_node("main_canvas")
	var task_ops = [
		[ "kill", funcref(self, "kill") ]
	]
	task_icon.set_meta("rotate", true)
	rcos.set_task_name(mTaskId, task_name)
	rcos.set_task_icon(mTaskId, task_icon)
	rcos.set_task_canvas(mTaskId, task_canvas)
	rcos.set_task_ops(mTaskId, task_ops)
	mNetInterface.connections = get_node("connections")
	mNetInterface.connections_group = "vrc_host_"+str(get_instance_ID())+"connections_group"
	mMainGui = get_node("main_canvas/main_gui")
	mStatusScreen = get_node("main_canvas/main_gui/status_screen")
	set_variable("VRCHOST/VERSION", "0.0.0")
	set_variable("VRCHOST/OS", "RCOS/"+OS.get_name())
	set_variable("VRCHOST/MODEL", OS.get_model_name())
	set_variable("VRCHOST/LOCALE", OS.get_locale())
	set_variable("VRCHOST/SETUP_PROGRESS", "0")
	_log_notice("Ready")

func _on_displayed():
	#print("_on_displayed")
	rcos.log_debug(self, "_on_displayed()")
	get_node("network_input_timer").set_wait_time(0.05)
	#mMainGui.get_node("window").mCanvas.update_worlds()

func _on_concealed():
	#print("_on_concealed")
	rcos.log_debug(self, "_on_concealed()")
	get_node("network_input_timer").set_wait_time(0.1)

func _process_network_io():
	if mNetInterface.state == NET_INTERFACE_STATE_CLOSED:
		return
	get_tree().call_group(0, mNetInterface.connections_group, "_process_network_io")
	if mNetInterface.udp.get_available_packet_count() > 0:
		_read_packet()
	if mNetInterface.tcp_server.is_connection_available():
		var stream = mNetInterface.tcp_server.take_connection()
		var addr = stream.get_connected_host()
		var port = stream.get_connected_port()
		_log_notice("New tcp connection from "+addr+":"+str(port)) 
		var conn = load("res://vrc_host/connection.tscn").instance()
		conn.initialize(self, mVrcHostApi, stream)
		conn.add_to_group(mNetInterface.connections_group)
		mNetInterface.connections.add_child(conn)
		mStatusScreen.set_connection_count(mNetInterface.connections.get_child_count())
		_log_notice("Accepted TCP connection from\n\t" + addr + ":" + str(port))
		if mNetInterface.state == NET_INTERFACE_STATE_OPENING:
			mNetInterface.state = NET_INTERFACE_STATE_OPEN

func _log_debug(content):
	add_log_entry(self, "debug", content)

func _log_notice(content):
	add_log_entry(self, "notice", content)

func _log_error(content):
	add_log_entry(self, "error", content)

func _on_vrc_canvas_displayed(canvas):
	emit_signal("vrc_displayed", canvas.get_child(0))

func _on_vrc_canvas_concealed(canvas):
	emit_signal("vrc_concealed", canvas.get_child(0))

func _read_packet():
	_log_debug(["_read_packet()"])
	var data = mNetInterface.udp.get_packet()
	var addr = mNetInterface.udp.get_packet_ip()
	var port = mNetInterface.udp.get_packet_port()
	var string = data.get_string_from_ascii()

func add_log_entry(source_node, level, content):
	if typeof(source_node) != TYPE_OBJECT:
		return
	if !(source_node extends Node):
		return
	if level != "debug" && level != "notice" && level != "error":
		return
	emit_signal("new_log_entry3", source_node, level, content)
	if mStatusScreen != null && !mStatusScreen.is_hidden() && level == "error":
		mStatusScreen.add_error()
	#prints("%", level, source_node, content)
	if level == "debug":
		rcos.log_debug(source_node, content)
	elif level == "notice":
		rcos.log_notice(source_node, content)
	elif level == "error":
		rcos.log_error(source_node, content)
	return ""

func add_module(var_name):
	_log_debug(["add_module()", var_name])
	var module_data = get_variable(var_name)
	if module_data == null:
		return var_name+": no such variable"
	var file = File.new()
	file.open("user://tmpdata.xml", file.WRITE)
	file.store_string(module_data)
	file.close()
	var module_packed = load("user://tmpdata.xml")
	Directory.new().remove("user://tmpdata.xml")
	if module_packed == null:
		_log_debug("Loading module data failed")
		return "Loading VRC data failed"
	var module = module_packed.instance()
	if module == null:
		_log_debug("Failed to instance module")
		return "failed to instance module"
	module.set_meta("vrc_host_api", mVrcHostApi)
	get_node("modules").add_child(module)
	return ""

func add_vrc(var_name, vrc_name):
	_log_debug(["add_vrc()", var_name, vrc_name])
	var vrc_data = get_variable(var_name)
	if vrc_data == null:
		return var_name+": no such variable"
	var file = File.new()
	file.open("user://tmpdata.xml", file.WRITE)
	file.store_string(vrc_data)
	file.close()
	var vrc_packed = load("user://tmpdata.xml")
	Directory.new().remove("user://tmpdata.xml")
	if vrc_packed == null:
		_log_debug("	Loading VRC data failed")
		return "Loading VRC data failed"
	var vrc = vrc_packed.instance()
	if vrc == null:
		_log_debug("	Failed to instance VRC")
		return "Failed to instance VRC"
	vrc.set_meta("vrc_host_api", mVrcHostApi)
	var vrc_canvas = preload("res://rcos/lib/canvas.tscn").instance()
	var vrc_canvas_size = vrc.get_end()
	if vrc_canvas_size.x > vrc_canvas_size.y:
		vrc_canvas_size = Vector2(vrc_canvas_size.y, vrc_canvas_size.x)
	var canvas_rect = Rect2(Vector2(0,0), vrc_canvas_size)
	vrc_canvas.set_name(vrc_name+"_canvas")
	vrc_canvas.set_rect(canvas_rect)
	vrc_canvas.connect("display", self, "_on_vrc_canvas_displayed", [vrc_canvas])
	vrc_canvas.connect("conceal", self, "_on_vrc_canvas_concealed", [vrc_canvas])
	vrc_canvas.add_child(vrc)
	get_node("vrc_instances").add_child(vrc_canvas)
	return ""

func connect_to_interface(addr, port):
	_log_debug(["connect_to_interface()", addr, port])
	if mNetInterface.state != NET_INTERFACE_STATE_CLOSED:
		mNetInterface.udp.close()
		mNetInterface.tcp_server.stop()
		for conn in mNetInterface.connections:
			conn.disconnect()
	mNetInterface.tcp_server = TCP_Server.new()
	mNetInterface.udp = PacketPeerUDP.new()
	mNetInterface.udp.set_send_address(addr, port)
	mNetInterface.remote_addr = addr
	mNetInterface.remote_port = port
	mNetInterface.tcp_server_port = rcos.listen(mNetInterface.tcp_server, rcos.PORT_TYPE_TCP)
	mNetInterface.udp_port = rcos.listen(mNetInterface.udp, rcos.PORT_TYPE_UDP)
	mNetInterface.state = NET_INTERFACE_STATE_OPENING
	_log_notice("Listening on TCP port " + str(mNetInterface.tcp_server_port))
	_log_notice("Listening on UDP port " + str(mNetInterface.udp_port))
	_log_notice("Sending service request to\n\t" + str(addr) + ":" + str(port))
	var msg = rlib.join_array([
		"service_request",
		mNetInterface.tcp_server_port,
		mNetInterface.udp_port,
		"default"
	], " ")
	mNetInterface.udp.put_packet(msg.to_ascii())

func exit():
	_log_debug(["exit()"])
	#mWindow.queue_free()
	#mButtons.queue_free()
	queue_free()

func get_connections():
	return mNetInterface.connections.get_children()

func get_node_from_path(path_string):
	var self_path = str(get_path())
	if !path_string.begins_with(self_path):
		return null
	var relative_path_string = path_string.right(self_path.length())
	return get_node(relative_path_string)

func get_path_from_node(node):
	if node == self:
		return "vrchost"
	if !node.is_inside_tree():
		return null
	if !is_a_parent_of(node):
		return null
	var node_path = str(node.get_path())
	var self_path = str(get_path())
	return "vrchost"+node_path.right(self_path.length())

func get_variable(name):
	_log_debug(["get_variable()", name])
	name = name.to_upper()
	if !mVariables.has(name):
		return ""
	return str(mVariables[name])

func get_variables():
	_log_debug(["get_variables()"])
	return mVariables.keys()

func kill():
	_log_debug(["kill()"])
	rcos.remove_task(mTaskId)
	queue_free()

func parse_cmdline(input):
	var cmdline = {
		"raw": input,
		"command": "",
		"attributes": {},
		"arguments": [],
		"arguments_raw": ""
	}
	cmdline.command = rlib.hd(input)
	if cmdline.command == "":
		return null
	input = rlib.tl(input)
	var quote = "'"
	var backslash = "\\"
	while(input.begins_with("--")):
		if input.begins_with("-- "):
			input = rlib.tl(input)
			break
		input = input.right(2)
		var idx = rlib.hd(input).find("=")
		if idx == -1:
			var name = rlib.hd(input)
			var value = ""
			cmdline.attributes[name] = value
			input = rlib.tl(input)
		else:
			var name = input.left(idx)
			input = input.right(idx+1)
			if input.begins_with(quote):
				var opening_quote_idx = 0
				var closing_quote_idx = input.find(quote, opening_quote_idx+1)
				while closing_quote_idx != -1:
					if input[closing_quote_idx-1] != backslash:
						break
					closing_quote_idx = input.find(quote, closing_quote_idx+1)
				if closing_quote_idx == -1:
					return null
				var arg_start_idx = opening_quote_idx+1
				var arg_end_idx = closing_quote_idx-1
				var arg_length = arg_end_idx - arg_start_idx + 1
				var arg = input.substr(arg_start_idx, arg_length)
				arg = arg.replace(backslash+quote, quote)
				cmdline.attributes[name] = arg
				input = input.right(closing_quote_idx+1)
				while input.begins_with(" "):
					input.erase(0, 1)
			else:
				var value = rlib.hd(input)
				cmdline.attributes[name] = value
				input = rlib.tl(input)
	cmdline.arguments_raw = input
	while(input != ""):
		if input.begins_with(quote):
			var opening_quote_idx = 0
			var closing_quote_idx = input.find(quote, opening_quote_idx+1)
			while closing_quote_idx != -1:
				if input[closing_quote_idx-1] != backslash:
					break
				closing_quote_idx = input.find(quote, closing_quote_idx+1)
			if closing_quote_idx == -1:
				return null
			var arg_start_idx = opening_quote_idx+1
			var arg_end_idx = closing_quote_idx-1
			var arg_length = arg_end_idx - arg_start_idx + 1
			var arg = input.substr(arg_start_idx, arg_length)
			arg = arg.replace(backslash+quote, quote)
			cmdline.arguments.append(arg)
			input = input.right(closing_quote_idx+1)
			while input.begins_with(" "):
				input.erase(0, 1)
		else:
			cmdline.arguments.append(rlib.hd(input))
			input = rlib.tl(input)
	return cmdline

func remove_vrc(vrc_name):
	_log_warning(self, "remove_vrc() not yet implemented")
	return "Not yet implemented"

func send(data, to, from = null):
	for conn in mNetInterface.connections.get_children():
		if conn.get_remote_address_string() == to:
			conn.send_data(data)
			return ""
	return "connection "+to+" not found"

func set_icon(texture):
	_log_debug(["set_icon()", texture])
	rcos.set_task_icon(mTaskId, texture)
	return ""

func set_variable(name, value):
	_log_debug(["set_variable()", name, value])
	name = name.to_upper()
	if name == "VRCHOST/SETUP_PROGRESS":
		mMainGui.get_node("status_screen").set_setup_progress(float(value))
		return
	var old_value = ""
	if mVariables.has(name):
		if mVariables[name] == value:
			return
		old_value = mVariables[name]
	mVariables[name] = value
	emit_signal("var_changed1", name)
	emit_signal("var_changed2", name, value)
	emit_signal("var_changed3", name, value, old_value)
	return ""

func show_vrc(vrc_name, fullscreen):
	_log_debug(["show_vrc()", vrc_name, fullscreen])
	for canvas in get_node("vrc_instances").get_children():
		if canvas.get_name() == vrc_name+"_canvas":
			if fullscreen:
				rcos.push_canvas(canvas)
			else:
				#rcos.set_task_canvas(mTaskId, canvas)
				mMainGui.get_node("window").show_canvas(canvas)
			mStatusScreen.hide()
			return ""
	return "VRC not found"


###############################################################################

#func extract_vrc_info(vrc_packed):
#	_log_debug(["extract_vrc_info()", vrc_packed])
#	var vrc_info = {
#		"root_node_type": null,
#		"width": null,
#		"height": null
#	}
#	var state = vrc_packed.get_state()
#	if state.get_node_count() == 0:
#		return vrc_info
#	vrc_info.root_node_type = state.get_node_type(0)
#	for i in range(0, state.get_node_property_count(0)):
#		var prop_name = state.get_node_property_name(0, i)
#		var prop_value = state.get_node_property_value(0, i)
#		if prop_name == "margin/right":
#			vrc_info.width = int(prop_value)
#		elif prop_name == "margin/bottom":
#			vrc_info.height = int(prop_value)
#	return vrc_info