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

extends ReferenceFrame

onready var gui = get_node("gui")

const COROUTINE_TYPE_NET_INPUT = 1
const COROUTINE_TYPE_NET_OUTPUT = 2
const COROUTINE_TYPE_ANIMATION = 3

const PORT_TYPE_TCP = 0
const PORT_TYPE_UDP = 1

var mNextPort = {
	PORT_TYPE_TCP: 22000,
	PORT_TYPE_UDP: 22000
}

var mOutputPorts = {}
var mInputPorts = {}

var mTmpDirPath = ""
var mInfoFiles = {}
var mModuleInfo = {}
var mNextAvailableModuleId = 1
var mNextAvailableTaskId = 1
var mTaskNodes = {} # Task ID -> Task Node
var mISquareSize = 40

func _init():
	add_user_signal("init_finished")
	add_user_signal("module_added")
	add_user_signal("module_removed")
	add_user_signal("url_handler_added")
	add_user_signal("url_handler_removed")
	add_user_signal("task_list_changed")
	add_user_signal("task_added")
	add_user_signal("task_changed")
	add_user_signal("task_removed")
	add_user_signal("new_log_entry3")

func _init_routine(print_init_msg_func, args = null):
	print_init_msg_func.call_func("*** BEGIN RC/OS INIT ***\n")
	var root_canvas_script = load("res://rcos_core/root_canvas.gd")
	get_node("/root").set_script(root_canvas_script)
	yield()
	print_init_msg_func.call_func("* Querying host model name...")
	yield()
	var model_name = OS.get_model_name()
	print_init_msg_func.call_func(" '" + model_name + "'\n")
	yield()
	print_init_msg_func.call_func("* Querying host OS name...")
	yield()
	var os_name = OS.get_name()
	print_init_msg_func.call_func(" '" + os_name + "'\n")
	yield()
	print_init_msg_func.call_func("* Querying screen size...")
	yield()
	var res = OS.get_screen_size()
	print_init_msg_func.call_func(" " + str(res) + "\n")
	yield()
	print_init_msg_func.call_func("* Querying screen DPI...")
	yield()
	var dpi = OS.get_screen_dpi()
	print_init_msg_func.call_func(" " + str(dpi) + "\n")
	yield()
	if model_name == "GenericDevice":
		mISquareSize = 40 
	else:
		mISquareSize = dpi/4
	if mISquareSize < 40:
		mISquareSize = 40
	#get_tree().set_auto_accept_quit(false)
	#OS.set_low_processor_usage_mode(true)	
	mTmpDirPath = rlib.join_array([
		"user://tmp/rcos", 
		OS.get_process_ID(),
		OS.get_unix_time()
	], "-") + "/"
	print_init_msg_func.call_func("* Temp directory is " + mTmpDirPath + "\n")
	yield()
	print_init_msg_func.call_func("* Building info file database...\n")
	yield()
	var info_file_paths = rlib.find_files("res://", "*.info")
	print_init_msg_func.call_func("* Found " + str(info_file_paths.size()) + " info files.\n")
	yield()
	for filename in info_file_paths:
		print_init_msg_func.call_func("* Processing " + filename)
		yield()
		var config_file = ConfigFile.new()
		var err = config_file.load(filename)
		if err != OK:
			print_init_msg_func.call_func(" ERROR: " + str(err)) + "\n"
		else:
			mInfoFiles[filename] = config_file
			print_init_msg_func.call_func(" OK\n")
		yield()
	print_init_msg_func.call_func("* Building module database...\n")
	yield()
	for filename in mInfoFiles.keys():
		var config_file = mInfoFiles[filename]
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
		print_init_msg_func.call_func("* Found module: " + module.name + "\n")
		yield()
	data_router.set_node_icon("rcos", load("res://data_router/icons/32/rcos.png"), 32)
	# Select icon for localhost node
	if model_name == "GenericDevice":
		data_router.set_node_icon("localhost", load("res://data_router/icons/32/generic_device.png"), 32)
	else:
		data_router.set_node_icon("localhost", load("res://data_router/icons/32/smartphone.png"), 32)
	data_router.set_node_icon("localhost/x11", load("res://data_router/icons/32/x11.png"), 32)
	data_router.set_node_icon("localhost/android", load("res://data_router/icons/32/android.png"), 32)
	data_router.set_node_icon("localhost/windows", load("res://data_router/icons/32/windows_os.png"), 32)
	yield()
	# Start core services...
	print_init_msg_func.call_func("* Starting core services...\n")
	var services = {
		"URL Handler service": "res://rcos_core/services/url_handler_service/url_handler_service.tscn",
		"Host Info service": "res://rcos_core/services/host_info_service/host_info_service.tscn",
		"Network Scanner service": "res://rcos_core/services/network_scanner_service/network_scanner_service.tscn",
		"Widgets service": "res://rcos_core/services/widgets_service/widgets_service.tscn"
	}
	for service_name in services.keys():
		print_init_msg_func.call_func("* Starting " + service_name + "...")
		yield()
		var scene_path = services[service_name]
		var service_packed = load(scene_path)
		if service_packed == null:
			print_init_msg_func.call_func(" FAILED\n")
			print_init_msg_func.call_func("*** INIT FAILED: UNABLE TO LOAD " + service_name.to_upper() + "\n")
			return null
		var service = service_packed.instance()
		if service == null:
			print_init_msg_func.call_func(" FAILED\n")
			print_init_msg_func.call_func("*** INIT FAILED: UNABLE TO INSTANCE " + service_name.to_upper() + "\n")
			return null
		if !add_service(service):
			print_init_msg_func.call_func(" FAILED\n")
			print_init_msg_func.call_func("*** INIT FAILED: UNABLE TO ADD " + service_name.to_upper() + "\n")
			return null
		print_init_msg_func.call_func(" DONE\n")
		yield()
	print_init_msg_func.call_func("* Loading Window Manager...")
	yield()
	var wm_packed = load("res://rcos_core/wm/wm.tscn")
	if wm_packed == null:
		print_init_msg_func.call_func(" FAILED\n")
		print_init_msg_func.call_func(" *** INIT FAILED: UNABLE TO LOAD WINDOW MANAGER")
		return null
	var wm = wm_packed.instance()
	if wm_packed == null:
		print_init_msg_func.call_func(" FAILED\n")
		print_init_msg_func.call_func(" *** INIT FAILED: UNABLE TO INSTANCE WINDOW MANAGER")
		return null
	get_node("gui/window_manager").add_child(wm)
	print_init_msg_func.call_func(" DONE\n")
	yield()
	print_init_msg_func.call_func("*** RC/OS INIT FINISHED ***\n")
	emit_signal("init_finished")
	OS.set_target_fps(30)
	return null

