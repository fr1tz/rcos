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
var mPerformScan = false
var mScanRoutine = null

func _init():
	add_user_signal("scan_started")
	add_user_signal("service_discovered")
	add_user_signal("scan_finished")

func _exit_tree():
	coroutines.destroy(mScanRoutine)

func _ready():
	var info_files = rcos.get_info_files()
	for filename in info_files.keys():
		var config_file = info_files[filename]
		if !config_file.has_section("network_scanner"):
			continue
		var path = config_file.get_value("network_scanner", "path", filename.basename()+".tscn")
		if !mScanners.has(path):
			mScanners.push_back(path)
	get_node("abort_scan_timer").connect("timeout", self, "stop_scan")

func _service_discovered(info):
	emit_signal("service_discovered", info)

func _scan_routine():
	while mPerformScan:
		emit_signal("scan_started")
		for scanner_path in mScanners:
			var scanner = rlib.instance_scene(scanner_path)
			if scanner:
				scanner.connect("service_discovered", self, "_service_discovered")
				get_node("scanners").add_child(scanner)
			yield()
		get_node("abort_scan_timer").start()
		while mPerformScan && get_node("scanners").get_child_count() > 0:
			yield()
		get_node("abort_scan_timer").stop()
		mPerformScan = false
		emit_signal("scan_finished")
		for scanner in get_node("scanners").get_children():
			get_node("scanners").remove_child(scanner)
			scanner.free()
			yield()
	coroutines.destroy(mScanRoutine)
	mScanRoutine = null
	return null

func add_scanner(scene_path):
	if !mScanners.has(scene_path):
		mScanners.push_back(scene_path)

func remove_scanner(scene_path):
	mScanners.erase(scene_path)

func start_scan():
	mPerformScan = true
	if mScanRoutine == null:
		mScanRoutine = coroutines.create(self, "_scan_routine")
		mScanRoutine.start()

func stop_scan():
	mPerformScan = false
