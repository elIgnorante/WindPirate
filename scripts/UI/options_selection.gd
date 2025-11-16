extends Label

@export var from_pause := false

func select():
        Game.main.open_options_menu(from_pause)
