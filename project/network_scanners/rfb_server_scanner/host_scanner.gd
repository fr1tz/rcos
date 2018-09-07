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

var mHostAddress = ""
var mPortTester = null

func _init():
	add_user_signal("service_discovered")

func _port_open(port):
	var url = "rfb://"+mHostAddress+":"+str(port-5900)
	var host = mHostAddress
	var name = "RFB Server :"+str(port-5900)
	var icon = load("res://network_scanners/rfb_server_scanner/icon.png")
	var desc = rlib.join_array([
		"RFB Server",
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
	mPortTester.test(mHostAddress, port+1)
#	if port > 5900:
#		_add_port_tester(port + 1)

func _port_closed(port):
	mPortTester.test(mHostAddress, port+1)
#	if port > 5900:
#		queue_free()

func scan_host(addr):
	mHostAddress = addr
	mPortTester = rlib.instance_scene("res://network_scanners/rfb_server_scanner/tcp_port_tester.tscn")
	add_child(mPortTester)
	mPortTester.connect("port_open", self, "_port_open")
	mPortTester.connect("port_closed", self, "_port_closed")
	mPortTester.test(mHostAddress, 5900)
