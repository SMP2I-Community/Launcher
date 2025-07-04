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
	if Utils.get_os_type() == Utils.OS_TYPE.WINDOWS:
		executor.options.append_array([
			"-XX:HeapDumpPath=MojangTricksIntelDriversForPerformance_javaw.exe_minecraft.exe.heapdump",
			"-XX:+UnlockExperimentalVMOptions",
			"-XX:+UseG1GC",
			"-XX:G1NewSizePercent=20",
			"-XX:G1ReservePercent=20",
			"-XX:MaxGCPauseMillis=50",
			"-XX:G1HeapRegionSize=32M"
		])
	
	executor.options.append(tweaker.get_main_class())
	executor.options.append_array(game_args.to_array())
	
	java.execute_in("user://", executor)
