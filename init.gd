extends Node

func _ready():
#	rcos.spawn_module("res://rcos/logger/logger.tscn")
	rcos.spawn_module("res://rcos/wm/wm.tscn")
	rcos.spawn_module("res://rcos/connector/connector.tscn")
