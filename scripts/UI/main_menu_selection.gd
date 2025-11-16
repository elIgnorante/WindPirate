extends Label

func select():
	var main_menu = Game.main.main_menu
	var pause_menu = Game.main.pause_menu
	var transition = Game.main.transition
	
	pause_menu.disable()
	transition.fade_out()
	await transition.faded_out
	pause_menu.hide()
	main_menu.show()
	main_menu.selection_index = 0
	Game.main.world.unload()
	await get_tree().process_frame
	get_tree().paused = false
	Game.main.parallax.scroll_offset = Vector2.ZERO
	transition.fade_in()
	await transition.faded_in
	main_menu.enable()
