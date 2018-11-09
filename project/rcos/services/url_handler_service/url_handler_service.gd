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

func _ready():
	for path in find_url_handlers():
		add_url_handler(path)

func find_url_handlers():
	var paths = []
	var info_files = rcos.get_info_files()
	for filename in info_files.keys():
		var config_file = info_files[filename]
		if !config_file.has_section("url_handler"):
			continue
		var path = config_file.get_value("url_handler", "path", filename.basename()+".tscn")
		paths.push_back(path)
	return paths

func add_url_handler(scene_path):
	var url_handler = rlib.instance_scene(scene_path)
	if url_handler == null:
		return
	add_child(url_handler)
