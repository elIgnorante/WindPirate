extends CharacterBody2D

@export var patrol_distance := 96.0
@export var speed := 45.0
@export var gravity := 900.0
@export var max_health := 3
@export var contact_damage := 1
@export var attack_cooldown := 1.2

@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_timer = $AttackCooldown
@onready var collision_shape = $CollisionShape2D

var origin := Vector2.ZERO
var direction := -1
var health := max_health
var attacking := false

func _ready():
        origin = global_position
        sprite.play("run")
        sprite.flip_h = direction < 0
        attack_area.body_entered.connect(_on_attack_area_body_entered)
        attack_timer.timeout.connect(_on_attack_cooldown_timeout)

func _physics_process(delta):
        if not attacking:
                velocity.x = direction * speed
        else:
                velocity.x = 0
        velocity.y = min(velocity.y + gravity * delta, 300.0)
        move_and_slide()
        if is_on_wall():
                _flip_direction()
        if not attacking and abs(global_position.x - origin.x) >= patrol_distance:
                _flip_direction()

func _flip_direction():
        direction *= -1
        sprite.flip_h = direction < 0

func _on_attack_area_body_entered(body):
        if body is Player and attack_timer.is_stopped():
                _attack(body)

func _attack(player: Player):
        attacking = true
        sprite.play("attack")
        player.take_damage(contact_damage, global_position, direction)
        attack_timer.start(attack_cooldown)
        await sprite.animation_finished
        attacking = false
        if health > 0:
                sprite.play("run")

func take_damage(amount, source_position: Vector2, direction_override := 0):
        if health <= 0:
                return
        health = max(0, health - amount)
        var dir = -direction_override if direction_override != 0 else sign(global_position.x - source_position.x)
        velocity.x = dir * speed
        sprite.play("hit")
        if health <= 0:
                _die()
                return
        await sprite.animation_finished
        sprite.play("run")

func _die():
        attacking = true
        attack_area.monitoring = false
        collision_shape.disabled = true
        sprite.play("death")
        await sprite.animation_finished
        queue_free()

func _on_attack_cooldown_timeout():
        attack_timer.stop()
