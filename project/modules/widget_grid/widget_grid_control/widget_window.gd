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

func _draw():
	if mCanvas == null:
		return
	var rect = Rect2(Vector2(0, 0), get_rect().size)
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
	var was_displayed_list = {}
	for canvas in get_tree().get_nodes_in_group("canvas_group"):
		was_displayed_list[canvas] = canvas.is_displayed()
	if mCanvas != null:
		mCanvas.remove_display(self)
	mCanvas = canvas
	if mCanvas == null:
		mCanvasRegion = null
	else:
		mCanvasRegion = region
		mCanvas.add_display(self)
	update()
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

func is_root_window():
	return false

func has_canvas():
	return mCanvas != null

func get_canvas():
	return mCanvas
