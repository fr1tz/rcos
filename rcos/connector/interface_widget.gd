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

extends Button

var mInfo = ""

func _init():
	add_user_signal("activated")

func _ready():
	get_node("button").connect("pressed", self, "_emit_on_pressed_signal")

func _emit_on_pressed_signal():
	emit_signal("pressed")

func activate():
	emit_signal("activated")

func get_info():
	return mInfo

func set_icon(tex):
	get_node("icon").set_texture(tex)

func set_info(info):
	mInfo = info
