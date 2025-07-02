extends Artifact
class_name Native

##TODO: complete this file (useless for higher minecraft versions)

func get_jar_path() -> String:
	return data.get("path").get_file()
