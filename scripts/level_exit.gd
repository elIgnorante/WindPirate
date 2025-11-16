extends Area2D

signal activated

@export var locked := false
@onready var collision = $CollisionShape2D
@onready var sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func set_locked(value):
		locked = value
		if sprite:
				sprite.modulate = Color(1, 0.4, 0.4) if locked else Color.WHITE

func _on_body_entered(body):
		if body is Player and not locked:
				activated.emit()
