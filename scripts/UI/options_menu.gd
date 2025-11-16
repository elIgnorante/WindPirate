extends CanvasLayer

@onready var selection_items = [
        $Panel/VBoxContainer/MusicRow,
        $Panel/VBoxContainer/SFXRow,
        $Panel/VBoxContainer/FullscreenRow,
        $Panel/VBoxContainer/BackLabel
]
@onready var music_value = $Panel/VBoxContainer/MusicRow/Value
@onready var sfx_value = $Panel/VBoxContainer/SFXRow/Value
@onready var fullscreen_value = $Panel/VBoxContainer/FullscreenRow/Value

var selection_index := 0
var return_to_pause := false
var music_bus := AudioServer.get_bus_index("Music")
var sfx_bus := AudioServer.get_bus_index("SFX")
var music_percent := 100
var sfx_percent := 60
var fullscreen := false

func _ready():
        hide()
        set_process_input(false)
        _load_settings()

func open(from_pause: bool):
        return_to_pause = from_pause
        show()
        selection_index = 0
        _highlight_selection()
        set_process_input(true)
        _update_labels()

func close():
        hide()
        set_process_input(false)
        Game.main.on_options_closed(return_to_pause)

func _input(event):
        if event.is_action_pressed("ui_down"):
                selection_index = clamp(selection_index + 1, 0, selection_items.size() - 1)
                _highlight_selection()
        elif event.is_action_pressed("ui_up"):
                selection_index = clamp(selection_index - 1, 0, selection_items.size() - 1)
                _highlight_selection()
        elif event.is_action_pressed("ui_left"):
                _adjust_current(-5)
        elif event.is_action_pressed("ui_right"):
                _adjust_current(5)
        elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
                if selection_index == selection_items.size() - 1 or event.is_action_pressed("ui_cancel"):
                        close()

func _adjust_current(delta):
        match selection_index:
                0:
                        music_percent = clamp(music_percent + delta, 0, 100)
                        AudioServer.set_bus_volume_db(music_bus, _percent_to_db(music_percent))
                1:
                        sfx_percent = clamp(sfx_percent + delta, 0, 100)
                        AudioServer.set_bus_volume_db(sfx_bus, _percent_to_db(sfx_percent))
                2:
                        if delta != 0:
                                fullscreen = not fullscreen
                                if fullscreen:
                                        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
                                else:
                                        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        _update_labels()

func _highlight_selection():
        for i in range(selection_items.size()):
                var item = selection_items[i]
                item.modulate.a = 1.0 if i == selection_index else 0.4

func _update_labels():
        music_value.text = "%d%%" % music_percent
        sfx_value.text = "%d%%" % sfx_percent
        fullscreen_value.text = "on" if fullscreen else "off"

func _load_settings():
        music_percent = _db_to_percent(AudioServer.get_bus_volume_db(music_bus))
        sfx_percent = _db_to_percent(AudioServer.get_bus_volume_db(sfx_bus))
        fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
        _update_labels()

func _percent_to_db(value):
        return lerpf(-40.0, 0.0, float(value) / 100.0)

func _db_to_percent(db):
        return int(round(remap(db, -40.0, 0.0, 0.0, 100.0)))
