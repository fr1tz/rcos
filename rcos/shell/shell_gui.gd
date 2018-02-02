extends Panel

onready var mWindow = get_node("window")
onready var mTaskbar = get_node("taskbar")

var mActiveTask = null

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_escape()

func _escape():
	var taskbar_was_hidden = mTaskbar.is_hidden()
	mTaskbar.set_hidden(false)
	if mActiveTask.ops != null && mActiveTask.ops.has("go_back"):
		var ret = mActiveTask.ops["go_back"].call_func()
		if ret:
			return
	if taskbar_was_hidden:
		return
	if mActiveTask == rcos.get_task_list()[0]:
		get_tree().quit()
	else:
		show_task(rcos.get_task_list()[0].id)

func _ready():
	rcos.connect("task_changed", self, "_on_task_changed")
	rcos.connect("task_list_changed", self, "_on_task_list_changed")
	mTaskbar.connect("task_selected", self, "show_task")

func _on_task_changed(task):
	if task == mActiveTask:
		show_task(task.id)

func _on_task_list_changed():
	var task_list = rcos.get_task_list()
	if task_list.size() == 1:
		var task_id = task_list[0].id
		show_task(task_id)

func show_task(task_id):
	var task = rcos.get_task(task_id)
	if task == null:
		return
	mActiveTask = task
	var canvas = mActiveTask.canvas
	var rect = Rect2(0, 0, canvas.get_rect().size.x, canvas.get_rect().size.y)
	mWindow.set_size(Vector2(rect.size.x, rect.size.y))
	var fullscreen = false
	if rect.size.x > rect.size.y:
		mWindow.set_rotation_deg(-90)
		mWindow.set_pos(Vector2(rect.size.y, 0))
		if rect.size.y > 200:
			fullscreen = true
	else:
		mWindow.set_rotation_deg(0)
		mWindow.set_pos(Vector2(0, 0))
		if rect.size.x > 200:
			fullscreen = true
	mTaskbar.set_hidden(fullscreen)
	mWindow.show_canvas(mActiveTask.canvas)
	mTaskbar.mark_active_task(task_id)
