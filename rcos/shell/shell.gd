extends Node

func _ready():
	var canvas = get_node("shell_canvas")
	rcos.push_canvas(canvas)
