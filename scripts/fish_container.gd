extends Node3D

signal removed

func _ready():
	# Если объект удаляется из сцены, отправляем сигнал
	tree_exiting.connect(_on_tree_exiting)

func _on_tree_exiting():
	emit_signal("removed")
