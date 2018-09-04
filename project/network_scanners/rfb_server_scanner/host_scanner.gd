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
var mPortTesters = {} # Port -> Port Tester

func _init():
	add_user_signal("service_discovered")

func _add_port_tester(port):
	var port_tester = rlib.instance_scene("res://network_scanners/rfb_server_scanner/tcp_port_tester.tscn")
	mPortTesters[port] = port_tester
	add_child(port_tester)
	port_tester.connect("success", self, "_port_open", [port])
	port_tester.connect("failure", self, "_port_closed", [port])
	port_tester.test(mHostAddress, port)

func _port_open(port):
	var url = "rfb://"+mHostAddress+":"+str(port-5900)
	var host = mHostAddress
	var name = "RFB Server (:"+str(port-5900)+")"
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
	if port > 5900:
		_add_port_tester(port + 1)

func _port_closed(port):
	if port > 5900:
		queue_free()

func scan_host(addr):
	mHostAddress = addr
	_add_port_tester(5900)
	_add_port_tester(5901)
