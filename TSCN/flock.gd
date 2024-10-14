extends Node3D

# Массив рыб
var fishes : Array = []

func _ready():
	# Находим все дочерние объекты типа "Fish"
	fishes = get_children()
