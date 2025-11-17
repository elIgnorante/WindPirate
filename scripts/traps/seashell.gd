extends ShooterTrap

@export var projectile_scene: PackedScene
@export var fire_interval := 2.25
@export var projectile_speed := 140.0
@export var projectile_damage := 1
@export var projectile_gravity := 360.0
@export var bite_damage := 2
@export var facing_left := false

var _direction := 1
var _target_count := 0
var _opened := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_point: Marker2D = $FirePoint
@onready var detection_area: Area2D = $DetectionArea
@onready var damage_area: Area2D = $DamageArea
@onready var bite_area: Area2D = $BiteArea
@onready var fire_timer: Timer = $FireTimer
@onready var bite_timer: Timer = $BiteCooldown

func _ready() -> void:
    super._ready()
    _direction = -1 if facing_left else 1
    sprite.flip_h = _direction == -1
    fire_point.position.x *= _direction
    detection_area.body_entered.connect(_on_detection_body_entered)
    detection_area.body_exited.connect(_on_detection_body_exited)
    damage_area.body_entered.connect(_on_damage_body_entered)
    damage_area.body_exited.connect(_on_damage_body_exited)
    bite_area.body_entered.connect(_on_bite_body_entered)
    bite_area.body_exited.connect(_on_bite_body_exited)
    fire_timer.timeout.connect(_on_fire_timer_timeout)
    sprite.animation_finished.connect(_on_sprite_animation_finished)
    sprite.play("idle")

func _on_detection_body_entered(body: Node) -> void:
    if not (body is Player):
        return
    _target_count += 1
    if not _opened:
        _opened = true
        sprite.play("opening")
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

func _on_bite_body_entered(body: Node) -> void:
    if not (body is Player):
        return
    if bite_timer.is_stopped():
        body.take_damage(bite_damage, global_position, _direction)
        sprite.play("bite")
        bite_timer.start()

func _on_bite_body_exited(body: Node) -> void:
    reset_contact(body)

func _on_fire_timer_timeout() -> void:
    if dead or _target_count == 0:
        return
    fire_timer.start(fire_interval)
    _shoot()

func _shoot() -> void:
    if projectile_scene == null:
        return
    sprite.play("fire")
    var timer := get_tree().create_timer(0.2)
    timer.timeout.connect(_spawn_pearl)

func _spawn_pearl() -> void:
    if dead or projectile_scene == null:
        return
    var pearl := projectile_scene.instantiate()
    if pearl is ShooterProjectile:
        pearl.damage = projectile_damage
        pearl.gravity = projectile_gravity
        var velocity := Vector2(projectile_speed * _direction, -projectile_speed * 0.45)
        pearl.set_velocity(velocity)
    if pearl is Node2D:
        pearl.global_position = fire_point.global_position
    add_to_world(pearl)

func _on_hit() -> void:
    if dead:
        return
    sprite.play("hit")

func _on_death() -> void:
    detection_area.monitoring = false
    bite_area.monitoring = false
    fire_timer.stop()
    bite_timer.stop()
    sprite.play("death")

func _on_sprite_animation_finished() -> void:
    match sprite.animation:
        "opening":
            sprite.play("ready")
        "fire":
            if not dead:
                sprite.play("ready")
        "bite":
            if not dead:
                sprite.play("ready")
        "hit":
            if not dead:
                sprite.play("ready" if _opened else "idle")
        "death":
            queue_free()
