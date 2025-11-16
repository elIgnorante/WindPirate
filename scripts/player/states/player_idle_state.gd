extends PlayerBaseState

func enter() -> void:
	play("idle")
	
func physics_update(delta: float) -> void:
	move(delta, false)

	if try_attack():
		return

	if input.jump_just_pressed:
		change_state("jump")
	elif not object.is_on_floor():
		change_state("fall")
	elif input.x != 0:
		change_state("run")
