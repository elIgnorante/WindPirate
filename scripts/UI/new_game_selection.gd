extends Label

func select():
	Game.main.transition.fade_out()
	Game.main.main_menu.disable()
	await Game.main.transition.faded_out
	get_tree().paused = true
	Game.main.main_menu.hide()
	Game.main.world.load_level("level_1")
	Game.main.transition.fade_in()
	await Game.main.transition.faded_in
	get_tree().paused = false
