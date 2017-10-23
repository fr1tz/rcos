extends ReferenceFrame

var mActiveTaskId = -1

onready var mTaskbarItemsGroup = "taskbar_items_"+str(get_instance_ID())

func _init():
	add_user_signal("task_selected")

func _ready():
	rcos.connect("task_list_changed", self, "_on_task_list_changed")
	var items_scroller = get_node("items_scroller")
	items_scroller.connect("scrolling_started", self, "show_titles")
	items_scroller.connect("scrolling_stopped", self, "hide_titles")

func _on_task_list_changed():
	var task_list = rcos.get_task_list()
	update_items(task_list)

func _item_selected(task_id):
	emit_signal("task_selected", task_id)

func show_titles():
	get_tree().call_group(0, mTaskbarItemsGroup, "show_title")

func hide_titles():
	get_tree().call_group(0, mTaskbarItemsGroup, "hide_title")

func update_items(task_list):
	var items = get_node("items_scroller/items")
	for item in items.get_children():
		items.remove_child(item)
		item.queue_free()
	for task in task_list:
		var item = load("res://rcos/shell/taskbar_item.tscn").instance()
		item.add_to_group(mTaskbarItemsGroup)
		item.set_task_id(task.id)
		item.set_title(task.name)
		item.set_icon(task.icon)
		item.hide_title()
		item.connect("selected", self, "_item_selected", [task.id])
		if task.id == mActiveTaskId:
			item.mark_active()
		items.add_child(item)
#
func mark_active_task(task_id):
	mActiveTaskId = task_id
	var items = get_node("items_scroller/items")
	for item in items.get_children():
		if item.get_task_id() == mActiveTaskId:
			item.mark_active()
		else:
			item.mark_inactive()
