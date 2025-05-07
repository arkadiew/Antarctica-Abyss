extends StaticBody3D

@onready var detection_area: Area3D = $Area3D
@onready var button_node: StaticBody3D = $button
@onready var framework = get_node_or_null("/root/main/framework")
@onready var player = get_node_or_null("/root/main/Player")

var item_counters: Dictionary = {
	"Stone": 0,
	"Curiosity": 0
}

var is_button_used: bool = false
var contributor_id: String = "button"

func _ready() -> void:
	item_counters = {
		"Stone": randi_range(3, 8),
		"Curiosity": randi_range(3, 8)
	}
	update_label_text()
	var max_progress = item_counters["Stone"] + item_counters["Curiosity"]
	# Register task with details
	var details = {"items": item_counters.duplicate()}
	TaskManager.register_task("button_task", "Collect Items", max_progress, contributor_id, details)
	
	if button_node and button_node.has_signal("button_state_changed"):
		button_node.connect("button_state_changed", _on_button_state_changed)

func update_label_text(player_items: Dictionary = {}) -> void:
	var stones_collected = player_items.get("Stone", 0)
	var curiosities_collected = player_items.get("Curiosity", 0)
	var stone_status = "✓" if stones_collected >= item_counters["Stone"] else "✗"
	var curiosity_status = "✓" if curiosities_collected >= item_counters["Curiosity"] else "✗"
	
	var label: Label = $SubViewport/Control/Label
	if label:
		label.text = "Stones: %d/%d %s\nCuriosities: %d/%d %s" % [
			stones_collected, item_counters["Stone"], stone_status,
			curiosities_collected, item_counters["Curiosity"], curiosity_status
		]

# Relevant excerpt from button script
func _on_button_state_changed(is_pressed: bool) -> void:
	if not is_pressed:
		return
	
	if is_button_used:
		if player and player.get("AudioManager"):
			player.AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")
		if player:
			player.show_notification("Button already used successfully!")
		return
	
	if not detection_area:
		return
	
	for body in detection_area.get_overlapping_bodies():
		if body and body.has_method("get_item_counters"):
			var player_items: Dictionary = body.get_item_counters()
			update_label_text(player_items)
			
			var has_exact_items = check_exact_items(player_items)
			if has_exact_items:
				if player:
					player.add_money(50)
					player.show_notification("Task completed successfully! Button disabled.")
				if framework and framework.has_method("register_success"):
					framework.register_success()
				is_button_used = true
				TaskManager.update_task_progress("button_task", contributor_id, item_counters["Stone"] + item_counters["Curiosity"])
			else:
				var has_half_items = check_half_items(player_items)
				if has_half_items:
					if player:
						player.add_money(35)
						player.show_notification("Task partially completed! Button disabled.")
					if framework and framework.has_method("register_half_success"):
						framework.register_half_success()
					is_button_used = true
					var progress = item_counters["Stone"] if int(player_items.get("Stone", 0)) >= item_counters["Stone"] else item_counters["Curiosity"]
					TaskManager.update_task_progress("button_task", contributor_id, progress)
				else:
					if player and player.get("AudioManager"):
						player.AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")
					if player:
						player.show_notification("Not enough items collected! Try again.")
					if framework and framework.has_method("register_failure"):
						framework.register_failure()
func check_exact_items(player_items: Dictionary) -> bool:
	if not player_items.has("Stone") or not player_items.has("Curiosity"):
		return false
	return int(player_items["Stone"]) >= item_counters["Stone"] and int(player_items["Curiosity"]) >= item_counters["Curiosity"]

func check_half_items(player_items: Dictionary) -> bool:
	if not player_items.has("Stone") or not player_items.has("Curiosity"):
		return false
	var stones_match = int(player_items["Stone"]) >= item_counters["Stone"]
	var curiosities_match = int(player_items["Curiosity"]) >= item_counters["Curiosity"]
	return (stones_match and not curiosities_match) or (curiosities_match and not stones_match)
