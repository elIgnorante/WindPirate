extends PlayerBaseState

@onready var coyote_timer = $CoyoteTimer
@onready var sfx = $LandingSFX

func enter():
	play("fall")
	if fsm.previous_state != "jump":
		coyote_timer.start()

func physics_update(delta):
	move(delta, true)

	if try_attack():
		return

	var can_coyote_jump := not coyote_timer.is_stopped()
	if can_coyote_jump and input.jump_just_pressed:
		change_state("jump")
		return

	if object.is_on_floor():
		if input.jump_buffer:
			change_state("jump")
		else:
			object.play_land_dust()
			sfx.play()
			change_state("idle" if input.x == 0 else "run")
		
