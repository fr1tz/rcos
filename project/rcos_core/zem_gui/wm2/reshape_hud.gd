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

var _active = false
var _old_rect = null
var _new_rect = null
var _new_grid_rect = [0, 0, 0, 0]
var _click_grid_pos = [0, 0]
var _num_columns = 2
var _num_rows = 2
var _columns = []
var _rows = []

func _init():
	add_user_signal("finished")

func _ready():
	connect("resized", self, "_resized")

func _resized():
	var width = get_size().x
	var height = get_size().y
	var spacing_x = width/_num_columns
	var spacing_y = height/_num_rows
	_columns.clear()
	var x = 0
	while x < width:
		_columns.push_back(x)
		x += spacing_x
	_columns.push_back(width)
	_rows.clear()
	var y = 0
	while y < height:
		_rows.push_back(y)
		y += spacing_y
	_rows.push_back(height)

func _get_grid_pos(pos):
	var spacing_x = _columns[1]
	var spacing_y = _rows[1]
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
	if _columns.size() < 2 || _rows.size() < 2:
		return
	if event.type == InputEvent.MOUSE_BUTTON:
		_active = event.pressed
		if _active:
			_click_grid_pos = _get_grid_pos(event.pos)
		else:
			emit_signal("finished")
	elif _active && event.type == InputEvent.MOUSE_MOTION:
		var p2 = _get_grid_pos(event.pos)
		var column1 = min(_click_grid_pos[0], p2[0])
		var column2 = max(_click_grid_pos[0], p2[0]) 
		var row1 = min(_click_grid_pos[1], p2[1])
		var row2 = max(_click_grid_pos[1], p2[1])
		_new_grid_rect = [column1, row1, column2, row2]
		column2 += 1
		if column2 > _columns.size() - 1:
			column2 = _columns.size() - 1
		row2 += 1
		if row2 > _rows.size() - 1:
			row2 = _rows.size() - 1
		var x1 = _columns[column1]
		var x2 = _columns[column2]
		var y1 = _rows[row1]
		var y2 = _rows[row2]
		_new_rect = Rect2(Vector2(x1, y1), Vector2(x2-x1, y2-y1))
	update()

func _draw():
	if _columns.size() < 2 || _rows.size() < 2:
		return
	var color = Color(0, 0, 0, 0.2)
	var width = get_size().x
	var height = get_size().y
	for x in _columns:
		draw_line(Vector2(x, 0), Vector2(x, height), color)
	for y in _rows:
		draw_line(Vector2(0, y), Vector2(width, y), color)
	if _old_rect != null:
		var rect = _old_rect
		var points = Vector2Array()
		points.push_back(rect.pos)
		points.push_back(Vector2(rect.pos.x+rect.size.x, rect.pos.y))
		points.push_back(rect.pos+rect.size)
		points.push_back(Vector2(rect.pos.x, rect.pos.y+rect.size.y))
		points.push_back(points[0])
		draw_rect(rect, Color(1, 1, 1, 0.25))
		var line_color = Color(1, 1, 1, 1)
		var line_width = 2
		for i in range(0, 4):
			draw_line(points[i], points[i+1], line_color, line_width)
	if _new_rect != null:
		var rect = _new_rect
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

func set_old_rect(rect):
	_old_rect = rect
	update()

func clear_painted_rect():
	_new_rect = null
	update()

func get_painted_rect():
	return _new_rect

func get_painted_grid_rect():
	return _new_grid_rect
	
func set_grid(num_columns, num_rows):
	_num_columns = num_columns
	_num_rows = num_rows
	_resized()
