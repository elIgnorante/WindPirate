extends Node2D

@onready var main_menu = $MainMenu
@onready var pause_menu = $PauseMenu
@onready var world = $World
@onready var transition = $Transition
@onready var parallax = $ParallaxBackground
@onready var hud = $HUD
@onready var options_menu = $OptionsMenu

func _ready():
		Game.main = self
		transition.fade_in()
		main_menu.show()
		await transition.fade_in()
		main_menu.enable()
		hud.hide()

func start_new_game():
		transition.fade_out()
		main_menu.disable()
		await transition.faded_out
		get_tree().paused = false
		hud.reset()
		hud.show()
		world.load_level("level_1")
		main_menu.hide()
		transition.fade_in()
		await transition.faded_in

func return_to_menu():
		get_tree().paused = false
		if world.current_level:
				world.unload()
		hud.reset()
		hud.hide()
		parallax.scroll_offset = Vector2.ZERO
		pause_menu.hide()
		pause_menu.disable()
		main_menu.show()
		main_menu.selection_index = 0
		transition.fade_in()
		await transition.faded_in
		main_menu.enable()

func open_options_menu(from_pause: bool):
		if from_pause:
				pause_menu.disable()
				pause_menu.hide()
		else:
				main_menu.disable()
				main_menu.hide()
		options_menu.open(from_pause)

func on_options_closed(return_to_pause: bool):
		if return_to_pause:
				pause_menu.show()
				pause_menu.enable()
		else:
				main_menu.show()
				main_menu.enable()

func options_menu_visible():
		return options_menu.visible
