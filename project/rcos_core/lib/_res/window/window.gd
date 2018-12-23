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

extends Control

export(bool) var debug
export(NodePath) var canvas

var mCanvas = null
var mCanvasRegion = null
var mActiveIndex = -1
var mNextViewportInputEventId = 0

func _init():
	add_user_signal("scrolling_started")
	add_user_signal("scrolling_stopped")

func _ready():
	if canvas != null && !canvas.is_empty():
		show_canvas(get_node(canvas))

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
	var win_rect = get_global_rect()
	event.pos = win_rect.pos + (event.pos - win_rect.pos).rotated(-get_rotation())
	if mCanvas.get_input_down(index) == false && !win_rect.has_point(event.pos):
		mCanvas.update_input(index, null, false)
		return
	var region_rect = _get_canvas_region()
	var win_size = Vector2(win_rect.size.width, win_rect.size.height)
	var region_size = Vector2(region_rect.size.width, region_rect.size.height)
	var scale = region_size / win_size
	var win_pos = event.pos - win_rect.pos
	var canvas_pos = win_pos*scale + region_rect.pos
	var fpos = canvas_pos
	var down = null
	#prints(win_rect.pos, win_pos, canvas_pos)
	if touch:
		down = event.pressed
	mCanvas.update_input(index, fpos, down)

func _draw():
	var rect = Rect2(Vector2(0, 0), get_rect().size)
	if mCanvas == null:
		draw_rect(rect, Color(1, 0, 1, 1))
		return
	var texture = mCanvas.get_render_target_texture()
	var src_rect = _get_canvas_region()
	var modulate = Color(1, 1, 1, 1)
	var transpose = false
	draw_texture_rect_region(texture, rect, src_rect, modulate, transpose)

func _get_canvas_region():
	if mCanvas == null:
		return Rect2(0, 0, 0, 0)
	if mCanvasRegion == null:
		var texture = mCanvas.get_render_target_texture()
		return Rect2(0, 0, texture.get_width(), texture.get_height())
	else:
		return mCanvasRegion

func show_canvas(canvas, region = null):
	#prints("window: show_canvas(): ", canvas, region)
	if canvas == mCanvas && region == mCanvasRegion:
		return
	var old_canvas = mCanvas
	var was_displayed_list = {}
	for canvas in get_tree().get_nodes_in_group("canvas_group"):
		was_displayed_list[canvas] = canvas.is_displayed()
	if mCanvas != null:
		mCanvas.remove_display(self)
	mCanvas = canvas
	if mCanvas == null:
		mCanvasRegion = null
		rcos.disable_canvas_input(self)
	else:
		mCanvasRegion = region
		if old_canvas != null:
			mCanvas.copy_inputs(old_canvas)
		mCanvas.add_display(self)
		rcos.enable_canvas_input(self)
	update()
	#print(">>>>>>>>>")
	for canvas in get_tree().get_nodes_in_group("canvas_group"):
		var was_displayed = was_displayed_list[canvas]
		var is_displayed = canvas.is_displayed()
		#prints(canvas.get_path(), was_displayed, "->", is_displayed)
		if !was_displayed && is_displayed:
			canvas.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_WHEN_VISIBLE)
			canvas.emit_signal("display")
			if canvas.get_child_count() == 1:
				canvas.get_child(0).set_hidden(false)
		elif was_displayed && !is_displayed:
			canvas.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_DISABLED)
			canvas.emit_signal("conceal")
			if canvas.get_child_count() == 1:
				canvas.get_child(0).set_hidden(true)

func has_canvas():
	return mCanvas != null

func get_canvas():
	return mCanvas
