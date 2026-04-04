extends SceneTree

func _initialize():
	# Define colors for output messages
	var green = "\u001b[32m"
	var red = "\u001b[31m"
	var reset = "\u001b[0m"

	print("\n----------------------------------------")
	print("[CI/CD] STARTING PROJECT VALIDATION...")
	print("----------------------------------------")
	
	var scene_path = "res://main.tscn"
	
	# 1. File Check
	print("Checking resource: " + scene_path)
	if not FileAccess.file_exists(scene_path):
		printerr(red + "[ERROR] CRITICAL: File not found on disk." + reset)
		quit(1)
		return

	# 2. Load Check
	print("Loading scene dependencies...")
	var main_scene = load(scene_path)
	if not main_scene:
		printerr(red + "[ERROR] CRITICAL: Could not load scene dependencies." + reset)
		quit(1)
		return

	# 3. Instance Check
	print("Instantiating game world...")
	var instance = main_scene.instantiate()
	if not instance:
		printerr(red + "[ERROR] CRITICAL: Scene instantiation failed." + reset)
		quit(1)
		return

	print("----------------------------------------")
	print(green + "SUCCESS: Bormax Project-One is initialized and stable." + reset)
	print("----------------------------------------\n")

	instance.free()
	quit(0)
