extends CharacterBody2D

@export var patrol_distance := 160.0
@export var speed := 70.0
@export var gravity := 1000.0
@export var attack_speed := 220.0
@export var jump_impulse := 360.0
@export var max_health := 4
@export var contact_damage := 1
@export var attack_cooldown := 1.4
@export var anticipation_time := 0.25
@export var attack_offset := 28.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackCooldown
@onready var anticipation_timer: Timer = $AnticipationTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var floor_check_left: RayCast2D = $FloorCheckLeft
@onready var floor_check_right: RayCast2D = $FloorCheckRight

var origin := Vector2.ZERO
var direction := -1
var health := 0
var attacking := false
var airborne := false
var landing_recovering := false
var tracked_target: Player = null

func _ready():
	origin = global_position
	health = max_health
	attack_area.monitoring = false
	sprite.play("run")
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)
	anticipation_timer.timeout.connect(_on_anticipation_timeout)
	_apply_direction()

func _physics_process(delta):
	if not attacking and not landing_recovering:
		velocity.x = direction * speed

	velocity.y = min(velocity.y + gravity * delta, 900.0)
	move_and_slide()

	if not attacking and not landing_recovering:
		if is_on_wall():
			_flip_direction()
		var floor_check := floor_check_left if direction < 0 else floor_check_right
		if not floor_check.is_colliding():
			_flip_direction()
		if abs(global_position.x - origin.x) >= patrol_distance:
			_flip_direction()

	if attacking and airborne and is_on_floor() and velocity.y >= 0.0 and not landing_recovering:
		airborne = false
		call_deferred("_handle_landing")

	if tracked_target and not attacking and not landing_recovering and attack_timer.is_stopped():
		if is_instance_valid(tracked_target):
			_start_attack()
		else:
			tracked_target = null

	_update_movement_animation()

func _update_movement_animation():
	if attacking or landing_recovering:
		return
	if not is_on_floor():
		if velocity.y < 0.0 and sprite.animation != "jump":
			sprite.play("jump")
		elif velocity.y >= 0.0 and sprite.animation != "fall":
			sprite.play("fall")
	elif sprite.animation != "run":
		sprite.play("run")

func _apply_direction():
	sprite.flip_h = direction < 0
	attack_area.position.x = attack_offset * direction

func _flip_direction():
	direction *= -1
	_apply_direction()

func _start_attack():
	if not tracked_target or not is_instance_valid(tracked_target):
		tracked_target = null
		return
	var distance_to_target := tracked_target.global_position.x - global_position.x
	if distance_to_target != 0:
		direction = sign(distance_to_target)
		_apply_direction()
	attacking = true
	landing_recovering = false
	sprite.play("anticipation")
	velocity.x = 0
	anticipation_timer.start(anticipation_time)

func _on_anticipation_timeout():
	if not attacking:
		return
	airborne = true
	sprite.play("attack")
	attack_area.monitoring = true
	velocity.x = direction * attack_speed
	velocity.y = -jump_impulse

func _handle_landing():
	if landing_recovering:
		return
	landing_recovering = true
	attack_area.monitoring = false
	sprite.play("ground")
	await sprite.animation_finished
	landing_recovering = false
	attacking = false
	attack_timer.start(attack_cooldown)
	if is_on_floor():
		sprite.play("run")

func _on_attack_area_body_entered(body):
	if not attack_area.monitoring:
		return
	if body is Player:
		var player: Player = body
		player.take_damage(contact_damage, global_position, direction)
		attack_area.monitoring = false

func _on_detection_area_body_entered(body):
	if body is Player:
		tracked_target = body

func _on_detection_area_body_exited(body):
	if tracked_target == body:
		tracked_target = null

func _on_attack_cooldown_timeout():
	attack_timer.stop()

func take_damage(amount, source_position: Vector2, direction_override := 0):
	if health <= 0:
		return
	health = max(0, health - amount)
	attacking = false
	landing_recovering = false
	airborne = false
	attack_area.monitoring = false
	anticipation_timer.stop()
	attack_timer.stop()
	var dir := -direction_override if direction_override != 0 else sign(global_position.x - source_position.x)
	if dir == 0:
		dir = -direction
	velocity.x = dir * speed
	velocity.y = -jump_impulse * 0.2
	if health <= 0:
		_die()
		return
	sprite.play("hit")
	await sprite.animation_finished
	if is_on_floor():
		sprite.play("run")
	else:
		sprite.play("fall")
	attack_timer.start(attack_cooldown)

func _die():
	attacking = true
	attack_timer.stop()
	anticipation_timer.stop()
	attack_area.monitoring = false
	detection_area.monitoring = false
	collision_shape.disabled = true
	sprite.play("death_ground" if is_on_floor() else "death_air")
	await sprite.animation_finished
	queue_free()
