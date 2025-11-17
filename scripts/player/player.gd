extends CharacterBody2D
class_name Player

@onready var sprite = $AnimatedSprite2D
@onready var fsm = $FSM
@onready var input = $InputHandler
@onready var sword_hitbox = $SwordHitbox
@onready var invincibility_timer = $InvincibilityTimer
@onready var run_dust: AnimatedSprite2D = $RunDust
@onready var jump_dust: AnimatedSprite2D = $JumpDust
@onready var land_dust: AnimatedSprite2D = $LandDust
@onready var sword_effect: AnimatedSprite2D = $SwordEffect

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
var dead: bool = false

const GROUND_ATTACKS: Array[StringName] = [
        &"attack_1",
        &"attack_2",
        &"attack_3",
]
const AIR_ATTACKS: Array[StringName] = [
        &"air_attack_1",
        &"air_attack_2",
]
var ground_attack_index := 0
var air_attack_index := 0
var _sword_hitbox_offset := 0.0
var _sword_effect_offset := 0.0

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
                if is_instance_valid(sword_effect):
                        sword_effect.flip_h = sprite.flip_h
                        sword_effect.position.x = _sword_effect_offset * value
                if is_instance_valid(run_dust):
                        run_dust.flip_h = sprite.flip_h
                if is_instance_valid(jump_dust):
                        jump_dust.flip_h = sprite.flip_h
                if is_instance_valid(land_dust):
                        land_dust.flip_h = sprite.flip_h
                if is_instance_valid(sword_hitbox):
                        sword_hitbox.position.x = _sword_hitbox_offset * value

        get:
                return _direction


func _ready() -> void:
        fsm.change_state("idle")
        invincibility_timer.wait_time = invincibility_time
        invincibility_timer.timeout.connect(Callable(self, "_on_invincibility_timer_timeout"))
        sword_hitbox.visible = sword

        _sword_hitbox_offset = abs(sword_hitbox.position.x)
        _sword_effect_offset = abs(sword_effect.position.x) if is_instance_valid(sword_effect) else 0.0
        if is_instance_valid(jump_dust):
                jump_dust.visible = false
                jump_dust.animation_finished.connect(Callable(self, "_on_dust_animation_finished").bind(jump_dust))
        if is_instance_valid(land_dust):
                land_dust.visible = false
                land_dust.animation_finished.connect(Callable(self, "_on_dust_animation_finished").bind(land_dust))
        if is_instance_valid(run_dust):
                run_dust.visible = false
        if is_instance_valid(sword_effect):
                sword_effect.visible = false
                sword_effect.animation_finished.connect(Callable(self, "_on_sword_effect_finished"))

        health = max_health
        health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	input.update()
	fsm.physics_update(delta)


func can_attack() -> bool:
        return sword and not attack_locked and not dead


func start_attack(animation_name: StringName = &"attack_1") -> void:
        attack_locked = true
        sword_hitbox.activate()
        play_sword_effect(animation_name)


func end_attack() -> void:
        await get_tree().process_frame
        attack_locked = false
        sword_hitbox.deactivate()


func take_damage(amount: int, source_position: Vector2, direction: int = 0) -> void:
        if invincible or dead:
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
                die()


func heal(amount: int) -> void:
        health = clamp(health + amount, 0, max_health)
        health_changed.emit(health, max_health)


func _on_invincibility_timer_timeout() -> void:
        if dead:
                return
        invincible = false
        sprite.modulate = Color.WHITE


# Opcional: mantener las funciones viejas para compatibilidad
func set_sword(value: bool) -> void:
	sword = value


func set_direction(value: int) -> void:
        direction = value


func reset_attack_combo(is_air_attack: bool) -> void:
        if is_air_attack:
                        air_attack_index = 0
        else:
                        ground_attack_index = 0


func get_next_attack_animation(is_air_attack: bool) -> StringName:
        var pool = AIR_ATTACKS if is_air_attack else GROUND_ATTACKS
        var index = air_attack_index if is_air_attack else ground_attack_index
        index = clamp(index, 0, pool.size() - 1)
        var animation: StringName = pool[index]
        if is_air_attack:
                        air_attack_index = min(air_attack_index + 1, pool.size() - 1)
        else:
                        ground_attack_index = min(ground_attack_index + 1, pool.size() - 1)
        return animation


func play_run_dust(active: bool) -> void:
        if not is_instance_valid(run_dust):
                return
        run_dust.visible = active
        if active:
                run_dust.animation = "run"
                run_dust.play()
        else:
                run_dust.stop()
                run_dust.frame = 0


func play_jump_dust() -> void:
        _play_one_shot_dust(jump_dust, "jump")


func play_land_dust() -> void:
        _play_one_shot_dust(land_dust, "land")


func _play_one_shot_dust(effect: AnimatedSprite2D, animation: StringName) -> void:
        if not is_instance_valid(effect):
                return
        effect.visible = true
        effect.animation = animation
        effect.frame = 0
        effect.play()


func play_sword_effect(animation_name: StringName) -> void:
        if not sword or not is_instance_valid(sword_effect):
                return
        if not sword_effect.sprite_frames.has_animation(animation_name):
                return
        sword_effect.visible = true
        sword_effect.animation = animation_name
        sword_effect.frame = 0
        sword_effect.play()


func _on_dust_animation_finished(_anim_name: StringName, effect: AnimatedSprite2D) -> void:
        effect.visible = false


func _on_sword_effect_finished(_anim_name: StringName) -> void:
        sword_effect.visible = false


func die() -> void:
        if dead:
                return
        dead = true
        invincibility_timer.stop()
        invincible = true
        sprite.modulate = Color.WHITE
        sword_hitbox.deactivate()
        fsm.change_state("death")
