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

var mPackedHostScanner = null
var mScanRoutine = null

func _init():
	add_user_signal("service_discovered")

func _exit_tree():
	coroutines.destroy(mScanRoutine)

func _ready():
	mPackedHostScanner = load("res://network_scanners/rfb_server_scanner/host_scanner.tscn")
	mScanRoutine = coroutines.create(self, "_scan_routine")
	mScanRoutine.start()

func _scan_routine():
	_scan_host("127.0.0.1")
	yield()
	var networks = []
	for addr in IP.get_local_addresses():
		if addr.begins_with("10.") \
		|| addr.begins_with("192.168."):
			var bytes = addr.split(".")
			var network = bytes[0]+"."+bytes[1]+"."+bytes[2]+"."
			if !networks.has(network):
				networks.push_back(network)
	for network in networks:
		for i in range(1, 255):
			_scan_host(network+str(i))
			yield()
	return null

func _scan_host(addr):
	var host_scanner = mPackedHostScanner.instance()
	get_node("hosts").add_child(host_scanner)
	host_scanner.set_name(addr)
	host_scanner.connect("service_discovered", self, "_service_discovered")
	host_scanner.scan_host(addr)

func _service_discovered(info):
	emit_signal("service_discovered", info)
