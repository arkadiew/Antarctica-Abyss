extends Node3D
@export var item_name: String = "Item"
@export var cost: float = 0.0

@onready var label = $SubViewport/Control/Label  # Reference to the Label node
# Array of items stored within the script
var items = [
	{"item_name": "Spanner", "cost": 35.0},
	{"item_name": "Gun", "cost": 50.0},
	{"item_name": "Oxygen Tank", "cost": 15.0}
]

func _ready():
	# Form the text for the Label
	var display_text = "=== List of Items ===\n"
	for item in items:
		display_text += "%s\n" % item["item_name"]
		display_text += "Price: $%.2f\n" % item["cost"]
		display_text += "---------------\n"
	
	# Set the text in the Label
	label.text = display_text
