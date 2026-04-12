# TreeCollisionManager.gd
extends Node3D

@export var terrain: Terrain3D
@export var player: CharacterBody3D
@export var mesh_asset_id: int = 0
@export var tree_trunk_radius: float = 0.3
@export var tree_collision_height: float = 3.0
@export var detection_range: float = 20.0
@export var pool_size: int = 30
@export var update_interval: int = 10
@export var show_debug_shapes: bool = false

var _pool: Array[StaticBody3D] = []
var _frame_counter: int = 0


func _ready() -> void:
	_build_collision_pool()
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Najdi všechny MultiMeshInstance3D pod terrain nodem
	var mmis := terrain.find_children("*", "MultiMeshInstance3D", true, false)
	#print("Počet MMI nodů: ", mmis.size())
	#for mmi in mmis:
		##print("  MMI: ", mmi.name)

func _physics_process(_delta: float) -> void:
	_frame_counter += 1
	if _frame_counter < update_interval:
		return
	_frame_counter = 0
	_update_active_colliders()

func _get_nearby_trees() -> Array[Vector3]:
	var result: Array[Vector3] = []
	if not is_instance_valid(terrain):
		return result

	var player_pos := player.global_position
	var range_sq := detection_range * detection_range

	var mmis := terrain.find_children("*", "MultiMeshInstance3D", true, false)
	for node in mmis:
		var mmi := node as MultiMeshInstance3D
		if not mmi.multimesh:
			continue
		var mm := mmi.multimesh
		var global_xform := mmi.global_transform
		for i in mm.instance_count:
			var world_pos: Vector3 = (global_xform * mm.get_instance_transform(i)).origin
			if world_pos.distance_squared_to(player_pos) <= range_sq:
				result.append(world_pos)

	return result

func _update_active_colliders() -> void:
	var nearby := _get_nearby_trees()

	# DEBUG — smaž až to bude fungovat
	#if nearby.size() > 0:
		#print("Stromy v dosahu: %d | první: %s | hráč: %s" % [nearby.size(), nearby[0], player.global_position])

	nearby.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_squared_to(player.global_position) < b.distance_squared_to(player.global_position)
	)

	var active_count := mini(nearby.size(), pool_size)
	for i in pool_size:
		if i < active_count:
			var tree_pos := nearby[i]
			tree_pos.y += tree_collision_height * 0.5
			_pool[i].global_position = tree_pos
		else:
			_pool[i].global_position = Vector3(0, -9999, 0)


func _build_collision_pool() -> void:
	for i in pool_size:
		var body := StaticBody3D.new()
		body.name = "TreeCollider_%d" % i

		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = tree_trunk_radius
		cyl.height = tree_collision_height
		shape.shape = cyl
		body.add_child(shape)

		if show_debug_shapes:
			var mesh_inst := MeshInstance3D.new()
			var cyl_mesh := CylinderMesh.new()
			cyl_mesh.top_radius = tree_trunk_radius
			cyl_mesh.bottom_radius = tree_trunk_radius
			cyl_mesh.height = tree_collision_height
			mesh_inst.mesh = cyl_mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1, 0, 0, 0.4)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_inst.material_override = mat
			body.add_child(mesh_inst)

		add_child(body)
		body.global_position = Vector3(0, -9999, 0)
		_pool.append(body)
