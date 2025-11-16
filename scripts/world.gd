extends Node2D

var levels_map = {
		"level_1": "res://scenes/levels/level_1.tscn",
		"level_2": "res://scenes/levels/level_2.tscn"
}

var levels_order = ["level_1", "level_2"]

var current_level_name := ""
var current_level

func load_level(level_name):
		if current_level:
				unload()
		var path = levels_map.get(level_name, "")
		if path == "":
				return
		current_level = load(path).instantiate()
		var next_level = _next_level_name(level_name)
		current_level.level_name = level_name
		current_level.next_level = next_level
		add_child(current_level)
		current_level_name = level_name

func load_next_level():
		var next = _next_level_name(current_level_name)
		if next == "":
				Game.main.return_to_menu()
		else:
				load_level(next)

func reload_current_level():
		if current_level_name != "":
				load_level(current_level_name)

func unload():
		if current_level:
				current_level.queue_free()
		current_level = null
		current_level_name = ""

func _next_level_name(level_name):
		var idx = levels_order.find(level_name)
		if idx == -1 or idx == levels_order.size() - 1:
				return ""
		return levels_order[idx + 1]
