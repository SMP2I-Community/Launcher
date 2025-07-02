extends Node
class_name MinecaftRunner

signal on_run

@export var java: Java
@export var tweaker: MinecraftTweaker

func run():
	java.on_execute.connect(on_run.emit)
	
	var executor := JavaExecutor.new()
	
	var game_args := tweaker.get_game_args()
	game_args.width = Config.x_resolution
	game_args.height = Config.y_resolution
	game_args.username = ProfileManager.get_player_name()
	
	var jvm_args := tweaker.get_jvm_args()
	jvm_args.xmx = "%sG" % Config.max_ram
	
	executor.options.append_array(jvm_args.to_array())
	executor.options.append(tweaker.get_main_class())
	executor.options.append_array(game_args.to_array())
	
	java.execute(executor)
	
	var file = FileAccess.open("user://cmd.sh", FileAccess.WRITE)
	file.store_string("%s %s" % [java.get_executable(), " ".join(executor.as_arguments())])
