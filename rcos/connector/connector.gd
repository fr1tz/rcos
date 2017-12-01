extends Node

var gui = null

var mTaskId = -1
var mInterfaces = null
var mUDP = PacketPeerUDP.new()

func _ready():
	mTaskId = rcos.add_task()
	var task_name = "Connector"
	var task_icon = get_node("icon").get_texture()
	var task_canvas = get_node("canvas")
	var task_ops = null
	rcos.set_task_name(mTaskId, task_name)
	rcos.set_task_icon(mTaskId, task_icon)
	rcos.set_task_canvas(mTaskId, task_canvas)
	rcos.set_task_ops(mTaskId, task_ops)
	mInterfaces = get_node("remote_interfaces")
	gui = get_node("canvas/connector_gui")
	if mUDP.listen(44000) != 0:
		rcos.log_error(self, "Unable to listen on UDP port 44000")
	else:
		get_node("read_packets_timer").connect("timeout", self, "_read_packets")

func _read_packets():
	while mUDP.get_available_packet_count() > 0:
		_process_udp_datagram()

func _process_udp_datagram():
	var data = mUDP.get_packet()
	var addr = mUDP.get_packet_ip()
	var port = mUDP.get_packet_port()
	var interface_name = "udp!"+addr+"!"+str(port)
	var interface = mInterfaces.get_node(interface_name)
	if interface == null:
		var string = data.get_string_from_ascii()
		#print("connector: _process_udp_datagram(): ", string, "\n")
		if string.to_lower().begins_with("#vrchost-ap.hb"):
			interface = rlib.instance_scene("res://rcos/connector/interfaces/vrchost-ap.tscn")
			interface.set_name(interface_name)
			interface.init(self, addr, port)
			mInterfaces.add_child(interface)
	if interface:
		interface.process_packet(data)

func send_packet(data, addr, port):
	mUDP.set_send_address(addr, port)
	mUDP.put_packet(data)
