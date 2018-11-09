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

var mDanglingControls = {}

func _ready():
	var color = Globals.get("application/boot_bg_color")
	set_frame_color(color)

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if !mDanglingControls.has(index):
		return
	var dangling_control = mDanglingControls[index]
	dangling_control.set_pos(event.pos - dangling_control.get_size()/2)
	if touch && !event.pressed:
		get_node("overlay/dangling_controls").remove_child(dangling_control)
		dangling_control.free()
		mDanglingControls.erase(index)
		if mDanglingControls.size() == 0:
			rcos.disable_canvas_input(self)

func pick_up_control(control, index): # deprecated
	set_dangling_control(index, control)

func set_dangling_control(index, control):
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
