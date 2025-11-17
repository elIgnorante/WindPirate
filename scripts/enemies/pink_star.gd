extends CharacterBody2D

@export var patrol_distance: float = 128.0
@export var walk_speed: float = 50.0
@export var gravity: float = 980.0
@export var attack_speed: float = 260.0
@export var attack_jump_impulse: float = 340.0
@export var max_health: int = 4
@export var contact_damage: int = 1
@export var attack_cooldown: float = 1.5
@export var anticipation_time: float = 0.25
@export var attack_offset: Vector2 = Vector2(20, -6)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackCooldown
@onready var anticipation_timer: Timer = $AnticipationTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var floor_check_left: RayCast2D = $FloorCheckLeft
@onready var floor_check_right: RayCast2D = $FloorCheckRight
@onready var attack_effect: AnimatedSprite2D = $AttackEffect

var origin: Vector2 = Vector2.ZERO
var direction: int = -1
var health: int = 0
var attacking: bool = false
var airborne: bool = false
var recovering: bool = false
var tracked_target: Player = null


func _ready() -> void:
	origin = global_position
	health = max_health
	attack_area.monitoring = false
	detection_area.monitoring = true
	sprite.play("idle")
	attack_effect.visible = false

	attack_area.body_entered.connect(_on_attack_area_body_entered)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)
	anticipation_timer.timeout.connect(_on_anticipation_timeout)

	_apply_direction()


func _physics_process(delta: float) -> void:
	if not attacking and not recovering:
		if patrol_distance > 0.0:
			velocity.x = direction * walk_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, walk_speed)
	else:
		pass

	velocity.y = min(velocity.y + gravity * delta, 900.0)
	move_and_slide()

	if not attacking and not recovering and patrol_distance > 0.0:
		if is_on_wall():
			_flip_direction()

		var floor_check: RayCast2D = floor_check_left
		if direction >= 0:
			floor_check = floor_check_right

		if floor_check and not floor_check.is_colliding():
			_flip_direction()

		if abs(global_position.x - origin.x) >= patrol_distance:
			_flip_direction()

	if attacking and airborne and is_on_floor() and velocity.y >= 0.0:
		airborne = false
		call_deferred("_finish_attack")

	if tracked_target and not attacking and not recovering and attack_timer.is_stopped():
		if is_instance_valid(tracked_target):
			_start_attack()
		else:
			tracked_target = null

	_update_movement_animation()


func _update_movement_animation() -> void:
	if attacking or recovering:
		return

	if not is_on_floor():
		if velocity.y < 0.0 and sprite.animation != "jump":
			sprite.play("jump")
		elif velocity.y >= 0.0 and sprite.animation != "fall":
			sprite.play("fall")
	else:
		if patrol_distance > 0.0 and abs(velocity.x) > 5.0:
			if sprite.animation != "run":
				sprite.play("run")
		elif sprite.animation != "idle":
			sprite.play("idle")


func _apply_direction() -> void:
	sprite.flip_h = direction < 0
	attack_area.position.x = attack_offset.x * direction
	attack_effect.position.x = attack_offset.x * direction
	attack_effect.flip_h = direction < 0

	if attack_offset.y != 0.0:
		attack_area.position.y = attack_offset.y
		attack_effect.position.y = attack_offset.y


func _flip_direction() -> void:
	direction *= -1
	_apply_direction()


func _start_attack() -> void:
	if not tracked_target or not is_instance_valid(tracked_target):
		tracked_target = null
		return

	var distance_to_target: float = tracked_target.global_position.x - global_position.x
	if distance_to_target != 0.0:
		direction = int(sign(distance_to_target))
		_apply_direction()

	attacking = true
	recovering = false
	sprite.play("anticipation")
	velocity.x = 0.0
	anticipation_timer.start(anticipation_time)


func _on_anticipation_timeout() -> void:
	if not attacking:
		return

	airborne = true
	sprite.play("attack")
	attack_area.monitoring = true
	attack_effect.visible = true
	attack_effect.play("attack")
	velocity.x = direction * attack_speed
	velocity.y = -attack_jump_impulse


func _finish_attack() -> void:
	if recovering:
		return

	recovering = true
	attack_area.monitoring = false
	attack_effect.visible = false
	attack_effect.stop()
	sprite.play("ground")
	await sprite.animation_finished
	recovering = false
	attacking = false
	attack_timer.start(attack_cooldown)

	if is_on_floor():
		if patrol_distance > 0.0:
			sprite.play("run")
		else:
			sprite.play("idle")


func _on_attack_area_body_entered(body: Node) -> void:
	if not attack_area.monitoring:
		return

	if body is Player:
		var player: Player = body
		player.take_damage(contact_damage, global_position, direction)
		attack_area.monitoring = false
		attack_effect.visible = true
		if not attack_effect.is_playing():
			attack_effect.play("attack")


func _on_detection_area_body_entered(body: Node) -> void:
	if body is Player:
		tracked_target = body


func _on_detection_area_body_exited(body: Node) -> void:
	if tracked_target == body:
		tracked_target = null


func _on_attack_cooldown_timeout() -> void:
	attack_timer.stop()


func take_damage(amount: int, source_position: Vector2, direction_override: int = 0) -> void:
	if health <= 0:
		return

	health = max(0, health - amount)
	attacking = false
	recovering = false
	airborne = false
	attack_area.monitoring = false
	attack_effect.visible = false
	attack_effect.stop()
	anticipation_timer.stop()
	attack_timer.stop()

	var dir: int
	if direction_override != 0:
		dir = -direction_override
	else:
		dir = int(sign(global_position.x - source_position.x))
		if dir == 0:
			dir = -direction

	velocity.x = dir * walk_speed
	velocity.y = -attack_jump_impulse * 0.2

	if health <= 0:
		_die()
		return

	sprite.play("hit")
	await sprite.animation_finished

	if is_on_floor():
		if patrol_distance > 0.0:
			sprite.play("run")
		else:
			sprite.play("idle")
	else:
		sprite.play("fall")

	attack_timer.start(attack_cooldown)


func _die() -> void:
	attacking = true
	recovering = true
	attack_area.monitoring = false
	detection_area.monitoring = false
	collision_shape.disabled = true
	attack_effect.visible = false
	attack_effect.stop()
	sprite.play("dead_ground" if is_on_floor() else "dead_hit")
	await sprite.animation_finished
	queue_free()
