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

extends Panel

var mScreenTouches = 0

onready var mDesktop = get_node("desktop")
onready var mWindow = get_node("desktop/window")
onready var mTaskbar = get_node("taskbar")

var mActiveTaskId = -1
var mDanglingControls = {}

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_escape()

func _escape():
	var taskbar_was_hidden = mTaskbar.is_hidden()
	mTaskbar.set_hidden(false)
	var properties = rcos.get_task_properties(mActiveTaskId)
	if properties != null \
	&& properties.has("ops") \
	&& properties.ops.has("go_back"):
		var ret = properties.ops["go_back"].call_func()
		if ret:
			return
	if taskbar_was_hidden:
		return
	get_tree().quit()

func _ready():
	connect("resized", self, "_resized")
	rcos.connect("task_added", self, "_on_task_added")
	rcos.connect("task_removed", self, "_on_task_removed")
	rcos.connect("task_changed", self, "_on_task_changed")
	rcos.enable_canvas_input(self)
	mTaskbar.connect("task_selected", self, "show_task")

func _resized():
	if mActiveTaskId != null:
		show_task(mActiveTaskId)
#	var root_canvas = get_node("root_window").get_canvas()
#	if root_canvas == null:
#		return
#	var screen_size = get_viewport().get_rect().size
#	if OS.get_model_name() == "GenericDevice":
#		root_canvas.resize(screen_size)
#	else:
#		var screen_num = OS.get_current_screen()
#		var dpi = OS.get_screen_dpi(screen_num)
#		var root_canvas_size = screen_size * (120.0/dpi)
#		root_canvas.resize(root_canvas_size)

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	var dangling_control = rcos.gui.get_dangling_control(index)
	if dangling_control == null:
		return
	dangling_control.set_pos(event.pos - dangling_control.get_size()/2)
	if mTaskbar.get_rect().has_point(event.pos):
		mTaskbar.select_task_by_pos(event.pos)

func _on_task_added(task):
	mTaskbar.add_task(task)
	show_task(task.get_id())

func _on_task_removed(task):
	mTaskbar.remove_task(task)
	var parent_task = task.get_parent()
	if parent_task != rcos.get_node("tasks"):
		show_task(parent_task.get_id())
	elif task.get_index() > 0:
		var sibling_task = parent_task.get_child(task.get_index()-1)
		show_task(sibling_task.get_id())
	show_task(-1)

func _on_task_changed(task):
	mTaskbar.change_task(task)
	if task.get_id() == mActiveTaskId:
		show_task(task.get_id())

func show_task(task_id):
	var properties = rcos.get_task_properties(task_id)
	if properties == null:
		return
	if !properties.has("canvas"):
		return
	mActiveTaskId = task_id
	var canvas = properties.canvas
	var fullscreen = false
	var frame_rect = Rect2(Vector2(0, 0), mDesktop.get_rect().size)
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
	mTaskbar.set_hidden(fullscreen)
	mTaskbar.mark_active_task(task_id)

func pick_up_control(control, index):
	if control == null:
		return
	# Don't "pick up" the control if the screen isn't touched.
	var pos = get_viewport().get_screen_touch_pos(index)
	if pos == null:
		control.queue_free()
		return
	if mDanglingControls.has(index):
		var old_control = mDanglingControls[index]
		get_node("overlay/dangling_controls").remove_child(old_control)
		old_control.queue_free()
		mDanglingControls.erase(index)
	control.get_parent().remove_child(control)
	get_node("overlay/dangling_controls").add_child(control)
	control.set_pos(pos - control.get_size()/2)
	mDanglingControls[index] = control
	if mDanglingControls.size() > 0:
		rcos.enable_canvas_input(self)
	else:
		rcos.disable_canvas_input(self)

func get_dangling_control(index):
	if mDanglingControls.has(index):
		return mDanglingControls[index]
	else:
		return null
