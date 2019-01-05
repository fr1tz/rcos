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

var mUrlHandlerService = null
var mOutputPortsMeta = {}
var mInputPortsMeta = {}
var mOutputPorts = []
var mInputPorts = []

func _exit_tree():
	_remove_io_ports()

func _add_io_ports():
	var prefix = "rcos"
	_add_output_ports(prefix)
	_add_input_ports(prefix)

func _remove_io_ports():
	for port in mOutputPorts:
		rcos_data_router.remove_port(port)
	for port in mInputPorts:
		rcos_data_router.remove_port(port)

func _add_output_ports(prefix):
	pass

func _add_input_ports(prefix):
	mInputPortsMeta["open(url)"] = {
		"data_type": "string",
		"icon32": load("res://rcos_sys/data_router/icons/32/open.png")
	}
	for port_path in mInputPortsMeta.keys():
		var port = rcos_data_router.add_input_port(prefix+"/"+port_path)
		mInputPortsMeta[port_path]["port"] = port
		for meta_name in mInputPortsMeta[port_path].keys():
			var meta_value = mInputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		port.connect("data_changed", self, "_input_port_data_changed", [port])
		mInputPorts.push_back(port)

func _input_port_data_changed(old_data, new_data, port):
	if port.get_name() == "open(url)":
		if new_data != null:
			mUrlHandlerService.open_url(str(new_data))

func initialize(url_handler_service):
	mUrlHandlerService = url_handler_service
	_add_io_ports()

func get_output_port(port_name):
	return mOutputPortsMeta[port_name].port
