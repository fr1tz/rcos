# Copyright © 2017-2019 Michael Goldener <mg@wasted.ch>
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

var mModuleInfo = {}
var mNextAvailableModuleId = 1

func _init():
	add_user_signal("module_added")
	add_user_signal("module_removed")

func get_module_info():
	return mModuleInfo

func get_modules():
	var modules = {}
	for node in get_children():
		modules[node.get_name()] = node.get_child(0)
	return modules

func spawn_module(module_name, instance_name = null):
	if !mModuleInfo.has(module_name):
		if mModuleInfo.has(module_name+"_module"):
			module_name = module_name+"_module"
		else:
			rcos_log.error(self, "spawn_module(): Unknown module: " + module_name)
			return null
	var module = mModuleInfo[module_name]
	if instance_name == null:
		instance_name = module.name
	var scene_packed = load(module.path)
	if scene_packed == null:
		rcos_log.error(self, "spawn_module(): Error loading " + module.path)
		return null
	var module_node = scene_packed.instance()
	if module_node == null:
		rcos_log.error(self, "spawn_module(): Error instancing " + module.path)
		return null
	var node = Node.new()
	node.set_name(str(mNextAvailableModuleId))
	node.add_child(module_node)
	module_node.set_name(instance_name)
	mNextAvailableModuleId += 1
	add_child(node)
	emit_signal("module_added", module_node)
	return module_node

func initialize():
	var info_files = rcos.get_info_files()
	for filename in info_files.keys():
		var config_file = info_files[filename]
		if !config_file.has_section("module"):
			continue
		var path = config_file.get_value("module", "path", "")
		if path == "":
			path = filename.basename()+".tscn"
		elif path.begins_with("/"):
			path = "res://" + path.right(1)
		else:
			path = filename.get_base_dir() + "/" + path
		var module = {
			"name": filename.get_file().basename(),
			"desc": config_file.get_value("module", "desc", "No description"),
			"path": path
		}
		mModuleInfo[module.name] = module
