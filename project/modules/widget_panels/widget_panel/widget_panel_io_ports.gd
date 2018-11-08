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

var mGui = null
var mOutputPortsMeta = {}
var mInputPortsMeta = {}
var mOutputPorts = []
var mInputPorts = []

func _exit_tree():
	_remove_io_ports()

func _add_io_ports(prefix):
	_add_output_ports(prefix)
	_add_input_ports(prefix)
	var icon = load("res://modules/widget_panels/graphics/icons/widget_panel.png")
	var node1 = data_router.get_output_port(prefix)
	var node2 = data_router.get_input_port(prefix)
	for node in [node1, node2]:
		node.set_meta("icon32", icon)
		node.set_meta("icon_label", str(mGui.get_widget_panel_id()))

func _remove_io_ports():
	for port in mOutputPorts:
		data_router.remove_port(port)
	for port in mInputPorts:
		data_router.remove_port(port)

func _add_output_ports(prefix):
	mOutputPortsMeta["info"] = {
		#"icon32": load("res://modules/widget_panels/graphics/icons/widget_panel.png"),
	}
	for port_path in mOutputPortsMeta.keys():
		var port = data_router.add_output_port(prefix+"/"+port_path, "")
		mOutputPortsMeta[port_path]["port"] = port
		for meta_name in mOutputPortsMeta[port_path].keys():
			var meta_value = mOutputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		mOutputPorts.push_back(port)

func _add_input_ports(prefix):
	mInputPortsMeta["ctrl"] = {
		#"icon32": load("res://modules/widget_panels/graphics/icons/widget_panel.png"),
	}
	for port_path in mInputPortsMeta.keys():
		var port = data_router.add_input_port(prefix+"/"+port_path)
		mInputPortsMeta[port_path]["port"] = port
		for meta_name in mInputPortsMeta[port_path].keys():
			var meta_value = mInputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		#port.connect("data_changed", self, "_input_port_data_changed", [port])
		mInputPorts.push_back(port)

func initialize(widget_panel_gui, io_ports_path_prefix):
	mGui = widget_panel_gui
	_add_io_ports(io_ports_path_prefix)
