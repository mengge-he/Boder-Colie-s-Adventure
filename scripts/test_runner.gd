extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_check_file_exists("project.godot")
	_check_file_exists("scenes/main.tscn")
	_check_project_has_main_scene()
	_finish()

func _check_file_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing file: %s" % path)

func _check_project_has_main_scene() -> void:
	var config := ConfigFile.new()
	var err := config.load("project.godot")
	if err != OK:
		failures.append("Cannot load project.godot")
		return
	var main_scene := str(config.get_value("application", "run/main_scene", ""))
	if main_scene != "res://scenes/main.tscn":
		failures.append("Expected main scene res://scenes/main.tscn, got %s" % main_scene)

func _finish() -> void:
	if failures.is_empty():
		print("TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
