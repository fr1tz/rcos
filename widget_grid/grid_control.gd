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

var mWidgetHostApi = null
var mOverlayDrawNodes = {}
var mEditMode = false
var mSelectedWidgetContainer = null

onready var mWidgetContainers = get_node("widget_containers")
onready var mOverlay = get_node("overlay")

func _ready():
	mWidgetHostApi = preload("widget_host_api.gd").new(self)

func _on_reshape_control_clicked(reshape_control):
	if mSelectedWidgetContainer != null:
		if reshape_control == mSelectedWidgetContainer.get_reshape_control():
			return
	if mSelectedWidgetContainer:
		mSelectedWidgetContainer.get_reshape_control().deselect()
	mSelectedWidgetContainer = reshape_control.get_control()
	reshape_control.select()

func add_widget(widget_factory_task_id, pos):
	var task = rcos.get_task(widget_factory_task_id)
	var widget = task.create_widget_func.call_func()
	if widget == null:
		return
	var widget_container = rlib.instance_scene("res://widget_grid/widget_container.tscn")
	mWidgetContainers.add_child(widget_container)
	widget_container.init(mWidgetHostApi, widget)
	widget_container.set_pos(pos)
	widget_container.toggle_edit_mode(mEditMode)
	widget_container.connect("item_rect_changed", self, "update_size")
	var reshape_control = widget_container.get_reshape_control()
	reshape_control.connect("clicked", self, "_on_reshape_control_clicked", [reshape_control])
	update_size()

func toggle_edit_mode(edit_mode):
	mEditMode = edit_mode
	for widget_container in mWidgetContainers.get_children():
		widget_container.toggle_edit_mode(edit_mode)

func update_size():
	var w = 0
	var h = 0
	for widget_container in mWidgetContainers.get_children():
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
	if pos != mWidgetContainers.get_child_count() - 1:
		pos = mWidgetContainers.get_child_count() - 1
	else:
		pos = 0
	mWidgetContainers.move_child(mSelectedWidgetContainer, pos)

func rotate_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.rotate()

func configure_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.configure()

func delete_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.queue_free()
	mSelectedWidgetContainer = null
	update_size()

func enable_overlay_draw(node):
	if mOverlayDrawNodes.has(node):
		return
	if !node.has_method("_overlay_draw"):
		return
	var widget_container = null
	for c in mWidgetContainers.get_children():
		if c.is_a_parent_of(node):
			widget_container = c
			break
	if widget_container == null:
		return
	mOverlayDrawNodes[node] = widget_container

func disable_overlay_draw(node):
	mOverlayDrawNodes.erase(node)

func remove_painter(node):
	mOverlayDrawNodes.erase(node)

func update_overlay_draw():
	mOverlay.update()

func draw_overlay():
	for node in mOverlayDrawNodes.keys():
		var widget_container = mOverlayDrawNodes[node]
		var window = widget_container.get_widget_window()
		var window_size = window.get_size()
		var canvas_size = window.get_canvas().get_rect().size
		var pos = widget_container.get_pos() + window.get_pos()
		var rot = window.get_rotation()
		var scale = window_size / canvas_size
		var orientation = widget_container.get_widget_orientation()
		if orientation == 1 || orientation == 3:
			var x = scale.x
			scale.x = scale.y
			scale.y = x
		mOverlay.draw_set_transform(pos, rot, scale)
		node._overlay_draw(mOverlay)
