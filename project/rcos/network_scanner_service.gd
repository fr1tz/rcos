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

var mScanners = []
var mScanning = false

func _init():
	add_user_signal("scan_started")
	add_user_signal("service_discovered")
	add_user_signal("scan_finished")

func _ready():
	for scanner in find_network_scanners():
		add_scanner(scanner)
	get_node("abort_scan_timer").connect("timeout", self, "stop_scan")

func _service_discovered(info):
	if rcos.has_node("services/hostname_service"):
		var hostname_service = rcos.get_node("services/hostname_service")
		info.host = hostname_service.get_hostname(info.host)
	emit_signal("service_discovered", info)

func find_network_scanners():
	var scanners = []
	var ns_files = rlib.find_files("res://", "*.ns")
	for filename in ns_files:
		var config_file = ConfigFile.new()
		var err = config_file.load(filename)
		if err != OK:
			log_error(self, "Error reading ns file " + filename + ": " + str(err))
			continue
		var basename = filename.get_file().basename()
		var path = config_file.get_value("widget", "path", filename.basename()+".tscn")
		scanners.push_back(path)
	return scanners

func add_scanner(scene_path):
	if !mScanners.has(scene_path):
		mScanners.push_back(scene_path)

func remove_scanner(scene_path):
	mScanners.erase(scene_path)

func start_scan():
	if mScanning:
		return
	for scanner_path in mScanners:
		var scanner = rlib.instance_scene(scanner_path)
		if scanner:
			scanner.connect("service_discovered", self, "_service_discovered")
			get_node("scanners").add_child(scanner)
	if get_node("scanners").get_child_count() == 0:
		stop_scan()
		return
	get_node("abort_scan_timer").start()
	mScanning = true
	emit_signal("scan_started")

func stop_scan():
	for scanner in get_node("scanners").get_children():
		get_node("scanners").remove_child(scanner)
		scanner.free()
	get_node("abort_scan_timer").stop()
	mScanning = false
	emit_signal("scan_finished")
