@tool
extends Control

const _Undoables = preload("res://addons/gloot/editor/undoables.gd")
const _EditorIcons = preload("res://addons/gloot/editor/common/editor_icons.gd")
const _PropertiesEditor = preload("res://addons/gloot/editor/item_editor/properties_editor.tscn")
const _POPUP_SIZE = Vector2i(800, 300)

var inventory: Inventory:
	set(new_inventory):
		if inventory == new_inventory:
			return
		disconnect_inventory_signals()
		inventory = new_inventory
		connect_inventory_signals()

		_refresh()
var _inventory_control: Control
var _inventory_container: Control
var _properties_editor: Window
var _selected_item: ItemStack = null


func connect_inventory_signals():
	if !inventory:
		return

	inventory.constraint_changed.connect(_on_constraint_changed)
	inventory.constraint_added.connect(_on_constraint_changed)
	inventory.constraint_removed.connect(_on_constraint_changed)
	inventory.item_added.connect(_on_item_manipulated)
	inventory.item_removed.connect(_on_item_manipulated)


func disconnect_inventory_signals():
	if !inventory:
		return

	inventory.constraint_changed.disconnect(_on_constraint_changed)
	inventory.constraint_added.disconnect(_on_constraint_changed)
	inventory.constraint_removed.disconnect(_on_constraint_changed)
	inventory.item_added.disconnect(_on_item_manipulated)
	inventory.item_removed.disconnect(_on_item_manipulated)


func _on_constraint_changed(constraint: InventoryConstraint) -> void:
	_refresh()


func _on_item_manipulated(item: ItemStack) -> void:
	_refresh()


func _refresh() -> void:
	if !is_inside_tree() || inventory == null:
		return

	# Remove the inventory control, if present
	if _inventory_container:
		%ScrollContainer.remove_child(_inventory_container)
		_inventory_container.queue_free()
		_inventory_container = null

	# Create the appropriate inventory control and populate it
	_inventory_container = _create_inventory_container()
	%ScrollContainer.add_child(_inventory_container)


func _create_inventory_container() -> Control:
	var vbox_container: Control = VBoxContainer.new()
	vbox_container.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox_container.size_flags_vertical = SIZE_EXPAND_FILL
	var capacity_control: CtrlInventoryCapacity = null

	if inventory.get_constraint(GridConstraint) != null:
		_inventory_control = CtrlInventoryGrid.new()
	else:
		_inventory_control = CtrlInventory.new()
	if _inventory_control is CtrlInventory:
		_inventory_control.select_mode = ItemList.SelectMode.SELECT_MULTI
	_inventory_control.size_flags_horizontal = SIZE_EXPAND_FILL
	_inventory_control.size_flags_vertical = SIZE_EXPAND_FILL
	_inventory_control.inventory = inventory
	_inventory_control.inventory_item_activated.connect(_on_inventory_item_activated)
	_inventory_control.inventory_item_clicked.connect(_on_inventory_item_clicked)
	if _inventory_control is CtrlInventoryGrid:
		_inventory_control.inventory_item_selected.connect(_on_item_selected)
	else:
		_inventory_control.item_selected.connect(_on_item_selected)
	_inventory_control.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)

	if inventory.get_constraint(WeightConstraint) != null:
		capacity_control = CtrlInventoryCapacity.new()
		capacity_control.inventory = inventory

	if _inventory_control:
		vbox_container.add_child(_inventory_control)
	if capacity_control:
		vbox_container.add_child(capacity_control)

	return vbox_container


func _on_inventory_item_activated(item: ItemStack) -> void:
	_Undoables.undoable_action(inventory, "Remove Inventory Item", func():
		return inventory.remove_item(item)
	)


func _on_inventory_item_clicked(item: ItemStack, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	_Undoables.undoable_action(inventory, "Rotate Inventory Item", func():
		var grid_constraint: GridConstraint = inventory.get_constraint(GridConstraint)
		if grid_constraint == null:
			return false
		var rotated = grid_constraint.is_item_rotated(item)
		return grid_constraint.set_item_rotation(item, !rotated)
	)


func _ready() -> void:
	%BtnEdit.icon = _EditorIcons.get_icon("Edit")
	%BtnRemove.icon = _EditorIcons.get_icon("Remove")
	%BtnClear.icon = _EditorIcons.get_icon("Clear")

	%BtnEdit.pressed.connect(_on_btn_edit)
	%BtnRemove.pressed.connect(_on_btn_remove)
	%BtnClear.pressed.connect(_on_btn_clear)
	_refresh()
	_update_selection_display()


func _on_item_selected(item: ItemStack) -> void:
	_selected_item = item
	_update_selection_display()


func _update_selection_display() -> void:
	if _selected_item == null or not is_instance_valid(_selected_item):
		%SelectionTexture.texture = null
		%SelectionName.text = "No item selected"
		%SelectionType.text = ""
		%BtnEdit.disabled = true
		return

	%SelectionTexture.texture = _selected_item.get_texture()
	%SelectionName.text = _selected_item.get_title()
	if _selected_item.item_type != null:
		%SelectionType.text = "Type: %s" % _selected_item.item_type.id
		if _selected_item.has_sockets():
			var socket_count = _selected_item.get_socket_slots().size()
			%SelectionType.text += " | %d socket(s)" % socket_count
	else:
		%SelectionType.text = ""
	%BtnEdit.disabled = false


func _on_btn_edit() -> void:
	var selected_item: ItemStack = _inventory_control.get_selected_inventory_item()
	if selected_item == null:
		return
	if _properties_editor == null:
		_properties_editor = _PropertiesEditor.instantiate()
		add_child(_properties_editor)
	_properties_editor.item = selected_item
	_properties_editor.popup_centered(_POPUP_SIZE)


func _on_btn_remove() -> void:
	var selected_items: Array[ItemStack] = _inventory_control.get_selected_inventory_items()
	_Undoables.undoable_action(inventory, "Remove Inventory Item", func():
		for selected_item in selected_items:
			inventory.remove_item(selected_item)
		return true
	)


func _on_btn_clear() -> void:
	_Undoables.undoable_action(inventory, "Clear Inventory", func():
		inventory.clear()
		return true
	)


static func _select_node(node: Node) -> void:
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(node)
	EditorInterface.edit_node(node)


func _can_drop_data(at_position: Vector2, data) -> bool:
	if data is Dictionary and data.has("type") and data["type"] == "files":
		for file_path in data["files"]:
			if file_path.ends_with(".tres") or file_path.ends_with(".res"):
				var res = load(file_path)
				if res is ItemType:
					return true
	return false


func _drop_data(at_position: Vector2, data) -> void:
	if data is Dictionary and data.has("type") and data["type"] == "files":
		for file_path in data["files"]:
			if file_path.ends_with(".tres") or file_path.ends_with(".res"):
				var res = load(file_path)
				if res is ItemType:
					_Undoables.undoable_action(inventory, "Add Inventory Item", func():
						return (inventory.create_and_add_item(res) != null)
					)
