extends Node3D

func _ready() -> void:
	print("LEVEL1 rdy")
	Net.configure(self, $Players, $Items)
	Net.player_spawned.connect(_on_player_spawned)
	print("CONFIGURED")
	Net.start_pending_connection()
	print("START_PENDING_CONNECTION_CALLED")


func _on_player_spawned(peer_id: int, player: Node) -> void:
	if str(multiplayer.get_unique_id()) != player.name:
		return

	var terrain = $Terrain3D

	if player.has_node("Pivot/Camera3D"):
		var camera = player.get_node("Pivot/Camera3D") as Camera3D
		terrain.set_camera(camera)
		print("Terrain camera set for local player: ", peer_id)


func _process(_delta: float) -> void:
	pass
