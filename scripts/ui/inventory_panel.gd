extends Control
class_name InventoryPanel
## UI层 - 背包界面

@onready var item_grid: GridContainer = $ItemGrid
@onready var item_info: PanelContainer = $ItemInfo
@onready var equip_slots: HBoxContainer = $EquipSlots

var is_open: bool = false

func _ready() -> void:
	visible = false
	EventBus.inventory_changed.connect(_on_inventory_changed)

func open() -> void:
	is_open = true
	visible = true
	_update_item_grid()
	EventBus.emit_ui_panel_opened("inventory")

func close() -> void:
	is_open = false
	visible = false
	EventBus.emit_ui_panel_closed("inventory")

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func _update_item_grid() -> void:
	for child in item_grid.get_children():
		child.queue_free()
	
	var inv_comp: InventoryComponent = InventoryComponent.new()
	var items: Array = inv_comp.get_all_items()
	
	for item_dict in items:
		var item_btn: Button = Button.new()
		item_btn.text = item_dict.get("item_id", "")
		item_btn.custom_minimum_size = Vector2(64, 64)
		item_grid.add_child(item_btn)

func _on_inventory_changed() -> void:
	if is_open:
		_update_item_grid()
