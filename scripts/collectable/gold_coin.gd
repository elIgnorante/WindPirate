extends Area2D

@onready var sprite = $AnimatedSprite2D
@onready var collectCoinSfx = $CollectCoinSFX
@onready var collision_shape = $CollisionShape2D

signal collected

func _ready():
        sprite.play("idle")

func _on_body_entered(_body):
        sprite.play("collect")
        collectCoinSfx.play()
        collision_shape.set_deferred("disabled", true)
        collected.emit()

func _on__sprite_animation_finished():
        if sprite.animation == "collect":
                queue_free()
