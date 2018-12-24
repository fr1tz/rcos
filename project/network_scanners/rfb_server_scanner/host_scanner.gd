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

var mPackedRfbPortTester = null

func _init():
	add_user_signal("service_discovered")

func _ready():
	mPackedRfbPortTester = load("res://network_scanners/rfb_server_scanner/rfb_port_tester.tscn")

func _test_finished(result, port_tester):
	var host = port_tester.get_address()
	var port = port_tester.get_port()
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
	var port_tester = mPackedRfbPortTester.instance()
	add_child(port_tester)
	port_tester.connect("test_finished", self, "_test_finished", [port_tester])
	port_tester.test(host, port)

func scan_host(addr):
	set_name("host_scanner ["+addr+"]")
	var port_tester = mPackedRfbPortTester.instance()
	add_child(port_tester)
	port_tester.connect("test_finished", self, "_test_finished", [port_tester])
	port_tester.test(addr, 5900)
