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
	assets_number = objects.size()
	
	var threaders_assets = partition(objects.values(), threaders.size())
	
	#print(partition([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ,21 ,22, 23, 24], 12))
	
	#var current_threader_idx := 0
	#for asset_path: String in objects:
		#var threader := threaders[current_threader_idx]
		#var asset_data = objects[asset_path]
		#
		#var asset := Asset.new(asset_data, assets_folder)
		#threader.add_child(asset)
		#
		#current_threader_idx = (current_threader_idx + 1) % threaders.size()
	#
	for i in range(threaders.size()):
		var threader: Threader = threaders[i]
		var assets_data: Array = threaders_assets[i]
		threader.start.call_deferred(_threader_callable.bind(threader, assets_data, assets_folder))
		await get_tree().create_timer(0.1).timeout
		print("threader %s starting" % i)

func partition(values: Array, amount: int) -> Array[Array]:
	var partitions: Array[Array] = []
	
	var partition_size: int = int(values.size() / amount)
	for i in range(amount-1):
		partitions.append(values.slice(i * partition_size, (i+1) * partition_size))
	
	partitions.append(values.slice((amount-1) * partition_size))
	
	return partitions

func _threader_callable(threader: Threader, assets_data: Array, assets_folder: String):
	var asset_data = assets_data.pop_front()
	if asset_data == null:
		print_debug("All assets of %s have been downloaded" % threader.name)
		threader.finished.emit()
		return
	
	var asset = Asset.new(asset_data, assets_folder)
	threader.download.call_deferred(asset, _threader_callable.bind(threader, assets_data, assets_folder))


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

func get_assets_downloaded() -> int:
	var assets_pending := 0
	for threader: Threader in threaders:
		assets_pending += threader.get_progress()
	return assets_pending

func get_progress() -> int:
	return get_assets_downloaded()

func has_finished() -> bool:
	return get_assets_downloaded() >= assets_number # we never know

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
