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

extends Node

onready var mToggleButton = get_node("toggle_button")
onready var mInvisibleButton = get_node("invisible_button")

func _ready():
	mInvisibleButton.connect("button_down", self, "set_pressed", [true])
	mInvisibleButton.connect("button_up", self, "set_pressed", [false])

func set_pressed(pressed):
	var was_pressed = mToggleButton.is_pressed()
	mToggleButton.set_pressed(pressed)
	if pressed && !was_pressed:
		get_meta("widget_root_node").transfer()
