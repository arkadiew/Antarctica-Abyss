extends MarginContainer
class_name Radar

# Constants
const MIN_ZOOM: float = 0.05
const MAX_ZOOM: float = 1.0
const DEFAULT_SIZE: Vector2 = Vector2(600, 600)
const GRID_SIZE: Vector2 = Vector2(600, 600)
const FADE_ALPHA_MIN: float = 0.3
const FADE_ALPHA_MAX: float = 1.0

# Exported variables
@export var zoom: float = 0.3 : set = _set_zoom
@export var radar_range: float = 50.0
@export var marker_scale_duration: float = 0.3
@export var rotation_enabled: bool = true
@export var marker_scale: float = 0.3
@export var home_marker_scale: float = 0.4
@export var boundary_fade_distance: float = 5.0
@export var update_interval: float = 0.1
@export var invert_x: bool = false
@export var invert_y: bool = false
@export var highlight_duration: float = 1.0  # Highlight duration
@export var highlight_scale: float = 1.5    # Highlight scale

# Node references
@onready var grid: Control = $Grid
@onready var player_marker: Control = $Grid/PlayerMarker
@onready var player = get_node_or_null("/root/main/Player")
@onready var icons: Dictionary = {
	"enemy": $Grid/EnemyMarker,
	"alert": $Grid/AlertMarker,
	"curiosity": $Grid/CuriosityMarker,
	"stone": $Grid/StoneMarker,
	"pipe": $Grid/PipeMarker,
	"home": $Grid/HomeMarker,
	"submarine": $Grid/SubmarineMarker,
	"oxygen": $Grid/oxygenMarker,
	"harpoon": $Grid/harpoonMarker,
	"spanner": $Grid/spannerMarker
}

# Internal variables
var grid_scale: Vector2
var markers: Dictionary = {}
var target_zoom: float = 0.3
var update_timer: float = 0.0
var viewport_size: Vector2

func _ready() -> void:
	# Initialize container and grid
	custom_minimum_size = DEFAULT_SIZE
	if grid:
		grid.size = GRID_SIZE
		grid.pivot_offset = GRID_SIZE / 2
	else:
		push_error("Radar: Grid node not found")
		return

	# Validate critical nodes
	if not is_instance_valid(player):
		push_error("Radar: Player not found")
	if not is_instance_valid(player_marker):
		push_error("Radar: PlayerMarker not found")
	if not _validate_icon_nodes():
		return

	# Center player marker
	player_marker.position = GRID_SIZE / 2
	_update_grid_scale()

	# Hide marker templates
	for marker in icons.values():
		marker.hide()

	# Connect to spawner
	var spawner = get_node_or_null("/root/main/SeaCreatureSpawner")
	if spawner:
		spawner.creatures_spawned.connect(_on_creatures_spawned)
	else:
		push_warning("Radar: Spawner not found")

	# Log no_water_effect_zone nodes for debugging
	var no_water_zones = get_tree().get_nodes_in_group("no_water_effect_zone")
	print("Found ", no_water_zones.size(), " no_water_effect_zone nodes")

	update_radar()

func _validate_icon_nodes() -> bool:
	for key in icons:
		if not is_instance_valid(icons[key]):
			push_error("Radar: Marker '%s' not found" % key)
			return false
	return true

func _process(delta: float) -> void:
	update_timer += delta
	if update_timer >= update_interval:
		update_radar()
		update_timer = 0.0

