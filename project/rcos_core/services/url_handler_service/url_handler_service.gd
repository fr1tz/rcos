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

onready var mIOPorts = get_node("io_ports")
onready var mUrlHandlers = get_node("url_handlers")

func _ready():
	mIOPorts.initialize(self)
	for path in _find_url_handlers():
		var url_handler = rlib.instance_scene(path)
		if url_handler == null:
			continue
		mUrlHandlers.add_child(url_handler)

func _find_url_handlers():
	var paths = []
	var info_files = rcos.get_info_files()
	for filename in info_files.keys():
		var config_file = info_files[filename]
		if !config_file.has_section("url_handler"):
			continue
		var path = config_file.get_value("url_handler", "path", filename.basename()+".tscn")
		paths.push_back(path)
	return paths

func get_scheme_from_url(url):
	var scheme = url
	var n = url.find(":")
	if n >= 1:
		scheme = url.left(n)
	return scheme

func get_host_from_url(url):
	var tokens = url.split("/", false)
	if tokens.size() < 2:
		return
	var authority = tokens[1]
	tokens = authority.split(":", false)
	var host = tokens[0]
	return host

func get_url_handlers(url):
	var scheme = get_scheme_from_url(url)
	var handlers = []
	for handler in mUrlHandlers.get_children():
		if handler.get_scheme() == scheme:
			handlers.push_back(handler)
	return handlers

func get_default_url_handler(url):
	var scheme = get_scheme_from_url(url)
	for handler in mUrlHandlers.get_children():
		if handler.get_scheme() == scheme:
			return handler
	return null

func open_url(url):
	var scheme = get_scheme_from_url(url)
	for handler in mUrlHandlers.get_children():
		if handler.get_scheme() == scheme:
			handler.open(url)
