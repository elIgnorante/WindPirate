extends ShooterTrap

@export_enum("head_1", "head_2", "head_3") var head_variant := 0
@export var projectile_scene: PackedScene
@export var fire_interval := 1.8
@export var projectile_speed := 200.0
@export var projectile_damage := 1
@export var projectile_gravity := 180.0
@export var facing_left := false

var _direction := 1
var _target_count := 0
var _active_head: AnimatedSprite2D
var _attack_toggle := false

@onready var head_one: AnimatedSprite2D = $Head1
@onready var head_two: AnimatedSprite2D = $Head2
@onready var head_three: AnimatedSprite2D = $Head3
@onready var fire_point: Marker2D = $FirePoint
@onready var detection_area: Area2D = $DetectionArea
@onready var damage_area: Area2D = $DamageArea
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
    super._ready()
    _direction = -1 if facing_left else 1
    fire_point.position.x *= _direction
    var heads := [head_one, head_two, head_three]
    for i in range(heads.size()):
        var head: AnimatedSprite2D = heads[i]
        head.visible = (i == head_variant)
        if head.visible:
            _active_head = head
    if _active_head == null:
        _active_head = head_one
    _active_head.flip_h = _direction == -1
    _active_head.animation_finished.connect(_on_sprite_animation_finished)
    detection_area.body_entered.connect(_on_detection_body_entered)
    detection_area.body_exited.connect(_on_detection_body_exited)
    damage_area.body_entered.connect(_on_damage_body_entered)
    damage_area.body_exited.connect(_on_damage_body_exited)
    fire_timer.timeout.connect(_on_fire_timer_timeout)
    _active_head.play("idle")

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
    var animation_name := "attack" if not _attack_toggle else "attack_alt"
    if not _active_head.sprite_frames.has_animation(animation_name):
        animation_name = "attack"
    _active_head.play(animation_name)
    _attack_toggle = not _attack_toggle
    var timer := get_tree().create_timer(0.18)
    timer.timeout.connect(_spawn_spike)

func _spawn_spike() -> void:
    if dead or projectile_scene == null:
        return
    var spike := projectile_scene.instantiate()
    if spike is ShooterProjectile:
        spike.damage = projectile_damage
        spike.gravity = projectile_gravity
        var velocity := Vector2(projectile_speed * _direction, -60.0)
        spike.set_velocity(velocity)
    if spike is Node2D:
        spike.global_position = fire_point.global_position
    add_to_world(spike)

func _on_hit() -> void:
    if dead:
        return
    _active_head.play("hit")

func _on_death() -> void:
    detection_area.monitoring = false
    damage_area.monitoring = false
    fire_timer.stop()
    _active_head.play("death")

func _on_sprite_animation_finished() -> void:
    match _active_head.animation:
        "attack", "attack_alt":
            if not dead:
                _active_head.play("idle")
        "hit":
            if not dead:
                _active_head.play("idle")
        "death":
            queue_free()
