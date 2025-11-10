extends Area2D



@onready var sprite = $AnimatedSprite2D
@onready var collectCoinSfx = $CollectCoinSFX

#signal collected para cuando se recoge una moneda
signal collected

func _ready():
	sprite.play("idle")

func _on_body_entered(_body):
	sprite.play("collect")
	collectCoinSfx.play()
	
	#Implementar la logica para llevar el conteo de las monedas recolectas

func _on__sprite_animation_finished():
	queue_free()
