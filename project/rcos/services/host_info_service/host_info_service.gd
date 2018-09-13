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

const HOST_INFO_SCENE_PATH = "res://rcos/services/host_info_service/host_info.tscn"

onready var mHosts = get_node("hosts")

func _init():
	add_user_signal("host_info_changed")

func _ready():
	var info_files = rlib.find_files("user://etc/hosts/", "*.info")
	for filename in info_files:
		var config_file = ConfigFile.new()
		var err = config_file.load(filename)
		if err != OK:
			log_error(self, "Error reading info file " + filename + ": " + str(err))
			continue
		if !config_file.has_section("host_info"):
			continue
		_add_host_info_from_file(config_file)
	var local_host_info = create_host_info("localhost")
	local_host_info.clear_addresses()

func _add_host_info_from_file(config_file):
	var s = "host_info"
	var name = config_file.get_value(s, "name")
	if name == null:
		return false
	var icon = null
	var icon_path = config_file.get_value(s, "icon")
	if icon_path != null:
		icon = load(icon_path)
	if icon == null:
		icon = load("res://data_router/icons/32/question_mark.png")
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
	host_info.set_name(name)
	host_info.set_host_name(name)
	host_info.set_host_icon(icon)
	host_info.set_host_color(color)
	for addr in addresses:
		host_info.add_address(addr)
	return true

func get_host_info_from_hostname(host_name):
	if mHosts.has_node(host_name):
		return mHosts.get_node(host_name)
	return null

func get_host_info_from_address(host_addr):
	if IP.get_local_addresses().has(host_addr):
		return mHosts.get_node("localhost")
	for host in mHosts.get_children():
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
	host_info.set_name(host_name)
	host_info.set_host_name(host_name)
	host_info.connect("host_info_changed", self, "emit_signal", ["host_info_changed", host_info])
	return host_info
