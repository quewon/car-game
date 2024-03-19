@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("ColorWrangler", "TextureRect", preload("WranglerScript.gd"), preload("icon.png"))
	pass


func _exit_tree():
	remove_custom_type("ColorWrangler")
	pass
