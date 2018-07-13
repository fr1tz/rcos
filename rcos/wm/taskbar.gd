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

var mActiveTaskId = -1

onready var mOpsButton = get_node("ops_button/button")
onready var mTaskbarItemsGroup = "taskbar_items_"+str(get_instance_ID())

func _init():
	add_user_signal("task_selected")

func _ready():
	rcos.connect("task_added", self, "_on_task_added")
	rcos.connect("task_changed", self, "_on_task_changed")
	rcos.connect("task_removed", self, "_on_task_removed")
	var items_scroller = get_node("items_scroller")
	items_scroller.connect("scrolling_started", self, "show_titles")
	items_scroller.connect("scrolling_stopped", self, "hide_titles")
	mOpsButton.connect("pressed", self, "_on_ops_button_pressed")

func _on_ops_button_pressed():
	if mActiveTaskId == -1:
		return
	var task = rcos.get_task(mActiveTaskId)
	if task == null:
		return
	var ops = task.ops
	if ops == null || ops.empty():
		return
	var op = ops[0]
	op[1].call_func()

func _on_task_added(task):
	if task.has("type") && task.type == "widget_factory":
		return
	var items = get_node("items_scroller/items")
	var item = load("res://rcos/wm/taskbar_item.tscn").instance()
	item.add_to_group(mTaskbarItemsGroup)
	item.set_task_id(task.id)
	if task.has("name"):
		item.set_title(task.name)
	if task.has("icon"):
		item.set_icon(task.icon)
	item.hide_title()
	item.connect("selected", self, "_item_selected", [task.id])
	items.add_child(item)

func _on_task_changed(task):
	var items = get_node("items_scroller/items")
	for item in items.get_children():
		if item.get_task_id() == task.id:
			item.set_title(task.name)
			item.set_icon(task.icon)
			return

func _on_task_removed(task):
	var items = get_node("items_scroller/items")
	for item in items.get_children():
		if item.get_task_id() == task.id:
			items.remove_child(item)
			item.queue_free()
			return

func _item_selected(task_id):
	emit_signal("task_selected", task_id)

func show_titles():
	get_tree().call_group(0, mTaskbarItemsGroup, "show_title")

func hide_titles():
	get_tree().call_group(0, mTaskbarItemsGroup, "hide_title")

func mark_active_task(task_id):
	mActiveTaskId = task_id
	var items = get_node("items_scroller/items")
	for item in items.get_children():
		if item.get_task_id() == mActiveTaskId:
			item.mark_active()
		else:
			item.mark_inactive()

func select_task_by_pos(pos):
	var items = get_node("items_scroller/items")
	for item in items.get_children():
		if item.get_global_rect().has_point(pos):
			emit_signal("task_selected", item.get_task_id())
			item.mark_active()
			return
