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

var mActive = false
var mPaintedRect = null
var mClickPos = Vector2(0, 0)

func _init():
	add_user_signal("finished")

func _ready():
	pass

func _input_event(event):
	if event.type == InputEvent.MOUSE_BUTTON:
		mActive = event.pressed
		if mActive:
			mClickPos = event.pos
		else:
			emit_signal("finished")
	elif mActive && event.type == InputEvent.MOUSE_MOTION:
		var p2 = event.pos 
		var x1 = min(mClickPos.x, p2.x)
		var y1 = min(mClickPos.y, p2.y)
		var x2 = max(mClickPos.x, p2.x)
		var y2 = max(mClickPos.y, p2.y)
		x1 -= fmod(x1, 40)
		x2 += 40 - fmod(x2, 40)
		y1 -= fmod(y1, 40)
		y2 += 40 - fmod(y2, 40)
		mPaintedRect = Rect2(Vector2(x1, y1), Vector2(x2-x1, y2-y1))
	update()

func _draw():
	if mPaintedRect == null:
		return
	var rect = mPaintedRect
	var points = Vector2Array()
	points.push_back(rect.pos)
	points.push_back(Vector2(rect.pos.x+rect.size.x, rect.pos.y))
	points.push_back(rect.pos+rect.size)
	points.push_back(Vector2(rect.pos.x, rect.pos.y+rect.size.y))
	points.push_back(points[0])
	draw_rect(rect, Color(1, 0, 0, 0.5))
	var line_color = Color(1, 0, 0, 1)
	var line_width = 2
	for i in range(0, 4):
		draw_line(points[i], points[i+1], line_color, line_width)

func clear_painted_rect():
	mPaintedRect = null
	update()

func get_painted_rect():
	return mPaintedRect
