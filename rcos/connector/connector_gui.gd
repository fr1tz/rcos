extends Panel

var mInterfaceWidgetContainers = null
var mInfoWidget = null
var mSelectedInterfaceWidget = null

func _ready():
	get_viewport().connect("display", self, "_on_displayed")
	get_viewport().connect("conceal", self, "_on_concealed")
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

func add_interface_widget(host):
	var interface_container = null
	for c in mInterfaceWidgetContainers.get_children():
		if c.get_name() == host:
			interface_container = c
			break
	if interface_container == null:
		interface_container = rlib.instance_scene("res://rcos/connector/interface_widget_container.tscn")
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
