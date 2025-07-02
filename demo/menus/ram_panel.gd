extends PanelContainer

@onready var ram_slider: VSlider = $RamSlider
@onready var rotating_label: RotatingLabel = %RotatingLabel

func _ready() -> void:
	ram_slider.scrollable = false
	var real_total_memory = OS.get_memory_info()["physical"] / (2**30)
	var cool_number = pow(2, ceil(log(real_total_memory)/log(2)))
	ram_slider.max_value = int(cool_number)
	ram_slider.value = Config.max_ram

func _process(delta: float) -> void:
	rotating_label.args[0] = int(ram_slider.value)


func _on_ram_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Config.max_ram = ram_slider.value
