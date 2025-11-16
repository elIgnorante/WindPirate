extends Node2D

@onready var main_menu = $MainMenu
@onready var pause_menu = $PauseMenu
@onready var world = $World
@onready var transition = $Transition
@onready var parallax = $ParallaxBackground

func _ready():
	Game.main = self
	transition.fade_in()
	main_menu.show()
	await transition.fade_in()
	main_menu.enable()
