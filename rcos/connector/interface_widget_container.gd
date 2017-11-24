extends MarginContainer

var mHostname = null
var mInterfaceWidgets = null

func _ready():
	mHostname = get_node("PanelContainer/MarginContainer/VBoxContainer/hostname")
	mInterfaceWidgets = get_node("PanelContainer/MarginContainer/VBoxContainer/interface_widgets")
	mHostname.set_text(get_name())

func add_interface_widget():
		var interface_widget = rlib.instance_scene("res://rcos/connector/interface_widget.tscn")
		mInterfaceWidgets.add_child(interface_widget)
		return interface_widget