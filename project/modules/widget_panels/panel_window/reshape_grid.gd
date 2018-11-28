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

var mActive = false
var mPaintedRect = null
var mClickGridPos = [0, 0]
var mPaintedGridRect = [0, 0, 0, 0]
var mColumns = []
var mRows = []

func _init():
	add_user_signal("finished")

func _get_grid_pos(pos):
	var spacing_x = mColumns[1]
	var spacing_y = mRows[1]
	var x = pos.x - fmod(pos.x, spacing_x)
	var y = pos.y - fmod(pos.y, spacing_y)
	var column_index = 0
	if x > 0:
		column_index = int(x/spacing_x)
	var row_index = 0
	if y > 0:
		row_index = int(y/spacing_y)
	return [column_index, row_index]

func _input_event(event):
	if mColumns.size() < 2 || mRows.size() < 2:
		return
	if event.type == InputEvent.MOUSE_BUTTON:
		mActive = event.pressed
		if mActive:
			mClickGridPos = _get_grid_pos(event.pos)
		else:
			emit_signal("finished")
	elif mActive && event.type == InputEvent.MOUSE_MOTION:
		var p2 = _get_grid_pos(event.pos)
		var column1 = min(mClickGridPos[0], p2[0])
		var column2 = max(mClickGridPos[0], p2[0]) 
		var row1 = min(mClickGridPos[1], p2[1])
		var row2 = max(mClickGridPos[1], p2[1])
		mPaintedGridRect = [column1, row1, column2, row2]
		column2 += 1
		if column2 > mColumns.size() - 1:
			column2 = mColumns.size() - 1
		row2 += 1
		if row2 > mRows.size() - 1:
			row2 = mRows.size() - 1
		var x1 = mColumns[column1]
		var x2 = mColumns[column2]
		var y1 = mRows[row1]
		var y2 = mRows[row2]
		mPaintedRect = Rect2(Vector2(x1, y1), Vector2(x2-x1, y2-y1))
	update()

func _draw():
	if mColumns.size() < 2 || mRows.size() < 2:
		return
	var color = Color(1, 1, 1)
	var width = get_size().x
	var height = get_size().y
	for x in mColumns:
		draw_line(Vector2(x, 0), Vector2(x, height), color)
	for y in mRows:
		draw_line(Vector2(0, y), Vector2(width, y), color)
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

func get_painted_grid_rect():
	return mPaintedGridRect

func set_grid(columns, rows):
	mColumns = columns
	mRows = rows
	update()
