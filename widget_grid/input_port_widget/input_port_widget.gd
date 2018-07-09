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

func _ready():
	get_main_gui().connect("dangling_control_dropped", self, "_dangling_control_dropped")

func _dangling_control_dropped(control):
	if !control.has_meta("data"):
		return
	var input_port = data_router.get_input_port(get_config_gui().get_port_path())
	if input_port == null:
		return
	var data = control.get_meta("data")
	input_port.put_data(data)

#-------------------------------------------------------------------------------
# Common Widget API
#-------------------------------------------------------------------------------

func get_main_gui():
	return get_node("main_canvas/main_gui")

func get_config_gui():
	return get_node("config_canvas/config_gui")

func load_widget_config_string(config_string):
	var widget_config = Dictionary()
	if widget_config.parse_json(config_string) != OK:
		return false
	var port_path = widget_config.port_path
	var icon = load(widget_config.icon_path)
	get_config_gui().set_port_path(port_path)
	get_main_gui().set_icon(icon)
	return true

func create_widget_config_string():
	var port_path = get_config_gui().get_port_path()
	var icon_path = get_main_gui().get_icon().get_path()
	var widget_config = {
		"port_path": port_path,
		"icon_path": icon_path
	}
	return widget_config.to_json()
