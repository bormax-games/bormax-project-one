extends SceneTree

func _initialize():
	print("\n----------------------------------------")
	print("[CI/CD] STARTING PROJECT VALIDATION...")
	print("----------------------------------------")
	
	var scene_path = "res://main.tscn"
	
	# 1. File Check
	print("Checking resource: " + scene_path)
	if not FileAccess.file_exists(scene_path):
		printerr("[ERROR] CRITICAL: File not found on disk.")
		quit(1)
		return

	# 2. Load Check
	print("Loading scene dependencies...")
	var main_scene = load(scene_path)
	if not main_scene:
		printerr("[ERROR] CRITICAL: Could not load scene dependencies.")
		quit(1)
		return

	# 3. Instance Check
	print("Instantiating game world...")
	var instance = main_scene.instantiate()
	if not instance:
		printerr("[ERROR] CRITICAL: Scene instantiation failed.")
		quit(1)
		return

	print("----------------------------------------")
	print("SUCCESS: Bormax Project-One is initialized and stable.")
	print("----------------------------------------\n")
	
	quit(0)
