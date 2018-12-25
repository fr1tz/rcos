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

export(bool) var debug = false
export(Vector2) var min_size_isquares = Vector2(0, 0)
export(Vector2) var default_size_isquares = Vector2(5, 5)
export(bool) var resizable = true

const NUM_INPUTS = 8

var mDisplays = [] # List of windows that show this canvas
var mNextInputEventId = 0
var mInputs = Array()

func _init():
	add_user_signal("display")
	add_user_signal("conceal")

func _exit_tree():
	for display in mDisplays:
		display.show_canvas(null)
	mDisplays.clear()

func _ready():
	add_to_group("canvas_group")
	mInputs.resize(NUM_INPUTS)
	for i in range(0, NUM_INPUTS):
		var input = {
			"index": i,
			"fpos": Vector2(0, 0),
			"down": false
		}
		mInputs[i] = input

func _call_canvas_input(event):
	var input_group = "_canvas_input"+str(get_instance_ID())
	if get_tree().has_group(input_group):
		get_tree().call_group(1|2|8, input_group, "_canvas_input", event)

func get_next_input_event_id():
	mNextInputEventId += 1
	return mNextInputEventId

func send_key_event(ev):
	ev.ID = get_next_input_event_id()
	if debug:
		prints(get_name(), "send_key_event(): calling input():", ev)
	input(ev)
	_call_canvas_input(ev)

func get_input_fpos(index):
	return mInputs[index].fpos

func get_input_down(index):
	return mInputs[index].down

func copy_inputs(from_canvas):
	for i in range(0, NUM_INPUTS):
		mInputs[i].index = from_canvas.mInputs[i].index
		mInputs[i].fpos = from_canvas.mInputs[i].fpos
		mInputs[i].down = from_canvas.mInputs[i].down

func update_input(index, fpos, down):
	var input = mInputs[index]
	var prev_fpos = input.fpos
	var prev_down = input.down
	if fpos != null:
		input.fpos = fpos
	if down != null:
		input.down = down
	var pos = input.fpos
	var rpos = pos - prev_fpos
	var down = input.down
	# Use index 0 to simulate mouse input events.
	if index == 0:
		if down != prev_down:
			var ev = InputEvent()
			ev.type = InputEvent.MOUSE_BUTTON
			ev.ID = get_next_input_event_id()
			ev.button_mask = 1
			ev.pos = pos
			ev.x = ev.pos.x
			ev.y = ev.pos.y
			ev.button_index = 1
			ev.pressed = down
			if debug:
				prints(get_name(), "update_input(): calling input():", ev)
			input(ev)
		elif down && prev_down:
			var ev = InputEvent()
			ev.type = InputEvent.MOUSE_MOTION
			ev.ID = get_next_input_event_id()
			ev.button_mask = 1
			ev.pos = pos
			ev.x = ev.pos.x
			ev.y = ev.pos.y
			ev.relative_pos = rpos
			ev.relative_x = ev.relative_pos.x
			ev.relative_y = ev.relative_pos.y
			ev.speed = ev.relative_pos
			ev.speed_x = ev.relative_pos.x
			ev.speed_y = ev.relative_pos.y
			if debug:
				prints(get_name(), "update_input(): calling input():", ev)
			input(ev)
	# Produce touchscreen input events.
	if down && prev_down:
		var ev = InputEvent()
		ev.type = InputEvent.SCREEN_DRAG
		ev.device = 0
		ev.ID = get_next_input_event_id()
		ev.index = index
		ev.pos = pos
		ev.x = pos.x
		ev.y = pos.y
		ev.relative_pos = rpos
		ev.relative_x = rpos.x
		ev.relative_y = rpos.y
		ev.speed = rpos
		ev.speed_x = rpos.x
		ev.speed_y = rpos.y
		_call_canvas_input(ev)
#		var ev = {
#			type = InputEvent.SCREEN_DRAG,
#			device = 0,
#			ID = get_next_input_event_id(),
#			index = index,
#			pos = pos,
#			x = pos.x,
#			y = pos.y,
#			relative_pos = rpos,
#			relative_x = rpos.x,
#			relative_y = rpos.y,
#			speed = rpos,
#			speed_x = rpos.x,
#			speed_y = rpos.y,
#		}
#		_call_canvas_input(ev)
	else:
		var ev = InputEvent()
		ev.type = InputEvent.SCREEN_TOUCH
		ev.device = 0
		ev.ID = get_next_input_event_id()
		ev.index = index
		ev.pos = pos
		ev.x = pos.x
		ev.y = pos.y
		ev.pressed = down
		_call_canvas_input(ev)
#		var ev = {
#			type = InputEvent.SCREEN_TOUCH,
#			device = 0,
#			ID = get_next_input_event_id(),
#			index = index,
#			pos = pos,
#			x = pos.x,
#			y = pos.y,
#			pressed = down,
#		}
#		_call_canvas_input(ev)

func add_display(window):
	mDisplays.append(window)

func remove_display(window):
	mDisplays.erase(window)

func is_displayed():
	for window in mDisplays:
		var vp = window.get_viewport()
		if vp == get_node("/root"):
			return true
		if vp.has_method("is_displayed") && vp.is_displayed():
			return true
	return false

func resize(size):
	if !resizable:
		return
	var isquare_size = rcos_gui.get_isquare_size()
	var min_size_x = min_size_isquares.x * isquare_size
	var min_size_y = min_size_isquares.y * isquare_size
	size.x = max(min_size_x, size.x)
	size.y = max(min_size_y, size.y)
	set_rect(Rect2(Vector2(0, 0), size))
