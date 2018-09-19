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

tool

extends Button

export(Color) var color = Color(1, 1, 1) setget set_color, get_color

var mColorFrame = null

func _ready():
	mColorFrame = get_node("color_frame")
	mColorFrame.set_frame_color(color)

func set_color(p_color):
	color = p_color
	if mColorFrame != null:
		mColorFrame.set_frame_color(color)

func get_color():
	return color
