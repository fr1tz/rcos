
func instance_scene(scene_path):
	var packed_scene = load(scene_path)
	if packed_scene == null:
		print("instance_scene() Error loading ", scene_path)
		return null
	var scene_instance = packed_scene.instance()
	if scene_instance == null:
		print("instance_scene() Error instancing ", scene_path)
		return null
	return scene_instance
