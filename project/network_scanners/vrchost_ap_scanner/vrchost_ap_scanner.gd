# Copyright © 2017, 2018 Michael Goldener <mg@wasted.ch>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

extends Node

var mAccessPoints = []
var mUDP = PacketPeerUDP.new()

func _init():
	add_user_signal("service_discovered")

func _ready():
	if mUDP.listen(44000) != 0:
		rcos.log_error(self, "Unable to listen on UDP port 44000")
	else:
		get_node("read_packets_timer").connect("timeout", self, "_read_packets")
		get_node("read_packets_timer").start()

func _read_packets():
	while mUDP.get_available_packet_count() > 0:
		_process_udp_datagram()

func _process_udp_datagram():
	var data = mUDP.get_packet()
	var addr = mUDP.get_packet_ip()
	var port = mUDP.get_packet_port()
	var ap_string = "udp!"+addr+"!"+str(port)
	var msg = data.get_string_from_ascii()
	if mAccessPoints.has(ap_string):
		if !msg.to_lower().begins_with("#service"):
			return
		var service_name = "default"
		var service_host = "Unknown"
		var service_desc = "No description"
		var service_icon = null
		var lines = msg.split("\n")
		for line in lines:
			var name = rlib.hd(line)
			var value = rlib.tl(line)
			if name == "" || value == "":
				continue
			if name == "host:":
				service_host = value
				#prints("found host:", service_host)
			elif name == "desc:":
				service_desc = value
				#prints("found desc:", service_desc)
			elif name == "icon:":
				service_icon = _decode_icon(value)
				if service_icon == null:
					rcos.log_error(self, "unable to decode icon")
					continue
				#prints("found icon:", icon)
		var url = "vrc://"+addr+":"+port
		var desc = rlib.join_array([
			service_desc,
			"VrcHost Access Point",
			url
		], "\n")
		var service_info = {
			"url": url,
			"host": service_name,
			"name": service_desc,
			"desc": desc,
			"icon": service_icon
		}
		emit_signal("service_discovered", service_info)
	else:
		if !msg.to_lower().begins_with("#vrchost-ap.hb"):
			return
		var msg_txt = "#service_info_request".to_ascii()
		msg_txt.append(0)
		var msg_bin = RawArray()
		msg_bin.append(0)
		msg_bin.append(1)
		_send_packet(msg_txt, addr, port)
		_send_packet(msg_bin, addr, port)
		mAccessPoints.push_back(ap_string)

func _send_packet(data, addr, port):
	mUDP.set_send_address(addr, port)
	mUDP.put_packet(data)

func _decode_icon(string):
	var data = rlib.base64_decode(string)
	if data == null:
		return null
	var file = File.new()
	file.open("user://tmpdata.png", file.WRITE)
	file.store_buffer(data)
	file.close()
	var res = load("user://tmpdata.png")
	if res == null:
		return null
	if typeof(res) != TYPE_OBJECT:
		return null
	if res.get_type() != "ImageTexture":
		return null
	return res
#	var img = Image(40, 40, false, Image.FORMAT_GRAYSCALE_ALPHA)
#	var p = 0
#	for c in data:
#		for b in range(0, 8):
#			var x = p % 40
#			var y = (p-x) / 40
#			var color = Color(1, 1, 1, 1)
#			if (c & 128>>b) > 0:
#				color = Color(1, 1, 1, 0)
#			img.put_pixel(x, y, color)
#			p += 1
#	var tex = ImageTexture.new()
#	tex.create_from_image(img, 0)
#	return tex
