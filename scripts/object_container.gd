extends Node3D
class_name ObjectContainer

signal removed

func _exit_tree():
	removed.emit()
	print("Контейнер: Сигнал removed отправлен для ", name)
