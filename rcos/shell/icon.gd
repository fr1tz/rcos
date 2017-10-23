extends Sprite

func set_texture(texture):
	.set_texture(texture)
	if texture.has_meta("rotate") && texture.get_meta("rotate") == true:
		set_fixed_process(true)
	else:
		set_fixed_process(false)

func _fixed_process(delta):
	set_rot(get_rot() - delta*5)
