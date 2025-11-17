extends Area2D
class_name ShooterProjectile

@export var damage := 1
@export var gravity := 0.0
@export var lifetime := 4.0
@export var travel_animation := "travel"
@export var impact_animation := "impact"

var velocity := Vector2.ZERO
var active := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $Lifetime

func _ready() -> void:
    connect("body_entered", Callable(self, "_on_body_entered"))
    lifetime_timer.timeout.connect(_on_lifetime_timeout)
    lifetime_timer.start(lifetime)
    if sprite.sprite_frames and sprite.sprite_frames.has_animation(travel_animation):
        sprite.play(travel_animation)

func _physics_process(delta: float) -> void:
    if not active:
        return
    velocity.y += gravity * delta
    global_position += velocity * delta

func set_velocity(new_velocity: Vector2) -> void:
    velocity = new_velocity
    if velocity.x < 0:
        sprite.flip_h = true
    elif velocity.x > 0:
        sprite.flip_h = false

func _on_body_entered(body: Node) -> void:
    if not active:
        return
    if body is Player:
        body.take_damage(damage, global_position, int(sign(velocity.x)))
        _explode()
        return
    if body.has_method("take_damage"):
        body.take_damage(damage, global_position, int(sign(velocity.x)))
    _explode()

func _explode() -> void:
    if not active:
        return
    active = false
    collision_shape.disabled = true
    if sprite.sprite_frames and sprite.sprite_frames.has_animation(impact_animation):
        sprite.play(impact_animation)
        await sprite.animation_finished
    queue_free()

func _on_lifetime_timeout() -> void:
    _explode()
