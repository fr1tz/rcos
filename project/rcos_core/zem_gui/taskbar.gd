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

onready var mTaskbarItemsGroup = "taskbar_items_"+str(get_instance_ID())

var mItemsByCanvas = {}

func _ready():
	rcos_tasks.connect("task_added", self, "_on_task_added")
	rcos_tasks.connect("task_removed", self, "_on_task_removed")
	rcos_gui.connect("active_canvas_changed", self, "_active_canvas_changed")
	connect("resized", self, "_resized")
	var items_scroller = get_node("scroller")
	items_scroller.connect("scrolling_started", self, "show_titles")
	items_scroller.connect("scrolling_stopped", self, "hide_titles")
	_resized()

func _resized():
	var isquare_size = rcos.get_isquare_size()
	for item in get_node("scroller/items").get_children():
		item.set_custom_minimum_size(Vector2(isquare_size, isquare_size))

func _active_canvas_changed(canvas):
	get_tree().call_group(SceneTree.GROUP_CALL_REALTIME, mTaskbarItemsGroup, "mark_inactive")
	if canvas != null:
		mItemsByCanvas[canvas].mark_active()

func _on_task_added(task):
	if !task.properties.has("canvas"):
		return
	var items = get_node("scroller/items")
	var item = load("res://rcos_core/zem_gui/taskbar_item.tscn").instance()
	var isquare_size = rcos.get_isquare_size()
	item.set_custom_minimum_size(Vector2(isquare_size, isquare_size))
	item.add_to_group(mTaskbarItemsGroup)
	item.initialize(task)
	item.hide_title()
	var parent_task_id = task.get_parent_task_id()
	if parent_task_id == 0:
		items.add_child(item)
	else:
		for i in range(items.get_child_count()-1, 0, -1):
			var c = items.get_child(i)
			if c.get_parent_task_id() == parent_task_id \
			|| c.get_task_id() == parent_task_id:
				items.add_child(item)
				items.move_child(item, i+1)
				break
	mItemsByCanvas[task.properties.canvas] = item

func _on_task_removed(task):
	if !task.properties.has("canvas"):
		return
	mItemsByCanvas.erase(task.properties.canvas)
	var items = get_node("scroller/items")
	for item in items.get_children():
		if item.get_task_id() == task.get_id():
			items.remove_child(item)
			item.queue_free()
			return

func activate_task_by_pos(pos):
	var items = get_node("scroller/items")
	for item in items.get_children():
		if item.get_global_rect().has_point(pos):
			item._pressed()
			return

func show_titles():
	get_tree().call_group(0, mTaskbarItemsGroup, "show_title")

func hide_titles():
	get_tree().call_group(0, mTaskbarItemsGroup, "hide_title")

func get_num_task_items():
	return get_node("scroller/items").get_child_count()
