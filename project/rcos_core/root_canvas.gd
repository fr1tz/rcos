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

extends Viewport

var _default_target_fps = 30
var _max_target_fps = 120
var _screen_inputs = []
var _num_screen_inputs_down = 0
var _last_input_event_id = 0

func _init():
	for i in range(0, rcos_gui.NUM_SCREEN_INPUTS):
		_screen_inputs.push_back(Vector2(0, 0))

func _input(event):
	_last_input_event_id = event.ID
	if event.type == InputEvent.KEY:
		if event.scancode == KEY_F11 && event.pressed:
			if OS.is_window_fullscreen():
				OS.set_window_fullscreen(false)
				OS.set_borderless_window(false)
			else:
				OS.set_window_fullscreen(true)
			return
		if  rcos_gui.__ActiveCanvas != null:
			rcos_gui.__ActiveCanvas.send_key_event(event)
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var screen_input_index = rcos_gui.SCREEN_INPUT_MOUSE
	if touchscreen:
		screen_input_index = event.index
	var from_user = event.device >= 0
	if from_user:
		if drag:
			_screen_inputs[screen_input_index] = event.pos
		elif touch:
			if event.pressed:
				_screen_inputs[screen_input_index] = event.pos
				_num_screen_inputs_down += 1
			else:
				_screen_inputs.erase(screen_input_index)
				_num_screen_inputs_down -= 1
			#prints("root_canvas:", event, "->", _num_screen_inputs_down)
			if _num_screen_inputs_down > 0:
				OS.set_target_fps(_max_target_fps)
			else:
				OS.set_target_fps(_default_target_fps)
	var group = "_canvas_input"+str(get_instance_ID())
	if get_tree().has_group(group):
		var flags = get_tree().GROUP_CALL_REALTIME
		get_tree().call_group(flags, group, "_canvas_input", event)

func __set_default_target_fps(fps):
	_default_target_fps = fps
	if _num_screen_inputs_down > 0:
		OS.set_target_fps(_max_target_fps)
	else:
		OS.set_target_fps(_default_target_fps)

func __set_max_target_fps(fps):
	_max_target_fps = fps
	if _num_screen_inputs_down > 0:
		OS.set_target_fps(_max_target_fps)
	else:
		OS.set_target_fps(_default_target_fps)

func get_next_input_event_id():
	return _last_input_event_id + 1

func is_displayed():
	return true

# Deprecated
func get_screen_touch_pos(index):
	return get_screen_input_pos(index)

func get_screen_input_pos(index):
	if _screen_inputs.has(index):
		return _screen_inputs[index]
	return null

func initialize():
	add_to_group("canvas_group")
	set_process_input(true)