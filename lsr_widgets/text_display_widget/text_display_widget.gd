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

extends Node

var mInputPort = null

func _ready():
	var port_path_prefix = "local/text_display_widget"+str(get_meta("widget_id"))
	mInputPort = data_router.add_input_port(port_path_prefix+"/text")
	mInputPort.connect("data_changed", self, "_set_text")

func _exit_tree():
	data_router.remove_port(mInputPort)

func _set_text(data):
	get_node("main_canvas/gui/Panel/Label").set_text(str(data))
