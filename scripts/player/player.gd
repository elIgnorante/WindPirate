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

@export var max_health := 5
var health := max_health
@export var invincibility_time := 0.75
@export var attack_cooldown := 0.35
var attack_locked := false
var invincible := false

#Sword states
var sword = false :
        get: return sword
        set (value):
                if sword == value: return
                sword = value
                var current_anim = sprite.animation
                var target_anim = current_anim
                if value:
                        target_anim += "_sword"
                else:
                        target_anim = target_anim.replace("_sword", "")
                if sprite.sprite_frames.has_animation(target_anim):
                        var progress = sprite.frame_progress
                        var frame = sprite.frame
                        sprite.play(target_anim)
                        sprite.set_frame_and_progress(frame, progress)
                sword_hitbox.visible = value
                if not value:
                        sword_hitbox.deactivate()

signal died
signal jumped
signal landed
signal health_changed(current, max)
signal took_damage(current)

var direction :
	get: return direction
	set(value):
		if value == 0 or value == direction: return
		direction = value
		sprite.flip_h = value == -1
		
func _ready():
        fsm.change_state("idle")
        invincibility_timer.wait_time = invincibility_time
        invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
        sword_hitbox.visible = sword
        health = max_health
        health_changed.emit(health, max_health)

func _physics_process(delta):
        input.update()
        fsm.physics_update(delta)

func can_attack():
        return sword and not attack_locked

func start_attack():
        attack_locked = true
        sword_hitbox.activate()

func end_attack():
        await get_tree().process_frame
        attack_locked = false
        sword_hitbox.deactivate()

func take_damage(amount, source_position: Vector2, direction := 0):
        if invincible:
                return
        health = max(0, health - amount)
        invincible = true
        sprite.modulate = Color(1, 0.5, 0.5)
        invincibility_timer.start(invincibility_time)
        var dir = direction if direction != 0 else sign(global_position.x - source_position.x)
        velocity.x = dir * MAX_SPEED
        velocity.y = -120
        health_changed.emit(health, max_health)
        took_damage.emit(health)
        if health <= 0:
                died.emit()

func heal(amount):
        health = clamp(health + amount, 0, max_health)
        health_changed.emit(health, max_health)

func _on_invincibility_timer_timeout():
        invincible = false
        sprite.modulate = Color.WHITE
