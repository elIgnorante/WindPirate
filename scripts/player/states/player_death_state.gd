extends PlayerBaseState

var finished := false
var _animation_finished_callable := Callable(self, "_on_animation_finished")
var _animation_looped_callable := Callable(self, "_on_animation_looped")

func enter():
        finished = false
        object.velocity = Vector2.ZERO
        object.play_run_dust(false)
        play("dead")
        if not object.sprite.animation_finished.is_connected(_animation_finished_callable):
                object.sprite.animation_finished.connect(_animation_finished_callable)
        if not object.sprite.animation_looped.is_connected(_animation_looped_callable):
                object.sprite.animation_looped.connect(_animation_looped_callable)

func physics_update(delta):
        if finished:
                return
        object.velocity.y = move_toward(object.velocity.y, Player.TERMINAL_VELOCITY, Player.FALL_GRAVITY * delta)
        object.move_and_slide()

func exit():
        if object.sprite.animation_finished.is_connected(_animation_finished_callable):
                object.sprite.animation_finished.disconnect(_animation_finished_callable)
        if object.sprite.animation_looped.is_connected(_animation_looped_callable):
                object.sprite.animation_looped.disconnect(_animation_looped_callable)

func _on_animation_finished() -> void:
        if finished:
                return
        finished = true
        object.died.emit()

func _on_animation_looped() -> void:
        _on_animation_finished()
