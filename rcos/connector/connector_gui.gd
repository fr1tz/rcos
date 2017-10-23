extends Panel

func _ready():
	get_viewport().connect("display", self, "_on_displayed")
	get_viewport().connect("conceal", self, "_on_concealed")
	get_node("buttons").connect("button_selected", self, "_show_tab")

func _show_tab(idx):
	get_node("tabs").set_current_tab(idx)
	
func _on_displayed():
	#print("connector: _on_displayed")
	rcos.log_debug(self, "_on_displayed()")

func _on_concealed():
	#print("connector: _on_concealed")
	rcos.log_debug(self, "_on_concealed()")
