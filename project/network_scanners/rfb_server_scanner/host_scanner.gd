# Copyright © 2018 Michael Goldener <mg@wasted.ch>
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

var mPackedRfbServerTester = null

func _init():
	add_user_signal("service_discovered")

func _ready():
	mPackedRfbServerTester = load("res://network_scanners/rfb_server_scanner/rfb_server_tester.tscn")

func _test_finished(result, server_tester):
	var host = server_tester.get_address()
	var port = server_tester.get_port()
	if result != null:
		var url = "rfb://"+host+":"+str(port-5900)
		var name = "RFB Server :"+str(port-5900)
		var icon = load("res://icons/services/32/rfb.png")
		var desc = "RFB Server\nProtocol Version: "+result+"\nURL: " + url
		var service_info = {
			"url": url,
			"name": name,
			"desc": desc,
			"icon": icon
		}
		emit_signal("service_discovered", service_info)
	port += 1
	if port > 5910:
		queue_free()
		return
	var server_tester = mPackedRfbServerTester.instance()
	add_child(server_tester)
	server_tester.connect("test_finished", self, "_test_finished", [server_tester])
	server_tester.test(host, port)

func scan_host(addr):
	set_name("host_scanner [addr "+addr+"]")
	var server_tester = mPackedRfbServerTester.instance()
	add_child(server_tester)
	server_tester.connect("test_finished", self, "_test_finished", [server_tester])
	server_tester.test(addr, 5900)
