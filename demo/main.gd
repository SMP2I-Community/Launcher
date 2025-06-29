extends Control

const CURSEFORGE_KEY_PATH := "res://addons/curseforge/curseforge_api.key"

const MINECRAFT_UUID = "https://api.mojang.com/users/profiles/minecraft/%s"
const MINECRAFT_PROFILE = "https://sessionserver.mojang.com/session/minecraft/profile/%s"

const UNKOWN_SKIN = preload("res://demo/assets/textures/skins/unkown.png")

var player_mat: StandardMaterial3D = preload("res://demo/assets/materials/player_godot.tres")
var cape_mat: StandardMaterial3D = preload("res://demo/assets/materials/cape.tres")

@onready var skin_file_dialog: FileDialog = $SkinFileDialog
@onready var cape_selector_window: Window = $CapesSelectorWindow

@onready var player_name_line_edit: LineEdit = %PlayerNameLineEdit
@onready var player_name_animation_player: AnimationPlayer = %PlayerNameAnimationPlayer

@onready var skin_download_timer: Timer = $SkinDownloadTimer
@onready var requests: Requests = $Requests

@onready var player_viewport_container: SubViewportContainer = %PlayerViewportContainer

@onready var play_button: Button = %PlayButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var quit_timer: Timer = $QuitTimer

@onready var minecraft: Node = $Minecraft

func _ready() -> void:
	_init_curseforge_api()
	
	player_name_line_edit.text = ProfileManager.get_player_name()
	progress_bar.hide()
	progress_bar.show()
	
	minecraft.install()
	
	#mc_installation.on_run.connect(quit_timer.start)

func _init_curseforge_api():
	var file = FileAccess.open(CURSEFORGE_KEY_PATH, FileAccess.READ)
	CurseforgeAPI.init(file.get_line())

func _on_button_pressed() -> void:
	skin_file_dialog.popup_centered()

func _on_play_button_pressed() -> void:
	if player_name_line_edit.text.is_empty():
		player_name_animation_player.play("Flash")
		return
	progress_bar.show()
	play_button.disabled = true
	
	#mc_installation.run(ProfileManager.get_player_name())


func _process(delta: float) -> void:
	progress_bar.value = minecraft.get_progress()


func _on_player_name_line_edit_text_changed(new_text: String) -> void:
	ProfileManager.set_player_name(new_text)


func _on_player_viewport_container_change_cape_request() -> void:
	cape_selector_window.ask_popup_centered()


func _on_capes_selector_window_cape_selected(path: String) -> void:
	ProfileManager.set_cape(path)

func _on_capes_selector_window_close() -> void:
	player_viewport_container.player.can_animate = true # spagetti code go brrr


func _on_skin_file_dialog_file_selected(path: String) -> void:
	ProfileManager.set_skin(path)


func _on_quit_timer_timeout() -> void:
	get_tree().quit()


func _on_java_finished(output: Array) -> void:
	print(output)
