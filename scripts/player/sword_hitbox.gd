extends Area2D

@export var damage := 1
@export var active_time := 0.25
@onready var shape := $CollisionShape2D
@onready var timer := $ActiveTimer
var owner_body
var enabled := false

func _ready():
        monitoring = false
        shape.disabled = true
        owner_body = get_parent()
        connect("body_entered", Callable(self, "_on_body_entered"))
        timer.timeout.connect(_on_active_timer_timeout)

func activate():
        if enabled:
                return
        enabled = true
        monitoring = true
        shape.disabled = false
        timer.start(active_time)

func deactivate():
        enabled = false
        monitoring = false
        shape.disabled = true

func _on_body_entered(body):
        if body == owner_body:
                return
        if body.has_method("take_damage"):
                var direction = sign(body.global_position.x - owner_body.global_position.x)
                body.take_damage(damage, owner_body.global_position, direction)

func _on_active_timer_timeout() -> void:
        deactivate()
