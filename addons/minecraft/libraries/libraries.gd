extends Progressor
class_name Libraries

@export var libraries_folder := "user://libraries"
@export var natives_folder := "user://natives"

var libraries_number: int = 0

var libraries: Array[Library] = []

@onready var artifact_threader: Threader = $ArtifactThreader
@onready var natives_threader: Threader = $NativesThreader

func install(libraries_list: Array):
	libraries_number = libraries_list.size()
	
	for library_data in libraries_list:
		var lib = Library.new(library_data, libraries_folder, natives_folder)
		libraries.append(lib)
	
	install_libraries()
	install_natives()

func install_libraries():
	for lib: Library in libraries:
		var artifact: Artifact = lib.as_artifact()
		if artifact == null:
			continue
		
		artifact_threader.add_child(artifact)
	
	var artifacts: Array = artifact_threader.get_children()
	artifact_threader.start(_download_artifacts.bind(artifact_threader, artifacts))

func install_natives():
	for lib: Library in libraries:
		#print(lib.as_native())
		pass

func _download_artifacts(threader: Threader, artifacts: Array):
	_artifact_callback(threader, null, artifacts)

func _artifact_callback(threader: Threader, artifact: Artifact, artifacts: Array):
	if artifact != null:
		threader.remove_child.call_deferred(artifact)
		artifact.queue_free.call_deferred()
	
	var next_artifact: Artifact = artifacts.pop_front()
	if next_artifact == null:
		print_debug("All artifacts of %s have been downloaded" % threader.name)
		threader.finished.emit()
		return
	
	next_artifact.download.call_deferred(_artifact_callback.bind(threader, next_artifact, artifacts))
