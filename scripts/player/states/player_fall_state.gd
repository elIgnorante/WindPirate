extends PlayerBaseState

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var sfx: AudioStreamPlayer = $LandingSFX

func enter() -> void:
	play("fall")
	if fsm.previous_state != "jump":
		coyote_timer.start()

func physics_update(delta: float) -> void:
	move(delta, true)

	if try_attack():
		return

	var can_coyote_jump: bool = not coyote_timer.is_stopped()
	if can_coyote_jump and input.jump_just_pressed:
		change_state("jump")
		return

	if object.is_on_floor():
		if input.jump_buffer:
			change_state("jump")
		else:
			object.play_land_dust()
			sfx.play()
			var target_state := "idle"
			if input.x != 0:
				target_state = "run"
			change_state(target_state)
