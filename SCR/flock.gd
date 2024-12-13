extends Node3D

# Массив рыб
var fishes : Array = []



func _ready():
	# Находим все дочерние объекты типа "Node3D", заменив CSGBox3D
	fishes = get_children()

	
