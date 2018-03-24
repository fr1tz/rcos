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

extends ColorFrame

var mEditMode = false
var mSelectedWidgetContainer = null

func add_widget(task_id, pos):
	var task = rcos.get_task(task_id)
	var widget_package = task.create_widget_packet.call_func()
	if widget_package == null:
		return
	var widget_container = rlib.instance_scene("res://widget_grid/widget_container.tscn")
	add_child(widget_container)
	var reshape_control = widget_container.get_reshape_control()
	reshape_control.connect("clicked", self, "_on_reshape_control_clicked", [reshape_control])
	widget_container.init(widget_package)
	widget_container.set_pos(pos)
	widget_container.toggle_edit_mode(mEditMode)
	widget_container.connect("item_rect_changed", self, "update_size")

func _on_reshape_control_clicked(reshape_control):
	if mSelectedWidgetContainer != null:
		if reshape_control == mSelectedWidgetContainer.get_reshape_control():
			return
	if mSelectedWidgetContainer:
		mSelectedWidgetContainer.get_reshape_control().deselect()
	mSelectedWidgetContainer = reshape_control.get_control()
	reshape_control.select()

func toggle_edit_mode(edit_mode):
	mEditMode = edit_mode
	for widget_container in get_children():
		widget_container.toggle_edit_mode(edit_mode)

func update_size():
	var w = 0
	var h = 0
	for widget_container in get_children():
		var rect = widget_container.get_rect()
		var p = rect.pos + rect.size
		if p.x > w: w = p.x
		if p.y > h: h = p.y
	set_size(Vector2(w, h))

func get_selected_widget_container():
	return mSelectedWidgetContainer

func raiselower_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	var pos = mSelectedWidgetContainer.get_position_in_parent()
	if pos != get_child_count() - 1:
		pos = get_child_count() - 1
	else:
		pos = 0
	move_child(mSelectedWidgetContainer, pos)

func rotate_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.rotate()

func delete_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.queue_free()
	mSelectedWidgetContainer = null
	update_size()
