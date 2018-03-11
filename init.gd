extends Node

func _ready():
#	rcos.spawn_module("res://rcos/logger/logger.tscn")
	rcos.spawn_module("res://rcos/shell/shell.tscn")
	rcos.spawn_module("res://rcos/connector/connector.tscn")
#	var info = {
#		addr = "localhost",
#		name = "test",
#		port = 1234,
#		type = "vrc"
#	}
#	var vrc_host = open_connection(info)
#	var file = File.new()
#	file.open("res://vrc_host/output_module.xml", File.READ)
#	vrc_host.set_variable("OUTPUT_MODULE_DATA", file.get_as_text())
#	file.close()
#	print(vrc_host.add_module("OUTPUT_MODULE_DATA"))
#	vrc_host.get_node("main_canvas/main_gui/status_screen").set_connection_count(3)
