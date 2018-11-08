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

func _ready():
	_log_debug("_ready()")
	var dir = Directory.new()
	if !dir.dir_exists("user://etc/widget_grids"):
		dir.make_dir_recursive("user://etc/widget_grids")
	var service = rlib.instance_scene("res://modules/widget_grid/widget_grid_service.tscn")
	service._module = self
	if !rcos.add_service(service):
		rcos.log_error(self, "Unable to add widget_grid service")
	_log_notice("Ready")

func _log_debug(content):
	rcos.log_debug(self, content)

func _log_notice(content):
	rcos.log_notice(self, content)

func _log_error(content):
	rcos.log_error(self, content)

func add_widget_grid_editor():
	var num = 1
	while get_node("widget_grid_editors").has_node(str(num)):
		num += 1
	var editor = rlib.instance_scene("res://modules/widget_grid/widget_grid_editor/widget_grid_editor.tscn")
	editor.set_name(str(num))
	get_node("widget_grid_editors").add_child(editor)
