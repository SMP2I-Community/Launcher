extends CanvasLayer

const IN_ANIMATION: StringName  = "in"
const OUT_ANIMATION: StringName = "out"

const ICON_SHOWUP_TIME_MS: float = 2000

@onready var screen_animation_player: AnimationPlayer = $ScreenAnimationPlayer

@onready var control: Control = $Control
@onready var icon_rect: TextureRect = %IconRect

var icon_loop_tween: Tween
var icon_showup_tween: Tween

var _start_time: int

func _ready() -> void:
	hide()
	SceneLoader.load_requested.connect(_on_load_requested)
	SceneLoader.load_finished.connect(_on_load_finished)
	SceneLoader.load_progressed.connect(_on_load_progress)
	
	_setup_icon_loop_tween()


func show_screen() -> void:
	icon_rect.modulate.a = 0.0
	control.modulate.a = 0.0
	screen_animation_player.play(IN_ANIMATION)
	show()


func start_load() -> void:
	_start_time = Time.get_ticks_msec()
	SceneLoader.begin_load()


func hide_screen() -> void:
	screen_animation_player.play(OUT_ANIMATION)


func _on_load_requested() -> void:
	show_screen()


func _on_load_finished() -> void:
	kill_showup_tween()
	SceneLoader.switch()
	hide_screen()


func _on_load_progress(progress: float) -> void:
	var showup_tween_off: bool = icon_showup_tween == null or not icon_showup_tween.is_running()
	var load_time: int = Time.get_ticks_msec() - _start_time
	if showup_tween_off and load_time > ICON_SHOWUP_TIME_MS and progress < 0.5:
		_setup_icon_showup_tween()


func _setup_icon_loop_tween() -> void:
	icon_loop_tween = get_tree().create_tween()
	icon_loop_tween.tween_property(icon_rect, "rotation_degrees", 180, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC).set_delay(0.9)
	icon_loop_tween.tween_property(icon_rect, "rotation_degrees", 360, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC).set_delay(0.9)
	icon_loop_tween.tween_callback(func(): icon_rect.rotation = 0)
	icon_loop_tween.set_loops()

func kill_showup_tween() -> void:
	if icon_showup_tween:
		icon_showup_tween.kill()
		icon_showup_tween = null

func _setup_icon_showup_tween() -> void:
	kill_showup_tween()
	icon_showup_tween = get_tree().create_tween()
	icon_showup_tween.tween_property(icon_rect, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
