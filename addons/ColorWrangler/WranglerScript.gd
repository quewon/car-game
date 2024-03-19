@tool
extends TextureRect

func _enter_tree():
	print("loaded color wrangler!")
	material = preload("wrangler.tres")
	texture = preload("icon.png")
	# do setup
	pass

func _exit_tree():
	print("unloaded color wrangler!")
	# undo setup
	pass
