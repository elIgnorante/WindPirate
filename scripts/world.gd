extends Node2D

var levels_map = {
	"level_1": "res://scenes/levels/level_1.tscn"
}

var current_level

func load_level(level_name):
	current_level = load(levels_map[level_name]).instantiate()
	add_child(current_level)
	
func unload():
	current_level.queue_free()
	current_level = null
