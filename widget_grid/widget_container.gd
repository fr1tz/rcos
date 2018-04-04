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
var mReshapeControl = null
var mWidget = null

onready var mContent = get_node("content")
onready var mWidgetWindow = get_node("widget_window")

func _ready():
	mReshapeControl = get_node("reshape_control")
	mReshapeControl.set_control(self)

func init(widget_host_api, widget):
	if widget == null || !widget.has_node("main_canvas"):
		return
	mWidget = widget
	var main_canvas = null
	var main_canvas_size = Vector2(40, 40)
	var config_canvas = null
	var config_canvas_size = Vector2(40, 40)
	var main_canvas_placeholder = mWidget.get_node("main_canvas")
	main_canvas_size.x = main_canvas_placeholder.get_margin(MARGIN_RIGHT)
	main_canvas_size.y = main_canvas_placeholder.get_margin(MARGIN_BOTTOM)
	main_canvas = rlib.instance_scene("res://rcos/lib/canvas.tscn")
	main_canvas_placeholder.replace_by(main_canvas)
	main_canvas_placeholder.queue_free()
	main_canvas.set_rect(Rect2(Vector2(0, 0), main_canvas_size))
	main_canvas.set_name("main_canvas")
	if mWidget.has_node("config_canvas"):
		var config_canvas_placeholder = mWidget.get_node("config_canvas")
		config_canvas_size.x = config_canvas_placeholder.get_margin(MARGIN_RIGHT)
		config_canvas_size.y = config_canvas_placeholder.get_margin(MARGIN_BOTTOM)
		config_canvas = rlib.instance_scene("res://rcos/lib/canvas.tscn")
		config_canvas_placeholder.replace_by(config_canvas)
		config_canvas_placeholder.queue_free()
		config_canvas.set_rect(Rect2(Vector2(0, 0), config_canvas_size))
		config_canvas.set_name("config_canvas")
	mWidget.set_meta("widget_host_api", widget_host_api)
	mContent.add_child(mWidget)
	
	if config_canvas:
		config_canvas.set_rect(Rect2(Vector2(0, 0), config_canvas.get_child(0).get_size()))
	var size = get_widget_canvas().get_rect().size
	set_size(size)
	mWidgetWindow.set_pos(Vector2(0, 0))
	mWidgetWindow.set_size(size)
	mWidgetWindow.show_canvas(mWidget.get_node("main_canvas"))

func toggle_edit_mode(edit_mode):
	mEditMode = edit_mode
	mReshapeControl.set_hidden(!edit_mode)

func get_widget_canvas():
	return mWidget.get_node("main_canvas")

func get_config_canvas():
	return mWidget.get_node("config_canvas")

func get_widget_window():
	return mWidgetWindow

func get_reshape_control():
	return mReshapeControl

func rotate():
	# Adjust container rect
	var pos = get_pos()
	var size = get_size()
	var center = pos + size/2
	size = Vector2(size.y, size.x)
	pos = center - size/2
	set_size(size)
	set_pos(pos)
	# Adjust widget window
	center = get_size()/2
	size = mWidgetWindow.get_size()
	var rot = mWidgetWindow.get_rotation_deg()
	if rot == 0:
		rot = 270
		pos = center + Vector2(size.y, -size.x)/2
	elif rot == 270:
		rot = 180
		pos = center + Vector2(size.x, size.y)/2
	elif rot == 180:
		rot = 90
		pos = center + Vector2(-size.y, size.x)/2
	else:
		rot = 0
		pos = Vector2(0, 0)
	mWidgetWindow.set_rotation_deg(rot)
	mWidgetWindow.set_pos(pos)
