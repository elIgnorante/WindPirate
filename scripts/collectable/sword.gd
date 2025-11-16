extends Area2D



func _on_player_entered(body):
	if not (body is Player):
		return
	var player: Player = body
	player.sword = true
	$AnimatedSprite2D.visible = false
	$PickupSwordSFX.play()
	$CollisionShape2D.set_deferred("disabled", true)

func _on_pickup_sword_sfx_finished() -> void:
	queue_free()
