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

extends Button

var mRot = 0

func _ready():
	return
	set_process(true)

func _process(delta):
	mRot -= 0.1
	update()

func _draw():
	return
	draw_set_transform(get_size()/2, mRot, Vector2(1, 1))
	var len = 18
	draw_line(Vector2(-len, 0), Vector2(len, 0), Color(1, 0, 1), 2)
	draw_line(Vector2(0, -len), Vector2(0, len), Color(1, 1, 1), 2)
	draw_circle(Vector2(0, 0), 12, Color(0, 0, 0))
