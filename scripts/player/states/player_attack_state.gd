extends PlayerBaseState

var finished := false
var queued_combo := false
var current_animation: StringName = ""
var air_attack := false
var _animation_callable := Callable(self, "_on_animation_finished")

func enter():
		if not object.can_attack():
				change_state("idle")
				return
		finished = false
		queued_combo = false
		air_attack = not object.is_on_floor()
		object.reset_attack_combo(air_attack)
		_play_next_combo()
		object.sprite.animation_finished.connect(_animation_callable)

func physics_update(_delta):
		move(_delta, true, false, 0)
		if not finished and input.attack_just_pressed:
				queued_combo = true
		if finished:
			if object.input.x != 0:
				change_state("run")
			else:
				change_state("idle")

func exit():
		object.end_attack()
		if object.sprite.animation_finished.is_connected(_animation_callable):
				object.sprite.animation_finished.disconnect(_animation_callable)

func _play_next_combo() -> void:
		var base_anim: StringName = object.get_next_attack_animation(air_attack)
		current_animation = play(base_anim)
		object.start_attack(base_anim)
		object.velocity.x = 0

func _on_animation_finished():
		if object.sprite.animation != current_animation:
				return
		if queued_combo:
				queued_combo = false
				finished = false
				_play_next_combo()
				return
		finished = true
