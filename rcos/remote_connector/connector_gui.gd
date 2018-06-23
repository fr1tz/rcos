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

extends Panel

var mInterfaceWidgetContainers = null
var mInfoWidget = null
var mSelectedInterfaceWidget = null

func _ready():
	get_viewport().connect("display", self, "_on_displayed")
	get_viewport().connect("conceal", self, "_on_concealed")
	get_viewport().connect("size_changed", self, "_on_size_changed")
	get_node("buttons").connect("button_selected", self, "_show_tab")
	mInterfaceWidgetContainers = get_node("interfaces_panel/interfaces_scroller/interfaces_list")
	mInfoWidget = get_node("info_panel/info_widget")

func _show_tab(idx):
	get_node("tabs").set_current_tab(idx)
	
func _on_displayed():
	#print("connector: _on_displayed")
	rcos.log_debug(self, "_on_displayed()")

func _on_concealed():
	#print("connector: _on_concealed")
	rcos.log_debug(self, "_on_concealed()")

func _on_size_changed():
	rcos.log_debug(self, "_on_size_changed()")
	var width = float(get_viewport().get_rect().size.x - 4 - 8 - 10)
	var new_column_count = floor(width/(42+2))
	for interface_container in mInterfaceWidgetContainers.get_children():
		interface_container.mInterfaceWidgets.set_columns(new_column_count)

func add_interface_widget(host):
	var interface_container = null
	for c in mInterfaceWidgetContainers.get_children():
		if c.get_name() == host:
			interface_container = c
			break
	if interface_container == null:
		interface_container = rlib.instance_scene("res://rcos/remote_connector/interface_widget_container.tscn")
		interface_container.set_name(host)
		mInterfaceWidgetContainers.add_child(interface_container)
	var interface_widget = interface_container.add_interface_widget()
	interface_widget.connect("pressed", self, "_on_interface_widget_pressed", [interface_widget])
	return interface_widget

func _on_interface_widget_pressed(interface_widget):
	if interface_widget == mSelectedInterfaceWidget:
		mSelectedInterfaceWidget.activate()
	elif mSelectedInterfaceWidget != null:
		mSelectedInterfaceWidget.set_pressed(false)
		mInfoWidget.get_node("label").set_text("")
	mSelectedInterfaceWidget = interface_widget
	mSelectedInterfaceWidget.set_pressed(true)
	show_info(mSelectedInterfaceWidget)

func show_info(interface_widget):
	mInfoWidget.get_node("label").set_text(interface_widget.get_info())
