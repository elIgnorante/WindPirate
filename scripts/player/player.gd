extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

var direction :
	get: return direction
	set(value):
		if value == 0 or value == direction: return
		direction = value
		sprite.flip_h = value == -1

func _physics_process(delta):
	var x_input = Input.get_axis("btn_left", "btn_right")
	direction = x_input
	velocity.x = x_input * 90
	
	if x_input == 0:
		sprite.play("idle")
	else:
		sprite.play("run")
	
	move_and_slide()
