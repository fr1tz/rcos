extends Node

var mTaskId = -1

func _ready():
	mTaskId = rcos.add_task()
	var task_name = "Connector"
	var task_icon = get_node("icon").get_texture()
	var task_canvas = get_node("canvas")
	var task_ops = null
	rcos.set_task_name(mTaskId, task_name)
	rcos.set_task_icon(mTaskId, task_icon)
	rcos.set_task_canvas(mTaskId, task_canvas)
	rcos.set_task_ops(mTaskId, task_ops)

