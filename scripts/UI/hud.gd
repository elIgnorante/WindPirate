extends CanvasLayer

@onready var health_label = $Panel/MarginContainer/VBoxContainer/HealthLabel
@onready var coins_label = $Panel/MarginContainer/VBoxContainer/CoinsLabel
@onready var level_label = $Panel/MarginContainer/VBoxContainer/LevelLabel
@onready var message_label = $MessageLabel
@onready var message_timer = $MessageTimer

func _ready():
		hide()
		message_label.visible = false
		message_timer.timeout.connect(_on_message_timer_timeout)

func reset():
		update_health(0, 0)
		update_coins(0, 0)
		update_level("")
		message_label.visible = false

func update_health(current, max):
		if max <= 0:
			health_label.text = "hp: --"
		else:
			health_label.text = "hp: %d/%d" % [current, max]

func update_coins(current, total):
		if total <= 0:
			coins_label.text = "coins: --"
		else:
			coins_label.text = "coins: %d/%d" % [current, total]

func update_level(name):
		if name == "":
			level_label.text = ""
		else:
			level_label.text = "level: %s" % name

func flash_message(text):
		message_label.text = text
		message_label.visible = true
		message_timer.start()

func _on_message_timer_timeout():
		message_label.visible = false
