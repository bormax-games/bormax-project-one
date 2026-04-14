extends Node

signal status_changed(message: String)
signal player_spawned(peer_id: int, node: Node)
signal player_despawned(peer_id: int)
signal connected_ok()
signal connection_failed_signal()
signal disconnected_signal()

const DEFAULT_PORT := 7777
const DEFAULT_MAX_CLIENTS := 8
const PLAYER_SCENE := preload("res://network/net_player.tscn")


var players_root: Node = null
var items_root: Node = null
var world_root: Node = null

var _peer: ENetMultiplayerPeer
var _player_nodes: Dictionary = {}

var _pending_mode := ""
var _pending_address := ""

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func configure(world_root_node: Node, players_root_node: Node, items_root_node: Node) -> void:
	world_root = world_root_node
	players_root = players_root_node
	items_root = items_root_node
	_push_status("Net configured.")


func host(port: int = DEFAULT_PORT, max_clients: int = DEFAULT_MAX_CLIENTS) -> Error:
	stop()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, max_clients)
	if err != OK:
		_push_status("Host failed on port %d, err=%d" % [port, err])
		return err

	multiplayer.multiplayer_peer = _peer
	_push_status("Hosting on UDP port %d" % port)

	if players_root == null:
		_push_status("Warning: Net.configure() was not called before host().")
		return OK

	_spawn_player_local(multiplayer.get_unique_id())
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	stop()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)
	if err != OK:
		_push_status("Join failed to %s:%d, err=%d" % [address, port, err])
		return err

	multiplayer.multiplayer_peer = _peer
	_push_status("Joining %s:%d" % [address, port])
	return OK
	
	
#functions for main scene to connect to level1
func go_to_level_as_host() -> void:
	print("Net: go_to_level_as_host")
	_pending_mode = "host"
	get_tree().change_scene_to_file("res://scenes/level1.tscn")


func go_to_level_as_client(address: String) -> void:
	print("Net: go_to_level_as_client")
	_pending_mode = "join"
	_pending_address = address
	get_tree().change_scene_to_file("res://scenes/level1.tscn")


func start_pending_connection() -> void:
	print("Net: start_pending_connection")

	if _pending_mode == "host":
		_pending_mode = ""
		print("Net: caling host")
		host()
	elif _pending_mode == "join":
		var addr = _pending_address
		_pending_mode = ""
		print("Net: calling  join")
		join(addr)
	else:
		print("No pending mode")
#ends here


func stop() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	_peer = null
	_clear_players()
	_push_status("Stopped networking.")


func is_online() -> bool:
	return multiplayer.multiplayer_peer != null

  
func is_server() -> bool:
	return multiplayer.is_server()


func get_local_peer_id() -> int:
	return multiplayer.get_unique_id()


func get_player_node(peer_id: int) -> Node:
	return _player_nodes.get(peer_id, null)


func request_pickup(peer_id: int) -> void:
	if not is_online():
		return
	if is_server():
		_server_try_pickup(peer_id)
	else:
		rpc_id(1, "_rpc_request_pickup", peer_id)


func broadcast_player_state(peer_id: int, pos: Vector3, vel: Vector3, basis: Basis) -> void:
	if not is_server():
		return
	_rpc_apply_player_state(peer_id, pos, vel, basis)
	rpc("_rpc_apply_player_state", peer_id, pos, vel, basis)


func _spawn_player_local(peer_id: int) -> void:
	if players_root == null:
		return
	if _player_nodes.has(peer_id):
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	players_root.add_child(player)
	
	var spawn_point := world_root.get_node_or_null("SpawnPoint")
	if spawn_point != null:
		player.global_position = spawn_point.global_position + Vector3(0,2,0)
	
	
	if player.has_method("setup_from_peer"):
		player.setup_from_peer(peer_id)
	_player_nodes[peer_id] = player
	player_spawned.emit(peer_id, player)
	_push_status("Spawned player %d" % peer_id)


func _despawn_player_local(peer_id: int) -> void:
	if not _player_nodes.has(peer_id):
		return
	var node: Node = _player_nodes[peer_id]
	_player_nodes.erase(peer_id)
	if is_instance_valid(node):
		node.queue_free()
	player_despawned.emit(peer_id)
	_push_status("Despawned player %d" % peer_id)


func _clear_players() -> void:
	for peer_id in _player_nodes.keys():
		var node: Node = _player_nodes[peer_id]
		if is_instance_valid(node):
			node.queue_free()
	_player_nodes.clear()


func _on_peer_connected(peer_id: int) -> void:
	if not is_server():
		return

	_spawn_player_local(peer_id)

	for existing_id in _player_nodes.keys():
		rpc_id(peer_id, "_rpc_spawn_player", int(existing_id))

	for other_peer_id in multiplayer.get_peers():
		if other_peer_id != peer_id:
			rpc_id(other_peer_id, "_rpc_spawn_player", peer_id)

	_push_status("Peer connected: %d" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_despawn_player_local(peer_id)
	if is_server():
		rpc("_rpc_despawn_player", peer_id)
	_push_status("Peer disconnected: %d" % peer_id)


func _on_connected_to_server() -> void:
	_push_status("Connected to server.")
	connected_ok.emit()


func _on_connection_failed() -> void:
	_push_status("Connection failed.")
	connection_failed_signal.emit()


func _on_server_disconnected() -> void:
	_push_status("Disconnected by server.")
	stop()
	disconnected_signal.emit()


func _server_try_pickup(peer_id: int) -> void:
	if items_root == null:
		return
	var player = get_player_node(peer_id)
	if player == null:
		return

	var best_item: Node3D = null
	var best_distance := 999999.0
	for child in items_root.get_children():
		if not child.is_in_group("pickup_item"):
			continue
		if not (child is Node3D):
			continue
		var dist : float = player.global_position.distance_to(child.global_position)
		if dist < 2.5 and dist < best_distance:
			best_distance = dist
			best_item = child

	if best_item == null:
		return

	var item_name := best_item.name
	best_item.queue_free()
	_rpc_remove_item(item_name)
	rpc("_rpc_remove_item", item_name)
	_push_status("Player %d picked up %s" % [peer_id, item_name])


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_pickup(peer_id: int) -> void:
	if not is_server():
		return
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	_server_try_pickup(peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_player(peer_id: int) -> void:
	_spawn_player_local(peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_despawn_player(peer_id: int) -> void:
	_despawn_player_local(peer_id)


@rpc("authority", "call_local", "unreliable")
func _rpc_apply_player_state(peer_id: int, pos: Vector3, vel: Vector3, basis: Basis) -> void:
	var player = get_player_node(peer_id)
	if player != null and player.has_method("apply_server_state"):
		player.apply_server_state(pos, vel, basis)


@rpc("authority", "call_local", "reliable")
func _rpc_remove_item(item_name: String) -> void:
	if items_root == null:
		return
	var item := items_root.get_node_or_null(item_name)
	if item != null:
		item.queue_free()


func _push_status(message: String) -> void:
	print("[Net] %s" % message)
	status_changed.emit(message)
