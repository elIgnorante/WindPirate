extends CanvasLayer

@onready var animation = $AnimationPlayer

signal faded_in
signal faded_out

func fade_out():
	animation.play("fade_out")
	
func fade_in():
	animation.play("falde_in")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"falde_in":
			faded_in.emit()
		"fade_out":
			faded_out.emit()
