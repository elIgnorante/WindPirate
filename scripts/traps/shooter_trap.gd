extends StaticBody2D
class_name ShooterTrap

@export var max_health := 4
@export var contact_damage := 1
@export var contact_cooldown := 0.6

var health := 0
var dead := false
var _damaged_bodies := {}

func _ready() -> void:
    health = max_health

func take_damage(amount: int, _source_position: Vector2, _direction_override := 0) -> void:
    if dead:
        return
    health = max(0, health - amount)
    _on_hit()
    if health <= 0:
        _die()

func reset_contact(body: Node) -> void:
    _damaged_bodies.erase(body)

func apply_contact_damage(body: Node) -> void:
    if dead:
        return
    if body == null:
        return
    if not (body is Player):
        return
    if body in _damaged_bodies:
        return
    body.take_damage(contact_damage, global_position)
    _damaged_bodies[body] = true
    if contact_cooldown > 0.0:
        var timer := get_tree().create_timer(contact_cooldown)
        var weak_body := weakref(body)
        timer.timeout.connect(func():
            var target := weak_body.get_ref()
            if target:
                _damaged_bodies.erase(target))

func _die() -> void:
    dead = true
    _on_death()

func _on_hit() -> void:
    pass

func _on_death() -> void:
    pass

func add_to_world(node: Node) -> void:
    var world := get_tree().current_scene
    if world:
        world.add_child(node)
    else:
        get_tree().root.add_child(node)
