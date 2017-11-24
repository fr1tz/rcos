extends ReferenceFrame

var mNetInterfaceActive = false
var mConnectionCount = 0

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	var vrc_host = get_node("vrc_host")
	vrc_host.set_rot(vrc_host.get_rot() - delta*2.5)

func add_error():
	get_node("vrc_host/setup_progress").add_error()

func set_connection_count(count):
	var connections = get_node("vrc_host/connections")
	for c in connections.get_children():
		connections.remove_child(c)
		c.queue_free()
	var packed_connection = load("res://vrc_host/status_screen/connection.tscn")
	for i in range(0, count):
		var connection = packed_connection.instance()
		var rot = i*(2*PI/count)
		connections.add_child(connection)
		connection.set_rot(rot)

func set_setup_progress(progress):
	get_node("vrc_host/setup_progress").set_progress(progress)


