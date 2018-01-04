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

extends TextureFrame

export(bool) var root_window
export(NodePath) var canvas

var mCanvas = null
var mActiveIndex = -1
var mNextViewportInputEventId = 0

func _init():
	add_user_signal("scrolling_started")
	add_user_signal("scrolling_stopped")

func _ready():
	if canvas != null && !canvas.is_empty():
		set_canvas(get_node(canvas))

func _canvas_input(event):
	if !is_visible():
		return
	if event.type == InputEvent.KEY:
		mCanvas.send_key_event(event)
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	var rect = get_global_rect()
	if !rect.has_point(event.pos):
		mCanvas.update_input(index, null, false)
		return
	var display_size = Vector2(rect.size.width, rect.size.height)
	var win_size = Vector2(mCanvas.get_rect().size.width, mCanvas.get_rect().size.height)
	var scale = win_size / display_size
	var display_pos = event.pos - rect.pos
	var win_pos = display_pos * scale
	var fpos = win_pos
	var down = null
	if touch:
		down = event.pressed
	mCanvas.update_input(index, fpos, down)

func show_canvas(canvas):
	#print("window: show_canvas(): ", canvas)
	if canvas == mCanvas:
		return
	var was_displayed_list = {}
	for canvas in get_tree().get_nodes_in_group("canvas_group"):
		was_displayed_list[canvas] = canvas.is_displayed()
	if mCanvas != null:
		mCanvas.remove_display(self)
	mCanvas = canvas
	if mCanvas == null:
		set_texture(null)
		rcos.disable_canvas_input(self)
	else:
		mCanvas.add_display(self)
		set_texture(mCanvas.get_render_target_texture())
		rcos.enable_canvas_input(self)
	#print(">>>>>>>>>")
	for canvas in get_tree().get_nodes_in_group("canvas_group"):
		var was_displayed = was_displayed_list[canvas]
		var is_displayed = canvas.is_displayed()
		#prints(canvas.get_path(), was_displayed, "->", is_displayed)
		if !was_displayed && is_displayed:
			canvas.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_WHEN_VISIBLE)
			canvas.emit_signal("display")
		elif was_displayed && !is_displayed:
			canvas.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_DISABLED)
			canvas.emit_signal("conceal")

func has_canvas():
	return mCanvas != null
