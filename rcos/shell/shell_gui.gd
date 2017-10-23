extends Panel

onready var mOpsButton = get_node("ops_button")
onready var mTaskbar = get_node("taskbar")

var mActiveTask = null

func _ready():
	rcos.connect("task_list_changed", self, "_on_task_list_changed")
	mOpsButton.connect("pressed", self, "_on_ops_button_pressed")
	mTaskbar.connect("task_selected", self, "show_task")

func _on_ops_button_pressed():
	if mActiveTask == null:
		return
	var ops = mActiveTask.ops
	if ops == null || ops.empty():
		return
	var op = ops[0]
	op[1].call_func()

func _on_task_list_changed():
	var task_list = rcos.get_task_list()
	if task_list.size() == 1:
		var task_id = task_list[0].id
		show_task(task_id)

func show_task(task_id):
	var task = rcos.get_task(task_id)
	if task == null:
		return
	get_node("window").show_canvas(task.canvas)
	mOpsButton.hide()
	mTaskbar.mark_active_task(task_id)
	if task.ops != null && !task.ops.empty():
		var icon = task.ops[0][0]
		var tex = load("res://rcos/themes/default/icons/"+icon+".png")
		mOpsButton.set_button_icon(tex)
		mOpsButton.show()
	mActiveTask = task
