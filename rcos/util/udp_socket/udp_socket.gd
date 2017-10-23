
extends Node

export(bool) var mReadVariables = true
var mUDP = PacketPeerUDP.new()
var mPort = -1

func _init():
	add_user_signal("packet_sent", [{"name": "packet", "type": TYPE_DICTIONARY}])
	add_user_signal("packet_received", [{"name": "packet", "type": TYPE_DICTIONARY}])

func _fixed_process(delta):
	if !mUDP.is_listening():
		close()
		return
	if mUDP.get_available_packet_count() > 0:
		while mUDP.get_available_packet_count() > 0:
			var data = null
			if mReadVariables:
				data = mUDP.get_var()
			else:
				data = mUDP.get_packet()
			var addr = mUDP.get_packet_ip()
			var port = mUDP.get_packet_port()
			var packet = {
				"address": addr,
				"port": port,
				"data": data
			}
			#print("udp_socket: packet received: ", packet)
			emit_signal("packet_received", packet)
		# PacketPeerUDP workaround
		mUDP.close()
		mUDP = PacketPeerUDP.new()
		var error = mUDP.listen(mPort)
		if error != 0:
			print("udp_socket: PacketPeerUDP workaround failed:", error)
			close()
			return

func close():
	mPort = -1
	set_fixed_process(false)

func get_port():
	return mPort

func is_listening():
	return mUDP.is_listening()

func listen(port = 49152, port_range = 300, port_increment = 3):
	print("udp_socket: listen(): ", port, " ", port_range, " ", port_increment)
	mUDP.close()
	mUDP = PacketPeerUDP.new()
	mPort = -1
	for i in range(port, port+port_range+1, port_increment):
		var error = mUDP.listen(i)
		if error == 0:
			mPort = i
			set_fixed_process(true)
			return true
	return false

func send_packet(address, port, data, put_var = true):
	#print("udp_socket: send_packet() ", address, ":", port, " ", data)
	if !mUDP.is_listening():
		print("udp_socket: send_packet(): error")
		return false
	mUDP.set_send_address(address, port)
	if put_var:
		mUDP.put_var(data)
	else:
		mUDP.put_packet(data)
	var packet = {
		"address": address,
		"port": port,
		"data": data
	}
	emit_signal("packet_sent", packet)
	return true
