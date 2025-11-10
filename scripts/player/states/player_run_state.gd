extends PlayerBaseState

@onready var sfx = $FootstepsSFX
@onready var sfx_timer = $FootstepsTimer

func enter():
	play("run")
	sfx.play()
	sfx_timer.start()
	
func physics_update(delta):
	move(delta, false)
	
	if input.jump_just_pressed:
		change_state("jump")
	elif not object.is_on_floor():
		change_state("fall")
	elif input.x == 0:
		change_state("idle")


func exit():
	sfx_timer.stop()

func _on_footsteps_timer_timeout() -> void:
	sfx.play()
