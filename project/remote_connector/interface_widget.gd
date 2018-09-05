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

var mURL = ""
var mDesc = ""

func _init():
	add_user_signal("selected")

func _ready():
	get_node("button").connect("pressed", self, "_selected")

func _selected():
	emit_signal("selected")

func activate():
	rcos.open(mURL)

func get_desc():
	return mDesc

func set_url(url):
	mURL = url

func set_icon(tex):
	set_button_icon(tex)

func set_desc(desc):
	mDesc = desc
