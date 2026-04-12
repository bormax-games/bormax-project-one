extends Node3D

func _ready() -> void:
	print("LEVEL1 rdy")
	Net.configure(self, $Players, $Items)
	print("CONFIGURED")
	Net.start_pending_connection()
	print("START_PENDING_COLLECTION_CALLED")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
