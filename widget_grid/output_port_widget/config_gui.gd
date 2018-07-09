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

extends Panel

onready var mPortSelectorButton = get_node("port_selector_button")
onready var mPortSelector = get_node("port_selector")

func _ready():
	mPortSelectorButton.connect("pressed", self, "_show_port_selector")
	mPortSelector.connect("canceled", self, "_show_buttons")
	mPortSelector.connect("node_selected", self, "_port_selected")

func _show_buttons():
	mPortSelector.set_hidden(true)

func _show_port_selector():
	mPortSelector.set_hidden(false)

func _port_selected(node):
	var port_path = node.get_port_path()
	var icon = data_router.get_node_icon(node, 32)
	set_port_path(port_path)
	get_meta("widget_root_node").get_main_gui().set_icon(icon)
	_show_buttons()

func set_port_path(port_path):
	mPortSelectorButton.set_text(port_path)

func get_port_path():
	return mPortSelectorButton.get_text()

func load_widget_config(widget_config):
	mPortSelectorButton.set_text(widget_config.port_path)
	