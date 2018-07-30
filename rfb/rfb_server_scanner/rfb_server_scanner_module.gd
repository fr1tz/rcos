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

const SCANNER_PATH = "res://rfb/rfb_server_scanner/rfb_server_scanner.tscn"

func _ready():
	if rcos.has_node("services/network_scanner_service"):
		var ns_service = rcos.get_node("services/network_scanner_service")
		ns_service.add_scanner(SCANNER_PATH)
	else:
		rcos.log_error(self, "Unable to find network scanner service")

func _exit_tree():
	if rcos.has_node("services/network_scanner_service"):
		var ns_service = rcos.get_node("services/network_scanner_service")
		ns_service.remove_scanner(SCANNER_PATH)
