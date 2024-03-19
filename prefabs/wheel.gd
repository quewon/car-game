extends Node3D

#

var car
var shapecast
@onready var parent = get_parent()
@onready var mesh = $mesh

#

var TRAVEL: float = .6
var SPRING_STRENGTH: float = 100.0
var SPRING_DAMPER: float = 2.0
var SLIP_FACTOR: float = 0.1

#

@export var use_as_steering: bool = true
var radius: float
var rest_position: Vector3
var ground_point: Vector3
var grounded: bool = false

var angular_velocity: float

func _ready():
	shapecast = $ShapeCast3D
	car = get_parent().get_parent()
	
	radius = shapecast.shape.radius
	shapecast.add_exception(car)
	
	rest_position = position
	
	shapecast.target_position = Vector3(-TRAVEL, 0, 0)
	
	$point.visible = false

func _process(delta):
	if use_as_steering: rotation.y = deg_to_rad(car.steer_angle)
	
	update_ground_collision_point()
	
func update_ground_collision_point():
	grounded = false
	var up = car.global_basis.y
	
	var global_rest_position = parent.to_global(rest_position)
	var max_ground_point = global_rest_position + -up * (TRAVEL - radius)
	ground_point = max_ground_point
	
	for collision in shapecast.collision_result:
		if collision.normal.y < 0.2:
			continue
		if up.dot(collision.point) > up.dot(ground_point):
			grounded = true
			var local_ground_point = parent.to_local(ground_point)
			var local_collision_point = parent.to_local(collision.point)
			local_ground_point.y = clamp(local_collision_point.y, -TRAVEL, TRAVEL)
			ground_point = parent.to_global(local_ground_point)
	
	$point.global_position = ground_point
	global_position = ground_point + up * radius

func _physics_process(delta):
	var global_velocity = car.get_point_velocity(global_position)
	
	# suspension
	if grounded:
		var up = global_basis.y
		var spring_offset = parent.to_local(ground_point).y - rest_position.y + radius
		
		var spring_velocity = up.dot(global_velocity)
		var force = (spring_offset * SPRING_STRENGTH) - (spring_velocity * SPRING_DAMPER)
		
		car.apply_force(up * force, ground_point - car.global_position)
	
	var forward = global_basis.z
	var left = global_basis.x
	
	var forward_velocity = global_velocity.dot(forward)
	var slip_velocity = global_velocity.dot(left)
	
	# wheel rotation
	if grounded:
		angular_velocity = deg_to_rad(forward_velocity) / radius
	else:
		angular_velocity = deg_to_rad(car.engine_torque / 3.0) / radius
		
	mesh.rotation.x += angular_velocity
	
	# slipping
	if grounded:
		var nonslip_force = -slip_velocity * car.FRICTION * (1 - SLIP_FACTOR)
		car.apply_force(left * nonslip_force, ground_point - car.global_position)
