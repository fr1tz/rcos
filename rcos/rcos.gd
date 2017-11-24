extends Panel

const PORT_TYPE_TCP = 0
const PORT_TYPE_UDP = 1

var mNextPort = {
	PORT_TYPE_TCP: 22000,
	PORT_TYPE_UDP: 22000
}

var mNextAvailableModuleId = 1
var mNextAvailableTaskId = 1
var mCanvasStack = []
var mTasks = []

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if mCanvasStack.size() <= 1:
			get_tree().quit()
		else:
			pop_canvas()

func _init():
	#OS.set_low_processor_usage_mode(true)
	add_user_signal("task_list_changed")
	add_user_signal("new_log_entry3")

func _ready():
	get_tree().set_auto_accept_quit(false)
	set_process_input(true)
#	spawn_module("res://rcos/logger/logger.tscn")
	spawn_module("res://rcos/shell/shell.tscn")
	spawn_module("res://rcos/connector/connector.tscn")
#	var info = {
#		addr = "localhost",
#		name = "test",
#		port = 1234,
#		type = "vrc"
#	}
#	var vrc_host = open_connection(info)
#	var file = File.new()
#	file.open("res://vrc_host/output_module.xml", File.READ)
#	vrc_host.set_variable("OUTPUT_MODULE_DATA", file.get_as_text())
#	file.close()
#	print(vrc_host.add_module("OUTPUT_MODULE_DATA"))
#	vrc_host.get_node("main_canvas/main_gui/status_screen").set_connection_count(3)

func _input(event):
	var group = "_canvas_input"+str(get_viewport().get_instance_ID())
	if get_tree().has_group(group):
		get_tree().call_group(1|2|8, group, "_canvas_input", event)

func _set_task_property(task_id, prop_name, prop_value):
	for task in mTasks:
		if task.id == task_id:
			task[prop_name] = prop_value
			call_deferred("emit_signal", "task_list_changed")
			return

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

func add_task():
	var task = {
		"id": mNextAvailableTaskId,
		"name": "",
		"icon": null,
		"canvas": null,
		"ops": null
	}
	mNextAvailableTaskId += 1
	mTasks.append(task)
	call_deferred("emit_signal", "task_list_changed")
	return task.id

func remove_task(task_id):
	for task in mTasks:
		if task.id == task_id:
			mTasks.erase(task)
			call_deferred("emit_signal", "task_list_changed")
			return

func set_task_name(task_id, string):
	_set_task_property(task_id, "name", string)

func set_task_icon(task_id, texture):
	_set_task_property(task_id, "icon", texture)

func set_task_canvas(task_id, canvas):
	_set_task_property(task_id, "canvas", canvas)

func set_task_ops(task_id, array):
	_set_task_property(task_id, "ops", array)

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

func push_canvas(canvas):
	if mCanvasStack.has(canvas):
		mCanvasStack.erase(canvas)
	mCanvasStack.push_back(canvas)
	get_node("root_window").show_canvas(canvas)

func pop_canvas():
	if mCanvasStack.size() > 0:
		remove_canvas(mCanvasStack.back())

func remove_canvas(canvas):
	if mCanvasStack.has(canvas):
		mCanvasStack.erase(canvas)
	if mCanvasStack.size() > 0:
		get_node("root_window").show_canvas(mCanvasStack.back())
	else:
		get_node("root_window").show_canvas(null)

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
