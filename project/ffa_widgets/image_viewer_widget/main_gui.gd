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

extends Panel

var mWidgetHost = null
var mIOPorts = null
var mImage = null
var mTexture = null

func _ready():
	mWidgetHost = get_meta("widget_host_api")
	mWidgetHost.enable_widget_frame_input(self)

func _draw():
	if mTexture == null:
		return
	draw_texture_rect(mTexture, get_rect(), false)

func _widget_frame_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if touch && !event.pressed:
		var dangling_control = rcos.gui.get_dangling_control(index)
		if dangling_control != null:
			_dangling_control_dropped(dangling_control)

func _dangling_control_dropped(control):
	if !control.has_meta("data"):
		return
	var data = control.get_meta("data")
	if typeof(data) == TYPE_IMAGE:
		set_image(data)

func set_image(image):
	if image == null:
		return
	if mTexture == null:
		mTexture = ImageTexture.new()
	mTexture.create_from_image(image, Texture.FLAG_FILTER)
	update()

func initialize(io_ports):
	mIOPorts = io_ports
