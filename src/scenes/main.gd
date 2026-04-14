extends Node3D

func _ready():
	print("Main rdy")
	await get_tree().create_timer(1.0).timeout
	print("GO HOST")
	Net.go_to_level_as_host()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
