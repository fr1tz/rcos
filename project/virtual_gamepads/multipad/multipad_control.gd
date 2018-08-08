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

extends ReferenceFrame

# NOTICE: The glyph inside these strings might not be visible in your editor
const ICON_STICK = "" #f192 
const ICON_DPAD = "" #f055 
const ICON_BUTTON = "" #f111

onready var mMultipad = get_node("multipad")
onready var mIcon = get_node("icon")

func load_touchpad_config(touchpad_config):
	mMultipad.load_touchpad_config(touchpad_config)
	if touchpad_config.mode == "stick":
		mIcon.set_text(ICON_STICK)
	elif touchpad_config.mode == "dpad":
		mIcon.set_text(ICON_DPAD)
	elif touchpad_config.mode == "button":
		mIcon.set_text(ICON_BUTTON)

func set_polygon(verts):
	mMultipad.set_polygon(verts)
	var s1 = (verts[1]-verts[0]).length() - 10
	var s2 = (verts[verts.size()-1]-verts[0]).length() - 15
	var icon_size = min(s1, s2)
	if verts.size() == 3:
		icon_size *= 0.5
	icon_size = max(6, floor(icon_size))
	var icon_pos = mMultipad.get_center() - Vector2(icon_size/2, icon_size/2)
	mIcon.set_pos(icon_pos)
	mIcon.set_font_size(icon_size)

func turn_on():
	mMultipad.turn_on()

func turn_off():
	mMultipad.turn_off()
