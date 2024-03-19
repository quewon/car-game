extends RigidBody3D

@onready var joystick = $joystick
var trail_particle: PackedScene = preload("res://prefabs/trail_particle.tscn")
@onready var trail_point = $trail_point
var trail_timer: float

var backlights = []
var headlights = []
var wheels = []

var DRAG: float = .2
var FRICTION: float = .2 * 30.0

var ACCEL_SPEED: float = .5
var ACCEL_FAlLOFF: float = 1.0
var BRAKE_FORCE: float = .7
var FLIP_STRENGTH: float = 5.0

var MAX_ENGINE_TORQUE: float = 70.0

var MOUSE_STEERING_RATIO: float = .1
var KEYBOARD_STEERING_RATIO: float = 2.0

var STEER_SPEED: float = 30.0
var STEER_FALLOFF: float = 5.0

#

var force_origin: Vector3
var engine_torque = 0.0
var desired_steer_angle: float = 0.0

var steer_mode = "mouse"

var steer_angle: float = 0.0
var wheels_grounded: int = 0
var gear_reverse: bool = false

var collision_point: Vector3

func _ready():
	backlights = [
		$backlights/light1/SpotLight3D,
		$backlights/light2/SpotLight3D
	]
	headlights = [
		$headlights/light1/SpotLight3D,
		$headlights/light2/SpotLight3D
	]
	for light in backlights:
		light.get_parent().material = light.get_parent().material.duplicate()
	for light in headlights:
		light.get_parent().material = light.get_parent().material.duplicate()
	
	set_lights(headlights, true)
	set_lights(backlights, false)
	
	wheels = [
		$wheels/FR,
		$wheels/FL,
		$wheels/BR,
		$wheels/BL
	]
	
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	contact_monitor = true
	max_contacts_reported = 1
	
	#$joystick.visible = false

func set_lights(lights, visibility: bool):
	for light in lights:
		light.get_parent().material.emission_enabled = visibility
		light.visible = visibility

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		desired_steer_angle -= event.relative.x * MOUSE_STEERING_RATIO

func _process(delta):
	wheels_grounded = 0
	for wheel in wheels:
		if wheel.grounded: wheels_grounded += 1
	
	# reverse
	if Input.is_action_just_pressed("reverse"):
		gear_reverse = !gear_reverse
		set_lights(backlights, gear_reverse)
		set_lights(headlights, !gear_reverse)
	
	process_steering(delta)
	
	joystick.rotation.x = engine_torque / MAX_ENGINE_TORQUE * deg_to_rad(45.0)
	joystick.rotation.z = -deg_to_rad(steer_angle)
	
	if Input.is_action_pressed("brake"):
		var forward_velocity = linear_velocity.dot(global_basis.z)
		center_of_mass = Vector3(0, 0, forward_velocity / 10.0)
		joystick.rotation.x = deg_to_rad(-linear_velocity.dot(global_basis.z) * BRAKE_FORCE) * 10
	elif Input.is_action_pressed("accelerate"):
		center_of_mass = Vector3(0, 0, -.1)
	else:
		center_of_mass = Vector3(0, 0, 0)
	
	var speed = linear_velocity.dot(global_basis.z)
	trail_timer += speed * delta
	if trail_timer >= 4.0 / abs(speed):
		trail_timer = 0
		var particle = trail_particle.instantiate()
		get_parent().add_child(particle)
		particle.global_position = trail_point.global_position

func process_steering(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		steer_mode = "mouse"
	elif Input.is_action_pressed("steer_left") or Input.is_action_pressed("steer_right"):
		steer_mode = "keyboard"
		
	if steer_mode == "mouse":
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			desired_steer_angle = 0.0
	else:
		var steer_input = 0.0
		if Input.is_action_pressed("steer_left"):
			steer_input += 1.0
		if Input.is_action_pressed("steer_right"):
			steer_input -= 1.0
		if steer_input == 0:
			desired_steer_angle = lerp(desired_steer_angle, 0.0, STEER_FALLOFF * delta)
		else:
			desired_steer_angle += steer_input * 30.0 * KEYBOARD_STEERING_RATIO * delta
		
	desired_steer_angle = clamp(desired_steer_angle, -30.0, 30.0)
	
	if desired_steer_angle != 0:
		steer_angle = lerp(steer_angle, desired_steer_angle, STEER_SPEED * delta)
	else:
		steer_angle = lerp(steer_angle, 0.0, STEER_FALLOFF * delta)

func _physics_process(delta):
	flip_the_turtle()
	
	var forward = global_basis.z
	
	if Input.is_action_pressed("brake"):
		if wheels_grounded > 0:
			var forward_speed = linear_velocity.dot(forward)
			engine_torque -= forward_speed * BRAKE_FORCE
			engine_torque = max(engine_torque, 0.0)
	else:
		if Input.is_action_pressed("accelerate"):
			engine_torque += ACCEL_SPEED * delta
			if gear_reverse:
				engine_torque = lerp(engine_torque, -MAX_ENGINE_TORQUE, ACCEL_SPEED * delta)
			else:
				engine_torque = lerp(engine_torque, MAX_ENGINE_TORQUE, ACCEL_SPEED * delta)
				
			#center_of_mass = Vector3()
			#apply_central_force(Vector3.UP * 50.0)
		else:
			engine_torque = lerp(engine_torque, 0.0, ACCEL_FAlLOFF * delta)
	
	apply_long_force()

func apply_long_force():
	if wheels_grounded > 0:
		var drag = DRAG * linear_velocity * linear_velocity.length()
		var roll_resistance = FRICTION * linear_velocity
		var force = global_basis.z * engine_torque - drag - roll_resistance
		apply_force(force, force_origin)

func flip_the_turtle():
	# min clamp in order to stop it from doing impossible swings, and car can actually
	# flip over completely maybe.
	if wheels_grounded + get_contact_count() > 0:
		var tilt = min(abs(rotation.z), deg_to_rad(90.0)) + min(abs(rotation.x), deg_to_rad(90.0))
		var force = -global_basis.y * FLIP_STRENGTH * tilt
		apply_force(force, Vector3(
			.5 * -sign(rotation.z) * tilt, 
			0, 
			.5 * -sign(rotation.x) * tilt
		))

func get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_transform.origin)
