extends PlayerBaseState

var finished = false

func enter():
        if not object.can_attack():
                change_state("idle")
                return
        finished = false
        object.start_attack()
        play("attack")
        object.velocity.x = 0
        object.sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func physics_update(_delta):
        move(_delta, true, false, 0)
        if finished:
            if object.input.x != 0:
                change_state("run")
            else:
                change_state("idle")

func exit():
        object.end_attack()

func _on_animation_finished(_anim_name = ""):
        finished = true
