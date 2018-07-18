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

const DEFAULT_TARGET_FPS = 30
const MAX_TARGET_FPS = 120

var mScreenTouches = {}
var mNumScreenTouches = 0
var mLastInputEventId = 0

func _ready():
	add_to_group("canvas_group")
	set_process_input(true)

func _input(event):
	mLastInputEventId = event.ID
	if event.type == InputEvent.MOUSE_BUTTON && event.button_mask > 1:
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	var index = 0
	if touchscreen:
		index = event.index
	var from_user = event.device >= 0
	if from_user:
		if drag:
			mScreenTouches[index] = event.pos
		elif touch:
			if event.pressed:
				mScreenTouches[index] = event.pos
				mNumScreenTouches += 1
			else:
				mScreenTouches.erase(index)
				mNumScreenTouches -= 1
			#prints("root_canvas:", event, "->", mNumScreenTouches)
			if mNumScreenTouches > 0:
				OS.set_target_fps(MAX_TARGET_FPS)
			else:
				OS.set_target_fps(DEFAULT_TARGET_FPS)
	var group = "_canvas_input"+str(get_instance_ID())
	if get_tree().has_group(group):
		get_tree().call_group(1|2|8, group, "_canvas_input", event)

func get_next_input_event_id():
	return mLastInputEventId + 1

func is_displayed():
	return true

func get_screen_touch_pos(index):
	if mScreenTouches.has(index):
		return mScreenTouches[index]
	return null
