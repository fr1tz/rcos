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

onready var gui = rcos_gui # Deprecated

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

func _init():
	add_user_signal("init_finished")
	add_user_signal("url_handler_added")
	add_user_signal("url_handler_removed")

func _init_routine(handle_init_msg_func, args = {}):
	var printf = handle_init_msg_func
	printf.call_func("*** BEGIN RC/OS INIT ***\n"); yield()
	OS.set_window_title(Globals.get("application/name") + " " + Globals.get("rcos/version_string"))
	printf.call_func("* Initializing root canvas..."); yield()
	var root_canvas_script = load("res://rcos_core/root_canvas.gd")
	if root_canvas_script == null:
		printf.call_func(" *** INIT FAILED: UNABLE TO LOAD res://rcos_core/root_canvas.gd"); yield()
		return null
	get_node("/root").set_script(root_canvas_script)
	get_node("/root").initialize()
	printf.call_func(" DONE\n"); yield()
	printf.call_func("* Querying host model name..."); yield()
	var model_name = OS.get_model_name()
	printf.call_func(" '" + model_name + "'\n"); yield()
	printf.call_func("* Querying host OS name..."); yield()
	var os_name = OS.get_name()
	printf.call_func(" '" + os_name + "'\n"); yield()
	printf.call_func("* Querying screen size..."); yield()
	var res = OS.get_screen_size()
	printf.call_func(" " + str(res) + "\n"); yield()
	printf.call_func("* Querying screen DPI..."); yield()
	var dpi = OS.get_screen_dpi()
	printf.call_func(" " + str(dpi) + "\n"); yield()
	#get_tree().set_auto_accept_quit(false)
	#OS.set_low_processor_usage_mode(true)	
	mTmpDirPath = rlib.join_array([
		"user://tmp/rcos", 
		OS.get_process_ID(),
		OS.get_unix_time()
	], "-") + "/"
	printf.call_func("* Temp directory is " + mTmpDirPath + "\n"); yield()
	printf.call_func("* Building info file database...\n"); yield()
	var info_file_paths = rlib.find_files("res://", "*.info")
	printf.call_func("* Found " + str(info_file_paths.size()) + " info files.\n"); yield()
	for filename in info_file_paths:
		printf.call_func("* Processing " + filename); yield()
		var config_file = ConfigFile.new()
		var err = config_file.load(filename)
		if err != OK:
			printf.call_func(" ERROR: " + str(err) + "\n"); yield()
		else:
			mInfoFiles[filename] = config_file
			printf.call_func(" OK\n"); yield()
	printf.call_func("* Building module database...\n"); yield()
	rcos_modules.initialize()
	# Initialize data router...
	printf.call_func("* Initializing data router"); yield()
	rcos_data_router.initialize("user://etc/data_router")
	rcos_data_router.set_node_icon("rcos", load("res://rcos_sys/data_router/icons/32/rcos.png"), 32)
	if model_name == "GenericDevice":
		rcos_data_router.set_node_icon("localhost", load("res://rcos_sys/data_router/icons/32/generic_device.png"), 32)
	else:
		rcos_data_router.set_node_icon("localhost", load("res://rcos_sys/data_router/icons/32/smartphone.png"), 32)
	rcos_data_router.set_node_icon("localhost/x11", load("res://rcos_sys/data_router/icons/32/x11.png"), 32)
	rcos_data_router.set_node_icon("localhost/android", load("res://rcos_sys/data_router/icons/32/android.png"), 32)
	rcos_data_router.set_node_icon("localhost/windows", load("res://rcos_sys/data_router/icons/32/windows_os.png"), 32)
	printf.call_func(" DONE\n"); yield()
	# Start core services...
	printf.call_func("* Starting core services...\n"); yield()
	var services = {
		"URL Handler service": "res://rcos_core/services/url_handler_service/url_handler_service.tscn",
		"Host Info service": "res://rcos_core/services/host_info_service/host_info_service.tscn",
		"Network Scanner service": "res://rcos_core/services/network_scanner_service/network_scanner_service.tscn",
		"Widgets service": "res://rcos_core/services/widgets_service/widgets_service.tscn"
	}
	for service_name in services.keys():
		printf.call_func("* Starting " + service_name + "..."); yield()
		var scene_path = services[service_name]
		var service_packed = load(scene_path)
		if service_packed == null:
			printf.call_func(" FAILED\n"); yield()
			printf.call_func("*** INIT FAILED: UNABLE TO LOAD " + service_name.to_upper() + "\n"); yield()
			return null
		var service = service_packed.instance()
		if service == null:
			printf.call_func(" FAILED\n"); yield()
			printf.call_func("*** INIT FAILED: UNABLE TO INSTANCE " + service_name.to_upper() + "\n"); yield()
			return null
		if !rcos_services.add_service(service):
			printf.call_func(" FAILED\n"); yield()
			printf.call_func("*** INIT FAILED: UNABLE TO ADD " + service_name.to_upper() + "\n"); yield()
			return null
		printf.call_func(" DONE\n"); yield()
	# Initialize GUI...
	printf.call_func("* Initializing GUI..."); yield()
	var isquare_size
	if model_name == "GenericDevice":
		isquare_size = 40 
	else:
		isquare_size = dpi/4
	if isquare_size < 40:
		isquare_size = 40
	rcos_gui.set_isquare_size(isquare_size)
	# Load ZEM (or a user-specified replacement)
	var zem_path = "res://rcos_core/zem_gui/zem.tscn"
	if args.has("zem_path"):
		zem_path = args.zem_path
	var zem_packed = load(zem_path)
	if zem_packed == null:
		printf.call_func(" FAILED\n"); yield()
		printf.call_func(" *** INIT FAILED: UNABLE TO LOAD "+zem_path); yield()
		return null
	var zem = zem_packed.instance()
	if zem == null:
		printf.call_func(" FAILED\n"); yield()
		printf.call_func(" *** INIT FAILED: UNABLE TO INSTANCE "+zem_path); yield()
		return null
	rcos_gui.add_child(zem)
	rcos_gui.move_child(zem, 0)
	printf.call_func(" DONE\n"); yield()
	printf.call_func("*** RC/OS INIT FINISHED ***\n"); yield()
	emit_signal("init_finished")
	if model_name == "GenericDevice":
		set_default_target_fps(60)
		set_max_target_fps(120)
	else:
		set_default_target_fps(30)
		set_max_target_fps(60)
	return null

func set_default_target_fps(fps):
	get_node("/root").__set_default_target_fps(fps)

func set_max_target_fps(fps):
	get_node("/root").__set_max_target_fps(fps)

func enable_canvas_input(node):
	var group = "_canvas_input"+str(node.get_viewport().get_instance_ID())
	node.add_to_group(group)

func disable_canvas_input(node):
	var group = "_canvas_input"+str(node.get_viewport().get_instance_ID())
	node.remove_from_group(group)

func get_info_files():
	return mInfoFiles

# Deprecated: Use rcos_gui.get_isquare_size() instead
func get_isquare_size(): 
	return rcos_gui.get_isquare_size()

func get_tmp_dir():
	return mTmpDirPath

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

func initialize(handle_init_msg_func, args = {}):
	return _init_routine(handle_init_msg_func, args)
