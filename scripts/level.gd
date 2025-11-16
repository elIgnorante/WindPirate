extends Node2D

func pause():
	get_tree().paused = true
	Game.main.pause_menu.selection_index = 0
	Game.main.pause_menu.show()
	Game.main.pause_menu.enable()


func resume():
	get_tree().paused = false
	Game.main.pause_menu.selection_index = 0
	Game.main.pause_menu.hide()
	Game.main.pause_menu.disable()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		pause()
