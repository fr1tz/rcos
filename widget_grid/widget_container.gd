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

onready var mWidgetCanvas = get_node("widget_canvas")
onready var mWidgetWindow = get_node("widget_window")

func _ready():
	mReshapeControl = get_node("reshape_control")
	mReshapeControl.set_control(self)

func init(widget_package):
	var mWidget = widget_package.get_node("widget")
	if mWidget == null:
		return
	widget_package.set_name("widget_package")
	add_child(widget_package)
	widget_package.remove_child(mWidget)
	mWidgetCanvas.set_rect(Rect2(Vector2(0, 0), mWidget.get_size()))
	mWidgetCanvas.add_child(mWidget)
	set_size(mWidget.get_size())
	mWidgetWindow.set_pos(Vector2(0, 0))
	mWidgetWindow.set_size(mWidget.get_size())

func toggle_edit_mode(edit_mode):
	mEditMode = edit_mode
	mReshapeControl.set_hidden(!edit_mode)

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
