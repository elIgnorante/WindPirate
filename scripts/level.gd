extends Node2D

@export var level_name := "level_1"
@export var next_level := ""
@export var require_all_coins := false

@onready var player: Player = $Player
@onready var coins_container = $Coins
@onready var level_exit = $LevelExit

var total_coins := 0
var collected_coins := 0
var completed := false

func _ready():
        if player:
                player.health_changed.connect(_on_player_health_changed)
                player.died.connect(_on_player_died)
                Game.main.hud.update_health(player.health, player.max_health)
        Game.main.hud.update_level(level_name)
        _setup_coins()
        if level_exit:
                level_exit.activated.connect(_on_exit_activated)
                level_exit.set_locked(require_all_coins)
        Game.main.hud.show()

func _setup_coins():
        if coins_container:
                total_coins = coins_container.get_child_count()
                for coin in coins_container.get_children():
                        coin.collected.connect(_on_coin_collected)
        Game.main.hud.update_coins(collected_coins, total_coins)

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
        if event.is_action_pressed("ui_cancel") and not Game.main.options_menu_visible():
                pause()

func _on_player_health_changed(current, max):
        Game.main.hud.update_health(current, max)

func _on_coin_collected():
        collected_coins += 1
        Game.main.hud.update_coins(collected_coins, total_coins)
        if require_all_coins and level_exit:
                level_exit.set_locked(collected_coins < total_coins)

func _on_player_died():
        if completed:
                return
        Game.main.transition.fade_out()
        await Game.main.transition.faded_out
        Game.main.world.reload_current_level()
        Game.main.transition.fade_in()
        await Game.main.transition.faded_in

func _on_exit_activated():
        if require_all_coins and collected_coins < total_coins:
                Game.main.hud.flash_message("collect all coins!")
                return
        completed = true
        Game.main.transition.fade_out()
        await Game.main.transition.faded_out
        if next_level == "":
                await Game.main.return_to_menu()
        else:
                Game.main.world.load_level(next_level)
                Game.main.transition.fade_in()
                await Game.main.transition.faded_in
