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

const HOST_INFO_SCENE_PATH = "res://rcos_core/services/host_info_service/host_info.tscn"

onready var mHosts = get_node("hosts")

func _ready():
	var filenames = rlib.find_files("user://etc/hosts/", "*")
	for filename in filenames:
		_load_host_info(filename)
	var local_host_info = create_host_info("localhost")
	local_host_info.clear_addresses()

func _load_host_info(filename):
	var config_file = ConfigFile.new()
	var err = config_file.load(filename)
	if err != OK:
		log_error(self, "Error reading info file " + filename + ": " + str(err))
		return false
	if !config_file.has_section("host_info"):
		return false
	var s = "host_info"
	var name = config_file.get_value(s, "name")
	if name == null:
		return false
	var icon = null
	var icon_path = config_file.get_value(s, "icon")
	if icon_path != null:
		icon = load(icon_path)
	if icon == null:
		icon = load("res://rcos_sys/data_router/icons/32/question_mark.png")
	var color = Color(1, 1, 1)
	var color_html = config_file.get_value(s, "color")
	if color_html != null:
		color = Color(color_html)
	var addresses = null
	var addresses_list = config_file.get_value(s, "addresses")
	if addresses_list != null:
		addresses = addresses_list.split(" ", false)
	var host_info = rlib.instance_scene(HOST_INFO_SCENE_PATH)
	mHosts.add_child(host_info)
	host_info.initialize(self)
	host_info.set_name(name)
	host_info.set_host_name(name)
	host_info.set_host_icon(icon)
	host_info.set_host_color(color)
	for addr in addresses:
		host_info.add_address(addr)
	host_info.mark_as_clean()
	return true

func _save_host_info(host_info):
	var dir = Directory.new()
	if !dir.dir_exists("user://etc/hosts"):
		dir.make_dir_recursive("user://etc/hosts")
	var cfile = ConfigFile.new()
	var s = "host_info"
	cfile.set_value(s, "name", host_info.get_host_name())
	cfile.set_value(s, "icon", host_info.get_host_icon().get_path())
	cfile.set_value(s, "color", host_info.get_host_color().to_html())
	cfile.set_value(s, "addresses", rlib.join_array(host_info.get_addresses(), " "))
	if cfile.save("user://etc/hosts/"+host_info.get_host_name()) != OK:
		return false
	host_info.mark_as_clean()
	return true

func get_host_info_from_hostname(host_name):
	if mHosts.has_node(host_name):
		return mHosts.get_node(host_name)
	return null

func get_host_info_from_address(host_addr):
	if host_addr == "localhost" || IP.get_local_addresses().has(host_addr):
		return mHosts.get_node("localhost")
	for host in mHosts.get_children():
		if host.get_host_name() == host_addr:
			return host
		if host.has_address(host_addr):
			return host
	return null

func get_host_info_nodes():
	return mHosts.get_children()

func create_host_info(host_name):
	if mHosts.has_node(host_name):
		return mHosts.get_node(host_name)
	var host_info = rlib.instance_scene(HOST_INFO_SCENE_PATH)
	mHosts.add_child(host_info)
	host_info.initialize(self)
	host_info.set_name(host_name)
	host_info.set_host_name(host_name)
	return host_info

func save_changes():
	for host_info in mHosts.get_children():
		if host_info.is_dirty():
			_save_host_info(host_info)
