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

var mService = null
var mWidgetFactoryTaskIDs = {}

func _ready():
	rcos.log_debug(self, "_ready()")
	mService = rlib.instance_scene("res://rcos/widgets/rcos_widgets_service.tscn")
	mService._module = self
	if !rcos.add_service(mService):
		rcos.log_error(self, "Unable to add rcos_widgets service")
	mWidgetFactoryTaskIDs["output_port_widget"] = rcos.add_task({
			"type": "widget_factory",
			"product_name": "Output Port Widget",
			"product_id": "rcos.output_port_widget",
			"create_widget_func": funcref(self, "create_output_port_widget")
		})
	mWidgetFactoryTaskIDs["input_port_widget"] = rcos.add_task({
			"type": "widget_factory",
			"product_name": "Input Port Widget",
			"product_id": "rcos.input_port_widget",
			"create_widget_func": funcref(self, "create_input_port_widget")
		})

func create_output_port_widget():
	return rlib.instance_scene("res://rcos/widgets/output_port_widget/output_port_widget.tscn")

func create_input_port_widget():
	return rlib.instance_scene("res://rcos/widgets/input_port_widget/input_port_widget.tscn")
