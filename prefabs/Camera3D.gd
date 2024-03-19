extends Camera3D

@export var player: Node3D

var query
var pivot

var rest_rotation: Vector3
var rest_position: Vector3
var zoom: float = 1.0

var MAX_ZOOM: float = 10.0

func _ready():
	pivot = get_parent()
	
	query = PhysicsShapeQueryParameters3D.new()
	query.shape = SeparationRayShape3D.new()
	
	rest_position = position
	rest_rotation = rotation

func _process(delta):
	hide_obstacles()
	
	pivot.position = player.position
	
	zoom = lerp(zoom, 0.0, delta)
	zoom += abs(player.linear_velocity.dot(player.global_basis.z)) / 100.0
	zoom = clamp(zoom, .5, MAX_ZOOM)
	
	var offset = global_basis.x/3 * player.global_basis.z * 10.0
	offset += basis.z * zoom
	position = rest_position + offset
	
	#var rotation_offset = global_basis.x * player.global_basis.z.dot(global_basis.z) * -5.0
	#rotation = rest_rotation + rotation_offset
	
func hide_obstacles():
	query.shape.length = global_position.distance_to(player.global_position)
	query.transform.origin = global_position
	query.transform = query.transform.looking_at(player.global_position, Vector3.UP, true)
	for result in get_world_3d().direct_space_state.intersect_shape(query):
		if result.collider == player: continue
		if result.collider.has_method("hide_for_camera"):
			result.collider.hide_for_camera()
