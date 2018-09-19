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

extends ColorFrame

onready var mColorsList = get_node("colors_panel/colors_scroller/colors_list")
onready var mCancelButton = get_node("cancel_button")

func _init():
	add_user_signal("cancel_button_pressed")
	add_user_signal("color_selected")

func _ready():
	mCancelButton.connect("pressed", self, "emit_signal", ["cancel_button_pressed"])
	for c in mColorsList.get_children():
		c.connect("pressed", self, "_color_button_pressed", [c])

func _color_button_pressed(color_button):
	emit_signal("color_selected", color_button.color)
