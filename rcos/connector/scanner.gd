extends ReferenceFrame

var mUDP = PacketPeerUDP.new()

func _ready():
	if mUDP.listen(44000) != 0:
		print("connector: Unable to listen on port 44000")
	get_node("read_packets_timer").connect("timeout", self, "_read_packets")

func _read_packets():
	while mUDP.get_available_packet_count() > 0:
		_read_packet()

func _read_packet():
	var data = mUDP.get_packet()
	var addr = mUDP.get_packet_ip()
	var port = mUDP.get_packet_port()
	var string = data.get_string_from_ascii()
	#print("connector_app: _read_packet(): ", string, "\n")
	var info = _parse_announce_string(string)
	if info == null:
		print("connector_app: received invalid packet: ", string)
		return
	info.addr = addr
	if info.port == 0:
		info.port = port
	else:
		port = info.port
	update_interface_widget(addr, port, info)
	
func _parse_announce_string(string):
	#print("connector_app: _parse_announce_string(): ", string, "\n")
	var info = {
		addr = "",
		name = "",
		port = 0,
		type = "vrc"
	}
	if string.left(13) != "rcos_announce":
		return null
	string = string.right(13)
	var args = string.split(" ")
	while args.size() > 0:
		var arg = args[0]
		if arg == "":
			args.remove(0)
		elif arg.left(2) == "-p":
			if arg.length() > 2:
				info.port = int(arg.right(2))
				#print("found port: ", info.port)
				args.remove(0)
		elif arg.left(2) == "-t":
			if arg.length() > 2:
				info.type = arg.right(2)
				#print("found type: ", info.type)
				args.remove(0)
		else:
			break
	while args.size() > 0:
		var arg = args[0]
		if arg == "":
			arg = " "
		info.name = info.name + arg + " "
		args.remove(0)
	info.name = info.name.strip_edges()
	return info

func update_interface_widget(addr, port, info):
	var interfaces = get_node("interfaces_panel/interfaces_scroller/interfaces_list")
	var widget_name = addr + "_" + str(port)
	var widget = null
	if interfaces.has_node(widget_name):
		widget = interfaces.get_node(widget_name)
	else:
		widget = load("res://rcos/connector/interface_widget.tscn").instance()
		interfaces.add_child(widget)
		widget.set_name(widget_name)
	widget.update_info(info)
