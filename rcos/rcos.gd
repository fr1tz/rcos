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

extends ColorFrame

const PORT_TYPE_TCP = 0
const PORT_TYPE_UDP = 1

var mNextPort = {
	PORT_TYPE_TCP: 22000,
	PORT_TYPE_UDP: 22000
}

var mTmpDirPath = ""
var mNextAvailableModuleId = 1
var mNextAvailableTaskId = 1
var mTasks = []

func _init():
	#get_tree().set_auto_accept_quit(false)
	#OS.set_low_processor_usage_mode(true)	
	mTmpDirPath = rlib.join_array([
		"user://tmp/rcos", 
		OS.get_process_ID(),
		OS.get_unix_time()
	], "-") + "/"
	add_user_signal("task_list_changed")
	add_user_signal("task_added")
	add_user_signal("task_changed")
	add_user_signal("task_removed")
	add_user_signal("new_log_entry3")

func _ready():
	get_viewport().connect("size_changed", self, "_resized")
	set_process_input(true)

func _resized():
	var root_canvas = get_node("root_window").get_canvas()
	if root_canvas == null:
		return
	var screen_size = get_viewport().get_rect().size
	if OS.get_model_name() == "GenericDevice":
		root_canvas.resize(screen_size)
	else:
		var screen_num = OS.get_current_screen()
		var dpi = OS.get_screen_dpi(screen_num)
		var root_canvas_size = screen_size * (120.0/dpi)
		root_canvas.resize(root_canvas_size)

func _input(event):
	var group = "_canvas_input"+str(get_viewport().get_instance_ID())
	if get_tree().has_group(group):
		get_tree().call_group(1|2|8, group, "_canvas_input", event)

func _add_log_entry(source_node, level, content):
	emit_signal("new_log_entry3", source_node, level, content)

func log_debug(source_node, content):
	_add_log_entry(source_node, "debug", content)

func log_notice(source_node, content):
	_add_log_entry(source_node, "notice", content)

func log_error(source_node, content):
	_add_log_entry(source_node, "error", content)

func is_canvas_visible(canvas):
	var visible = false

func enable_canvas_input(node):
	var group = "_canvas_input"+str(node.get_viewport().get_instance_ID())
	node.add_to_group(group)

func disable_canvas_input(node):
	var group = "_canvas_input"+str(node.get_viewport().get_instance_ID())
	node.remove_from_group(group)

func get_tmp_dir():
	return mTmpDirPath

func add_task(properties):
	var task = properties
	task["id"] = mNextAvailableTaskId
	mNextAvailableTaskId += 1
	mTasks.append(task)
	call_deferred("emit_signal", "task_added", task)
	call_deferred("emit_signal", "task_list_changed")
	return task.id

func change_task(task_id, properties):
	for task in mTasks:
		if task.id == task_id:
			for key in properties.keys():
				task[key] = properties[key]
			call_deferred("emit_signal", "task_changed", task)
			call_deferred("emit_signal", "task_list_changed")
			return

func remove_task(task_id):
	for task in mTasks:
		if task.id == task_id:
			mTasks.erase(task)
			call_deferred("emit_signal", "task_removed", task)
			call_deferred("emit_signal", "task_list_changed")
			return

func get_task(task_id):
	for task in mTasks:
		if task.id == task_id:
			return task
	return null

func get_task_list():
	return mTasks

func listen(object, port_type):
	if !mNextPort.has(port_type):
		error("[rlib] listen(): Invalid port type: ", port_type)
		return -1
	var port_begin = mNextPort[port_type]
	var port_end = 49151
	for port in range(port_begin, port_end+1):
		var error = object.listen(port)
		if error == 0:
			mNextPort[port_type] = port+1
			return port
	return -2

func set_root_canvas(canvas):
	get_node("root_window").show_canvas(canvas)
	_resized()

func spawn_module(scene_path, name = null):
	if name == null:
		name = scene_path.get_file().basename()
	var module_packed = load(scene_path)
	if module_packed == null:
		print("spawn_module() Error loading ", scene_path)
		return false
	var module = module_packed.instance()
	if module == null:
		print("spawn_module() Error instancing ", scene_path)
		return false
	var node = Node.new()
	node.set_name(str(mNextAvailableModuleId))
	node.add_child(module)
	module.set_name(name)
	mNextAvailableModuleId += 1
	get_node("modules").add_child(node)
	return module

func open_connection(todo):
	#TODO
	pass
