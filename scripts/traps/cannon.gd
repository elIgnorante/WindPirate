extends ShooterTrap

@export var projectile_scene: PackedScene
@export var fire_interval := 2.0
@export var fire_delay := 0.25
@export var projectile_speed := 220.0
@export var projectile_damage := 1
@export var facing_left := false

var _target_count := 0
var _direction := 1
var _base_fire_point := Vector2.ZERO
var _shooting := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: AnimatedSprite2D = $MuzzleFlash
@onready var fire_point: Marker2D = $FirePoint
@onready var fire_timer: Timer = $FireTimer
@onready var detection_area: Area2D = $DetectionArea
@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
    super._ready()
    _direction = -1 if facing_left else 1
    _base_fire_point = fire_point.position
    _apply_direction()
    detection_area.body_entered.connect(_on_detection_body_entered)
    detection_area.body_exited.connect(_on_detection_body_exited)
    damage_area.body_entered.connect(_on_damage_body_entered)
    damage_area.body_exited.connect(_on_damage_body_exited)
    fire_timer.timeout.connect(_on_fire_timer_timeout)
    sprite.animation_finished.connect(_on_sprite_animation_finished)
    muzzle.animation_finished.connect(func():
        muzzle.visible = false)
    muzzle.visible = false
    sprite.play("idle")

func _apply_direction() -> void:
    sprite.flip_h = _direction == -1
    muzzle.flip_h = sprite.flip_h
    fire_point.position = Vector2(_base_fire_point.x * _direction, _base_fire_point.y)

func _on_detection_body_entered(body: Node) -> void:
    if not (body is Player):
        return
    _target_count += 1
    if fire_timer.is_stopped():
        fire_timer.start(fire_interval)

func _on_detection_body_exited(body: Node) -> void:
    if not (body is Player):
        return
    _target_count = max(0, _target_count - 1)
    if _target_count == 0:
        fire_timer.stop()

func _on_damage_body_entered(body: Node) -> void:
    apply_contact_damage(body)

func _on_damage_body_exited(body: Node) -> void:
    reset_contact(body)

func _on_fire_timer_timeout() -> void:
    if dead or _target_count == 0:
        return
    fire_timer.start(fire_interval)
    _shoot()

func _shoot() -> void:
    if projectile_scene == null:
        return
    _shooting = true
    sprite.play("fire")
    muzzle.visible = true
    muzzle.play("fire")
    var timer := get_tree().create_timer(fire_delay)
    timer.timeout.connect(_spawn_projectile)

func _spawn_projectile() -> void:
    if dead or projectile_scene == null:
        return
    var projectile := projectile_scene.instantiate()
    if projectile is ShooterProjectile:
        projectile.damage = projectile_damage
        projectile.set_velocity(Vector2(projectile_speed * _direction, 0))
    if projectile is Node2D:
        projectile.global_position = fire_point.global_position
    add_to_world(projectile)

func _on_hit() -> void:
    if dead:
        return
    if _shooting:
        return
    sprite.play("hit")

func _on_death() -> void:
    fire_timer.stop()
    detection_area.monitoring = false
    damage_area.monitoring = false
    sprite.play("death")

func _on_sprite_animation_finished() -> void:
    match sprite.animation:
        "fire":
            _shooting = false
            if not dead:
                sprite.play("idle")
        "hit":
            if not dead and not _shooting:
                sprite.play("idle")
        "death":
            queue_free()
