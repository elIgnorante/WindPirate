extends Area2D



func _on_player_entered(player):
	player.sword = true
	$AnimatedSprite2D.visible = false
	$PickupSwordSFX.play()
	$CollisionShape2D.set_deferred("disabled", true)

func _on_pickup_sword_sfx_finished() -> void:
	queue_free()