func _add_log_entry(source_node, level, content):
	emit_signal("new_log_entry3", source_node, level, content)

func _find_modules():
	var modules = {}
	var info_files = rlib.find_files("res://", "*.info")
	for filename in info_files:
		var config_file = ConfigFile.new()
		var err = config_file.load(filename)
		if err != OK:
			log_error(self, "Error reading info file " + filename + ": " + str(err))
			continue
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
		modules[module.name] = module
	return modules

func log_debug(source_node, content):
	#prints("debug", source_node, content)
	_add_log_entry(source_node, "debug", content)

func log_notice(source_node, content):
	#prints("notice", source_node, content)
	_add_log_entry(source_node, "notice", content)

func log_error(source_node, content):
	#prints("error", source_node, content)
	_add_log_entry(source_node, "error", content)

func is_canvas_visible(canvas):
	var visible = false

func enable_canvas_input(node):
	var group = "_canvas_input"+str(node.get_viewport().get_instance_ID())
	node.add_to_group(group)

func disable_canvas_input(node):
	var group = "_canvas_input"+str(node.get_viewport().get_instance_ID())
	node.remove_from_group(group)

func get_info_files():
	return mInfoFiles

func get_isquare_size():
	return mISquareSize

func get_module_info():
	return mModuleInfo

func get_modules():
	var modules = {}
	for node in get_node("modules").get_children():
		modules[node.get_name()] = node.get_child(0)
	return modules

func get_tmp_dir():
	return mTmpDirPath

func add_task(properties, parent_task_id = -1):
	var parent_node = get_node("tasks")
	if parent_task_id >= 0:
		if !mTaskNodes.has(parent_task_id):
			return -1
		parent_node = mTaskNodes[parent_task_id]
	var task_id = mNextAvailableTaskId
	mNextAvailableTaskId += 1
	var task_node = rlib.instance_scene("res://rcos_core/task.tscn")
	task_node.set_name(str(task_id)) 
	task_node.properties = properties
	parent_node.add_child(task_node)
	mTaskNodes[task_id] = task_node
	emit_signal("task_added", task_node)
	emit_signal("task_list_changed")
	return task_id

func change_task(task_id, properties):
	if !mTaskNodes.has(task_id):
		return false
	var task_node = mTaskNodes[task_id]
	for key in properties.keys():
		task_node.properties[key] = properties[key]
	emit_signal("task_changed", task_node)
	emit_signal("task_list_changed")
	return true

func remove_task(task_id):
	if !mTaskNodes.has(task_id):
		return true
	var task_node = mTaskNodes[task_id]
	emit_signal("task_removed", task_node)
	mTaskNodes.erase(task_id)
	task_node.get_parent().remove_child(task_node)
	task_node.free()
	emit_signal("task_list_changed")
	return true

func get_task_properties(task_id):
	if !mTaskNodes.has(task_id):
		return null
	var properties = {}
	var task_node = mTaskNodes[task_id]
	for key in task_node.properties.keys():
		properties[key] = task_node.properties[key]
	return properties

func get_task_list():
	return mTaskNodes

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

func spawn_module(module_name, instance_name = null):
	if !mModuleInfo.has(module_name):
		if mModuleInfo.has(module_name+"_module"):
			module_name = module_name+"_module"
		else:
			log_error(self, "spawn_module(): Unknown module: " + module_name)
			return null
	var module = mModuleInfo[module_name]
	if instance_name == null:
		instance_name = module.name
	var scene_packed = load(module.path)
	if scene_packed == null:
		log_error(self, "spawn_module(): Error loading " + module.path)
		return null
	var module_node = scene_packed.instance()
	if module_node == null:
		log_error(self, "spawn_module(): Error instancing " + module.path)
		return null
	var node = Node.new()
	node.set_name(str(mNextAvailableModuleId))
	node.add_child(module_node)
	module_node.set_name(instance_name)
	mNextAvailableModuleId += 1
	get_node("modules").add_child(node)
	emit_signal("module_added", module_node)
	return module_node

func add_service(service_node):
	var service_name = service_node.get_name()
	var services_node = get_node("services")
	if  services_node.has_node(service_name):
		log_error(self, "add_service(): Service " + service_name + "already exists")
		return false
	services_node.add_child(service_node)
	return true

func initialize(print_init_msg_func, args = null):
	return _init_routine(print_init_msg_func, args)
