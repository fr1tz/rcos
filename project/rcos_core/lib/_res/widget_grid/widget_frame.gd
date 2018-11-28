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

export(bool) var debug = false

const NUM_INPUTS = 8

var mNextInputEventId = 0
var mInputs = Array()

func _ready():
	add_to_group("widget_frame_group")
	mInputs.resize(NUM_INPUTS)
	for i in range(0, NUM_INPUTS):
		var input = {
			"index": i,
			"fpos": Vector2(0, 0),
			"down": false
		}
		mInputs[i] = input

func _call_widget_frame_input(event):
	var input_group = "_widget_frame_input"+str(get_instance_ID())
	if get_tree().has_group(input_group):
		get_tree().call_group(1|2|8, input_group, "_widget_frame_input", event)

func get_next_input_event_id():
	mNextInputEventId += 1
	return mNextInputEventId

func get_input_fpos(index):
	return mInputs[index].fpos

func get_input_down(index):
	return mInputs[index].down

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
		_call_widget_frame_input(ev)
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
		_call_widget_frame_input(ev)

func enable_widget_frame_input(node):
	if !is_a_parent_of(node):
		return false
	var input_group = "_widget_frame_input"+str(get_instance_ID())
	node.add_to_group(input_group)
	return true

func disable_widget_frame_input(node):
	var input_group = "_widget_frame_input"+str(get_instance_ID())
	node.remove_from_group(input_group)
	return true
