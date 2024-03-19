extends StaticBody3D

var material
var is_transparent: bool = false

var FADE_SPEED: float = 10.0

func _ready():
	material = $CSGBox3D.material
	if !material:
		$CSGBox3D.material = StandardMaterial3D.new()
		material = $CSGBox3D.material
		material.albedo_color.r = 148.0 / 255.0
		material.albedo_color.g = 148.0 / 255.0
		material.albedo_color.b = 148.0 / 255.0
	material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	#material.depth_draw_mode = BaseMaterial3D.DepthDrawMode.DEPTH_DRAW_ALWAYS
	pass

func _process(delta):
	if is_transparent:
		material.albedo_color.a = lerp(material.albedo_color.a, 0.2, delta * FADE_SPEED)
	else:
		material.albedo_color.a = lerp(material.albedo_color.a, 1.0, delta * FADE_SPEED)
		#if material.albedo_color.a >= .99:
			#material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_DISABLED
	
	is_transparent = false

func hide_for_camera():
	is_transparent = true
	#material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
