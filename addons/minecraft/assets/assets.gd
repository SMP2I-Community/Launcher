extends Progressor
class_name Assets

signal installed

const RESOURCES_URL = "https://resources.download.minecraft.net/"

@export var assets_folder := "user://assets"
@export var max_threads := 4

var threaders: Array[Threader] = []
var threaders_finished_list: Array[bool] = []

var requester: Requests

var assets_number: int = 0

func _ready() -> void:
	_init_requester()
	_init_threaders()

func _init_requester():
	requester = Requests.new()
	add_child(requester)

func _init_threaders():
	var nb_of_cores := OS.get_processor_count()
	# -1 Core to not use 100% of the computor
	var nb_of_cores_used := clamp((nb_of_cores-1) / 2, 1, max_threads)
	
	for i in range(nb_of_cores_used):
		var threader := Threader.new()
		threader.name = "Threader %s" % i
		threader.finished.connect(_on_threader_finished.bind(i))
		
		threaders.append(threader)
		threaders_finished_list.append(false)
		add_child(threader)

func _on_threader_finished(threader_idx: int):
	threaders_finished_list[threader_idx] = true
	if not threaders_finished_list.has(false):
		installed.emit()

func install(asset_index: AssetIndex):
	var objects = await get_assets_list(asset_index)
	#assets_number = len(objects)
	assets_number = 0
	
	var current_threader_idx := 0
	for asset_path: String in objects:
		var threader := threaders[current_threader_idx]
		var asset_data = objects[asset_path]
		
		var asset := Asset.new(asset_data, assets_folder)
		threader.add_child.call_deferred(asset)
		assets_number += 1
		
		current_threader_idx = (current_threader_idx + 1) % threaders.size()
		if current_threader_idx == 0:
			await get_tree().create_timer(0.001).timeout
	
	for threader: Threader in threaders:
		var threader_assets = threader.get_children()
		threader.start(_threader_callable.bind(threader, threader_assets))

func _threader_callable(threader: Threader, assets: Array):
	_asset_callback(threader, null, assets)

func _asset_callback(threader: Threader, asset: Asset, assets: Array):
	if asset != null:
		threader.remove_child.call_deferred(asset)
		asset.queue_free.call_deferred()
		
	var next_asset: Asset = assets.pop_front()
	if next_asset == null:
		print_debug("All assets of %s have been downloaded" % threader.name)
		threader.finished.emit()
		return
	
	next_asset.download.call_deferred(_asset_callback.bind(threader, next_asset, assets))

func get_assets_pending_count() -> int:
	var assets_pending := 0
	for threader: Threader in threaders:
		assets_pending += threader.get_progress()
	return assets_pending

func get_progress() -> int:
	return assets_number - get_assets_pending_count()

func has_finished() -> bool:
	return get_assets_pending_count() == 0

func get_assets_list(asset_index: AssetIndex) -> Dictionary:
	var asset_index_path = assets_folder.path_join("indexes/%s.json" % asset_index.get_id())
	await requester.do_file(asset_index.get_url(), asset_index_path, asset_index.get_sha1())
	
	var asset_index_file = FileAccess.open(asset_index_path, FileAccess.READ)
	if asset_index_file == null or asset_index_file.get_error() != OK:
		push_error("Error opening file %s" % asset_index_file)
		return {}
	
	var content: Dictionary = JSON.parse_string(asset_index_file.get_as_text())
	var objects: Dictionary = content.get("objects", {})
	
	return objects
