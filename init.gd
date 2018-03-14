extends Node

func _ready():
	rcos.spawn_module("wm")
	rcos.spawn_module("connector")
