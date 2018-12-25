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

onready var mPanelItems = get_node("vsplit/items_panel/items_container/items")

var mConfigFilePath = null 
var mModule = null
var mWindow = null
var mPackedWidgetPanelItem = null
var mSelectedItem = null

func _init():
	mPackedWidgetPanelItem = load("res://modules/widget_panels/main_window/widget_panel_item.tscn")

func _ready():
	get_node("vsplit/buttons/new").connect("pressed", self, "_create_widget_panel")
	get_node("vsplit/buttons/rename").connect("pressed", self, "_rename_selected_widget_panel")
	get_node("vsplit/buttons/toggle").connect("pressed", self, "_toggle_selected_widget_panel")
	get_node("vsplit/buttons/remove").connect("pressed", self, "_remove_selected_widget_panel")
	var isquare = Vector2(rcos.get_isquare_size(), rcos.get_isquare_size())
	get_node("vsplit/buttons").set_custom_minimum_size(isquare)
	for c in get_node("vsplit/buttons").get_children():
		c.set_custom_minimum_size(isquare)

func _create_widget_panel():
	var widget_panel_id = 1
	while true:
		if mPanelItems.has_node(str(widget_panel_id)):
			widget_panel_id += 1
		else:
			break
#	var dir = Directory.new()
#	var old_config = mModule.CONFIG_DIR+"/widget_panel_"+str(widget_panel_id)+".conf"
#	dir.remove(old_config)
	var widget_panel_label = "Widget Panel "+str(widget_panel_id)
	_add_widget_panel(widget_panel_id, widget_panel_label)
	_save()

func _add_widget_panel(widget_panel_id, widget_panel_label):
	var isquare = Vector2(rcos.get_isquare_size(), rcos.get_isquare_size())
	var panel_window = mModule.create_widget_panel_window(widget_panel_id)
	var item = mPackedWidgetPanelItem.instance()
	item.initialize(panel_window)
	item.set_name(str(widget_panel_id))
	item.set_text(widget_panel_label)
	item.set_custom_minimum_size(isquare)
	item.connect("pressed", self, "_item_selected", [item])
	mPanelItems.add_child(item)
	panel_window.set_title(widget_panel_label)
	panel_window.show()

func _toggle_selected_widget_panel():
	if mSelectedItem == null:
		return

func _remove_selected_widget_panel():
	if mSelectedItem == null:
		return
	var panel_window = mSelectedItem.get_widget_panel_window()
	mModule.destroy_widget_panel_window(panel_window)
	mPanelItems.remove_child(mSelectedItem)
	mSelectedItem.free()
	mSelectedItem = null
	_save()

func _item_selected(item):
	if mSelectedItem != null:
		mSelectedItem.set_pressed(false)
	mSelectedItem = item

func _save():
	var panels = []
	for panel_item in mPanelItems.get_children():
		panels.push_back({
			"id": panel_item.get_name(),
			"label": panel_item.get_text(),
			"disabled": false
		})
	if panels.empty():
		return
	var file = File.new()
	if file.open(mConfigFilePath, File.WRITE) != OK:
		return
	var config = {
		"version": 0,
		"panels": panels
	}
	file.store_buffer(config.to_json().to_utf8())
	file.close()

func load_config_file():
	var file = File.new()
	if file.open(mConfigFilePath, File.READ) != OK:
		return
	var text = file.get_buffer(file.get_len()).get_string_from_utf8()
	file.close()
	var config = {}
	if config.parse_json(text) != OK:
		return
	if config.version == 0:
		for panel in config.panels:
			_add_widget_panel(panel.id, panel.label)

func initialize(module, window):
	mModule = module
	mWindow = window
	mConfigFilePath = mModule.CONFIG_DIR+"/widget_panels.conf"

