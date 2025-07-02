extends Progressor
class_name Threader

signal finished

var thread: Thread

func start(thread_callable: Callable):
	thread = Thread.new()
	thread.start(thread_callable)

func get_progress():
	return get_child_count()

func _exit_tree() -> void:
	if thread != null:
		thread.wait_to_finish()
