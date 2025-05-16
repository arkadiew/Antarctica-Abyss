extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on__pressd1() -> void:
	OS.shell_open("https://github.com/ArtjomZadera")


func _on__pressed2() -> void:
	OS.shell_open("https://github.com/arkadiew")
	

func _on__pressed3() -> void:
	OS.shell_open("https://github.com/AlekseiSut")
