extends Label

func select():
var pause_menu = Game.main.pause_menu
var transition = Game.main.transition

        pause_menu.disable()
        transition.fade_out()
        await transition.faded_out
        pause_menu.hide()
        await Game.main.return_to_menu()
