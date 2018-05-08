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

var mActiveTask = null

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_escape()

func _escape():
	var taskbar_was_hidden = mTaskbar.is_hidden()
	mTaskbar.set_hidden(false)
	if mActiveTask.has("ops") && mActiveTask.ops.has("go_back"):
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
	connect("resized", self, "_resized")
	rcos.connect("task_changed", self, "_on_task_changed")
	rcos.connect("task_list_changed", self, "_on_task_list_changed")
	mTaskbar.connect("task_selected", self, "show_task")
	#set_process_input(true)

func _resized():
	if mActiveTask != null:
		show_task(mActiveTask.id)
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

func _on_task_changed(task):
	if task == mActiveTask:
		show_task(task.id)

func _on_task_list_changed():
	var task_list = rcos.get_task_list()
	if mActiveTask == null:
		var task_id = task_list[task_list.size()-1].id
		show_task(task_id)

func show_task(task_id):
	var task = rcos.get_task(task_id)
	if task == null:
		return
	mActiveTask = task
	var canvas = mActiveTask.canvas
	var fullscreen = false
	var frame_rect = Rect2(Vector2(0, 0), mDesktop.get_rect().size)
	if mActiveTask.has("fullscreen") && mActiveTask.fullscreen:
		fullscreen = true
		frame_rect = Rect2(Vector2(0, 0), get_rect().size)
	var window_rotated = false
	var window_rect = Rect2(Vector2(0, 0), canvas.get_rect().size)
	if mActiveTask.has("canvas_region") && mActiveTask.canvas_region != null:
		window_rect = Rect2(Vector2(0, 0), mActiveTask.canvas_region.size)
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
	if mActiveTask.has("canvas_region"):
		canvas_region = mActiveTask.canvas_region
	mWindow.show_canvas(canvas, canvas_region)
	mTaskbar.set_hidden(fullscreen)
	mTaskbar.mark_active_task(task_id)
