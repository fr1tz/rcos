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

var mServers = []
var mUDP = PacketPeerUDP.new()

func _init():
	add_user_signal("service_discovered")

func _ready():
	if mUDP.listen(44001) != 0:
		rcos.log_error(self, "Unable to listen on UDP port 44001")
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
	var announce = data.get_string_from_ascii()
	if !announce.to_lower().begins_with("#vjoy-server"):
		return
	var server_string = "udp!"+addr+"!"+str(port)
	if !mServers.has(server_string):
		mServers.push_back(server_string)
		_process_announce(addr, port, announce)

func _process_announce(source_address, source_port, announce):
	#prints("announce: ", announce)
	rcos.log_debug(self, ["process_announce()", announce])
	var words = announce.split(" ", false)
	if words.size() != 4:
		return
	var protocol_version = int(words[1])
	var server_tcp_port = int(words[2])
	var url = "vjoy://"+source_address+":"+str(server_tcp_port)
	var host = source_address
	var name = "vJoy Server"
	var icon = load("res://vjoy/vjoy_client/graphics/icon.png")
	var desc = rlib.join_array([
		"vJoy Server",
		source_address+":"+str(server_tcp_port),
		"Protocol version: "+str(protocol_version),
		"URL: "+url
	], "\n")
	var service_info = {
		"url": url,
		"host": host,
		"name": name,
		"desc": desc,
		"icon": icon
	}
	emit_signal("service_discovered", service_info)
