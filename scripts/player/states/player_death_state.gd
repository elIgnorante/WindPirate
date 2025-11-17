extends PlayerBaseState

var finished := false
var _animation_callable := Callable(self, "_on_animation_finished")

func enter():
        finished = false
        object.velocity = Vector2.ZERO
        object.play_run_dust(false)
        play("dead")
        if not object.sprite.animation_finished.is_connected(_animation_callable):
                object.sprite.animation_finished.connect(_animation_callable)

func physics_update(delta):
        if finished:
                return
        object.velocity.y = move_toward(object.velocity.y, Player.TERMINAL_VELOCITY, Player.FALL_GRAVITY * delta)
        object.move_and_slide()

func exit():
        if object.sprite.animation_finished.is_connected(_animation_callable):
                object.sprite.animation_finished.disconnect(_animation_callable)

func _on_animation_finished(_anim_name: StringName) -> void:
        if finished:
                return
        finished = true
        object.died.emit()
