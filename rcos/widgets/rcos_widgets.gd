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
	_create_widget_factories()

func _create_widget_factories():
	var info_files = rlib.find_files("res://rcos/widgets/", "*.info")
	for info_file in info_files:
		var config_file = ConfigFile.new()
		var err = config_file.load(info_file)
		if err != OK:
			log_error(self, "Error reading info file " + info_file + ": " + str(err))
			continue
		var basename = info_file.get_file().basename()
		var product_name = config_file.get_value("widget", "name", basename)
		var product_id = "rcos_widgets."+config_file.get_value("widget", "id", basename)
		var path = config_file.get_value("widget", "path", info_file.basename()+".tscn")
		var factory = rlib.instance_scene("res://rcos/widgets/widget_factory.tscn")
		add_child(factory)
		factory.set_name(basename+"_factory")
		factory.initialize(product_name, product_id, path)
