# Copyright © 2018 Michael Goldener <mg@wasted.ch>
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

onready var mWindow = get_node("window")

var mTasksByCanvas = {}
var mVisibleTask = null

func _ready():
	rcos_tasks.connect("task_added", self, "_task_added")
	rcos_tasks.connect("task_removed", self, "_task_removed")
	rcos_gui.connect("active_canvas_changed", self, "_active_canvas_changed")
	connect("resized", self, "_resized")

func _resized():
	_show_task(mVisibleTask)

func _active_canvas_changed(canvas):
	if canvas:
		_show_task(mTasksByCanvas[canvas])
	else:
		mWindow.set_hidden(true)

func _task_added(task):
	if task.properties.has("canvas"):
		mTasksByCanvas[task.properties.canvas] = task
		task.connect("properties_changed", self, "_task_properties_changed", [task])
		_show_task(task)

func _task_removed(task):
	if task.properties.has("canvas"):
		mTasksByCanvas.erase(task.properties.canvas)
		if task == mVisibleTask:
			mVisibleTask = null
			mWindow.set_hidden(true)

func _task_properties_changed(new_properties, task):
	if new_properties.has("window_raise") && new_properties.window_raise:
		task.properties.erase("window_raise")
		_show_task(task)

func _show_task(task):
	if task == null:
		return
	var properties = task.properties
	if properties == null:
		return
	if !properties.has("canvas"):
		return
	var canvas = properties.canvas
	var fullscreen = false
	var frame_rect = Rect2(Vector2(0, 0), get_rect().size)
	if properties.has("fullscreen") && properties.fullscreen:
		fullscreen = true
		frame_rect = Rect2(Vector2(0, 0), get_rect().size)
	var window_rotated = false
	var window_rect = Rect2(Vector2(0, 0), canvas.get_rect().size)
	if properties.has("canvas_region") && properties.canvas_region != null:
		window_rect = Rect2(Vector2(0, 0), properties.canvas_region.size)
	if canvas.resizable:
		mWindow.set_rotation_deg(0)
		if canvas.min_size.x > frame_rect.size.x \
		|| canvas.min_size.y > frame_rect.size.y:
			canvas.resize(canvas.min_size)
			var aspect = frame_rect.size / canvas.min_size
			window_rect.size = canvas.min_size * min(aspect.x, aspect.y)
			var pos = frame_rect.size/2 - window_rect.size/2
			mWindow.set_pos(pos)
			mWindow.set_size(Vector2(window_rect.size.x, window_rect.size.y))
		else: 
			canvas.resize(frame_rect.size)
			mWindow.set_pos(frame_rect.pos)
			mWindow.set_size(frame_rect.size)
	else:
		if window_rect.size.x > window_rect.size.y \
		&& window_rect.size.x > frame_rect.size.x:
			window_rotated = true
			var x = window_rect.size.y 
			var y = window_rect.size.x
			window_rect.size = Vector2(x, y)
		var aspect = frame_rect.size / window_rect.size
		window_rect.size *= min(aspect.x, aspect.y)
		if window_rotated:
			var pos = frame_rect.size/2 - window_rect.size/2 
			pos.x += window_rect.size.x 
			mWindow.set_pos(pos)
			mWindow.set_rotation_deg(-90)
			mWindow.set_size(Vector2(window_rect.size.y, window_rect.size.x))
		else:
			var pos = frame_rect.size/2 - window_rect.size/2
			mWindow.set_pos(pos)
			mWindow.set_rotation_deg(0)
			mWindow.set_size(Vector2(window_rect.size.x, window_rect.size.y))
	var canvas_region = canvas.get_rect()
	if properties.has("canvas_region"):
		canvas_region = properties.canvas_region
	mWindow.show_canvas(canvas, canvas_region)
	mWindow.set_hidden(false)
	mVisibleTask = task

