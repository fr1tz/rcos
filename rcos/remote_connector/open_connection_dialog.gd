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

onready var mConnectorList = get_node("scroller_container/connector_list")

func _ready():
	get_node("cancel_button").connect("pressed", self, "set_hidden", [true])
	rcos.connect("url_handler_added", self, "_url_handler_added")
	rcos.connect("url_handler_removed", self, "_url_handler_removed")

func _url_handler_added(scheme):
	if mConnectorList.has_node(scheme):
		return
	var button = Button.new()
	button.set_custom_minimum_size(Vector2(200, 40))
	button.set_size(Vector2(200, 40))
	button.set_name(scheme)
	button.set_text(scheme)
	button.connect("pressed", self, "_button_selected", [button])
	mConnectorList.add_child(button)

func _url_handler_removed(scheme):
	if mConnectorList.has_node(scheme):
		var button = mConnectorList.get_node(scheme)
		mConnectorList.remove_child(button)
		button.queue_free()

func _button_selected(button):
	rcos.open(button.get_name())
	set_hidden(true)
