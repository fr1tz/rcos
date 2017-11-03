extends Node

var mTaskId = -1

func _ready():
	mTaskId = rcos.add_task()
	var task_name = "Logger"
	var task_icon = get_node("icon").get_texture()
	var task_canvas = get_node("canvas")
	var task_ops = [
		[ "kill", funcref(self, "kill") ]
	]
	rcos.set_task_name(mTaskId, task_name)
	rcos.set_task_icon(mTaskId, task_icon)
	rcos.set_task_canvas(mTaskId, task_canvas)
	rcos.set_task_ops(mTaskId, task_ops)
	rcos.connect("new_log_entry3", self, "_on_new_log_entry")

func _on_new_log_entry(source_node, level, content):
	var source_path = str(source_node.get_path())
	if source_path.begins_with("/root/rcos"):
		source_path = source_path.right(6)
	content = str(content).replace("\n", "\n  ")
	var entry = level + " " + source_path + "\n  " + content + "\n"

func kill():
	rcos.log_debug(self, ["kill()"])
	rcos.remove_task(mTaskId)
	queue_free()
