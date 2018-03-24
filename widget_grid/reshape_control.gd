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

const MODE_INACTIVE = 0
const MODE_MOVE = 1

export(Color) var mDefaultColor = Color(0, 1, 0, 1)
export(Color) var mSelectedColor = Color(1, 0, 0, 1)
var mControl = null
var mMode = MODE_INACTIVE

func _init():
	add_user_signal("clicked")

func _ready():
	deselect()

func _input_event(event):
	if event.type == InputEvent.MOUSE_BUTTON:
		if event.pressed:
			emit_signal("clicked")
			_set_mode(MODE_MOVE)
		else:
			_set_mode(MODE_INACTIVE)
	elif event.type == InputEvent.MOUSE_MOTION:
		if mMode == MODE_MOVE:
			var vec = event.relative_pos
			mControl.set_pos(mControl.get_pos() + vec)

func _set_mode(mode):
	mMode = mode

func _update_control():
	mControl.set_pos(get_pos())
	mControl.set_size(get_size())
	mControl.set_rotation(get_rotation())

func get_control():
	return mControl

func set_control(control):
	mControl = control

func select():
	get_node("color").set_frame_color(mSelectedColor)

func deselect():
	get_node("color").set_frame_color(mDefaultColor)