func _set_zoom(new_zoom: float) -> void:
	target_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
	var tween = create_tween()
	tween.tween_property(self, "zoom", target_zoom, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_update_grid_scale()

func _update_grid_scale() -> void:
	viewport_size = get_viewport_rect().size if get_viewport() else Vector2.ZERO
	if grid and viewport_size != Vector2.ZERO:
		grid_scale = GRID_SIZE / (viewport_size * zoom)
	else:
		push_error("Radar: Failed to compute grid_scale")

func update_radar() -> void:
	if not _is_radar_valid():
		return

	player_marker.position = GRID_SIZE / 2
	var objects = _collect_radar_objects()


	for item in objects:
		if not is_instance_valid(item):
			continue

		var icon_type = _get_icon_type(item)
		if icon_type == "":
			continue

		

		if not markers.has(item):
			_create_marker(item, icon_type)

		_update_marker(item, icon_type)

func _is_radar_valid() -> bool:
	if not is_instance_valid(player) or not grid or not player_marker:
		push_error("Radar: Invalid player, grid, or player marker")
		return false
	return true

func _collect_radar_objects() -> Array:
	var unique_objects: Array = []
	var seen_objects: Dictionary = {}

	var minimap_objects = get_tree().get_nodes_in_group("minimap_objects")
	var no_water_effect_zones = get_tree().get_nodes_in_group("no_water_effect_zone")
	var suit_items = get_tree().get_nodes_in_group("suit_items")

	for item in minimap_objects + no_water_effect_zones + suit_items:
		if is_instance_valid(item) and not seen_objects.has(item):
			unique_objects.append(item)
			seen_objects[item] = true

	return unique_objects

func _get_icon_type(item: Node) -> String:
	if item.is_in_group("no_water_effect_zone"):
		# Only allow the first no_water_effect_zone as "home"
		var no_water_zones = get_tree().get_nodes_in_group("no_water_effect_zone")
		if no_water_zones.size() > 1 and item != no_water_zones[0]:
			return ""
		return "home"
	if item.is_in_group("suit_items"):
		return "submarine"
	if item.has_meta("minimap_icon") and item.get_meta("minimap_icon") in icons:
		return item.get_meta("minimap_icon")
	return ""

func _create_marker(item: Node, icon_type: String) -> void:
	if markers.has(item) and is_instance_valid(markers[item]):
		return

	if icon_type == "home":
		print("Creating home marker for item: ", item, " at position: ", item.global_position)

	var new_marker = icons[icon_type].duplicate()
	grid.add_child(new_marker)
	new_marker.scale = Vector2.ZERO
	new_marker.show()
	markers[item] = new_marker

	var target_scale = Vector2.ONE * (home_marker_scale if icon_type in ["home", "submarine"] else marker_scale)
	var tween = create_tween()
	tween.tween_property(new_marker, "scale", target_scale, marker_scale_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	if not item.tree_exited.is_connected(_on_object_removed.bind(item)):
		item.tree_exited.connect(_on_object_removed.bind(item))

func _update_marker(item: Node, icon_type: String) -> void:
	var relative_pos = _calculate_relative_position(item)
	var half_range = radar_range / 2.0
	var is_out_of_range = abs(relative_pos.x) > half_range or abs(relative_pos.z) > half_range
	var marker = markers[item]

	if is_out_of_range and icon_type != "home":
		marker.hide()
		return
	marker.show()

	var player_rotation = player.global_transform.basis.get_euler().y if rotation_enabled else 0.0
	var rotated_pos = relative_pos.rotated(Vector3.UP, -player_rotation)
	var scaled_pos = Vector2(rotated_pos.x, -rotated_pos.z) * (GRID_SIZE.x / radar_range)

	if invert_x:
		scaled_pos.x = -scaled_pos.x
	if invert_y:
		scaled_pos.y = -scaled_pos.y

	var radar_pos = scaled_pos + GRID_SIZE / 2
	radar_pos = radar_pos.clamp(Vector2.ZERO, GRID_SIZE)

	var distance_to_edge = min(
		min(radar_pos.x, GRID_SIZE.x - radar_pos.x),
		min(radar_pos.y, GRID_SIZE.y - radar_pos.y)
	)
	var fade_factor = clamp(distance_to_edge / boundary_fade_distance, 0.0, 1.0)
	marker.modulate.a = lerp(FADE_ALPHA_MIN, FADE_ALPHA_MAX, fade_factor)

	# Dynamic scaling based on distance
	var distance = relative_pos.length()
	var base_scale = home_marker_scale if icon_type in ["home", "submarine"] else marker_scale
	var dynamic_scale = lerp(base_scale, base_scale * 0.5, distance / radar_range)
	marker.scale = Vector2.ONE * dynamic_scale

	if marker.position.distance_to(radar_pos) > 0.1:
		var tween = create_tween()
		tween.tween_property(marker, "position", radar_pos, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _calculate_relative_position(item: Node) -> Vector3:
	if item.is_in_group("no_water_effect_zone"):
		var center_pos = item.global_position
		if item is Area3D:
			for child in item.get_children():
				if child is CollisionShape3D and child.shape:
					var shape = child.shape
					if shape is BoxShape3D or shape is SphereShape3D:
						center_pos = item.global_position + child.global_position
						break
		return center_pos - player.global_position
	return item.global_position - player.global_position

func _on_object_removed(item: Node) -> void:
	if markers.has(item):
		var marker = markers[item]
		if is_instance_valid(marker):
			var tween = create_tween()
			tween.tween_property(marker, "scale", Vector2.ZERO, marker_scale_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			tween.tween_callback(marker.queue_free)
		markers.erase(item)

func _on_creatures_spawned() -> void:
	update_radar()

func highlight_marker(item: Node) -> void:
	if markers.has(item):
		var marker = markers[item]
		var tween = create_tween()
		tween.tween_property(marker, "scale", Vector2.ONE * highlight_scale, highlight_duration / 2).set_ease(Tween.EASE_OUT)
		tween.tween_property(marker, "scale", Vector2.ONE * marker_scale, highlight_duration / 2).set_ease(Tween.EASE_IN)
		tween.tween_property(marker, "modulate", Color(1, 1, 0), highlight_duration / 2).set_ease(Tween.EASE_OUT)
		tween.tween_property(marker, "modulate", Color(1, 1, 1), highlight_duration / 2).set_ease(Tween.EASE_IN)
