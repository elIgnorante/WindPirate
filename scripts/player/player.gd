extends CharacterBody2D
class_name Player

@onready var sprite = $AnimatedSprite2D
@onready var fsm = $FSM
@onready var input = $InputHandler
@onready var sword_hitbox = $SwordHitbox
@onready var invincibility_timer = $InvincibilityTimer

const AIR_MULTIPLIER = 0.7
const MAX_SPEED = 90.0
const ACCELERATION = 900.0

const JUMP_GRAVITY = 900.0
const FALL_GRAVITY = 500.0
const TERMINAL_VELOCITY = 180.0

@export var max_health: int = 5
var health: int
@export var invincibility_time: float = 0.75
@export var attack_cooldown: float = 0.35
var attack_locked: bool = false
var invincible: bool = false

signal died
signal jumped
signal landed
signal health_changed(current: int, max: int)
signal took_damage(current: int)

# --- Propiedad sword con setter/getter estilo Godot 4 ---

var _sword: bool = false
var sword: bool:
	set(value):
		if _sword == value:
			return
		_sword = value

		var current_anim: StringName = sprite.animation
		var target_anim: StringName = current_anim

		if value:
			target_anim += "_sword"
		else:
			target_anim = target_anim.replace("_sword", "")

		if sprite.sprite_frames.has_animation(target_anim):
			var progress: float = sprite.frame_progress
			var frame: int = sprite.frame
			sprite.play(target_anim)
			sprite.set_frame_and_progress(frame, progress)

		sword_hitbox.visible = value
		if not value:
			sword_hitbox.deactivate()

	get:
		return _sword

# --- Propiedad direction con setter/getter estilo Godot 4 ---

var _direction: int = 1
var direction: int:
	set(value):
		if value == 0 or value == _direction:
			return
		_direction = value
		sprite.flip_h = (value == -1)

	get:
		return _direction


func _ready() -> void:
	fsm.change_state("idle")
	invincibility_timer.wait_time = invincibility_time
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	sword_hitbox.visible = sword

	health = max_health
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	input.update()
	fsm.physics_update(delta)


func can_attack() -> bool:
	return sword and not attack_locked


func start_attack() -> void:
	attack_locked = true
	sword_hitbox.activate()


func end_attack() -> void:
	await get_tree().process_frame
	attack_locked = false
	sword_hitbox.deactivate()


func take_damage(amount: int, source_position: Vector2, direction: int = 0) -> void:
	if invincible:
		return

	health = max(0, health - amount)
	invincible = true
	sprite.modulate = Color(1, 0.5, 0.5)

	invincibility_timer.start(invincibility_time)

	var dir: int = direction
	if dir == 0:
		dir = int(sign(global_position.x - source_position.x))

	velocity.x = dir * MAX_SPEED
	velocity.y = -120.0

	health_changed.emit(health, max_health)
	took_damage.emit(health)

	if health <= 0:
		died.emit()


func heal(amount: int) -> void:
	health = clamp(health + amount, 0, max_health)
	health_changed.emit(health, max_health)


func _on_invincibility_timer_timeout() -> void:
	invincible = false
	sprite.modulate = Color.WHITE


# Opcional: mantener las funciones viejas para compatibilidad
func set_sword(value: bool) -> void:
	sword = value


func set_direction(value: int) -> void:
	direction = value
