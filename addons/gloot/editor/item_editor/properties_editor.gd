@tool
extends Window

const _Undoables = preload("res://addons/gloot/editor/undoables.gd")
const _DictEditor = preload("res://addons/gloot/editor/common/dict_editor.tscn")
const _EditorIcons = preload("res://addons/gloot/editor/common/editor_icons.gd")
const _COLOR_OVERRIDDEN = Color.GREEN
const _COLOR_INVALID = Color.RED

@onready var _margin_container: MarginContainer = $"MarginContainer"
@onready var _tab_container: TabContainer = %TabContainer
@onready var _dict_editor: Control = $"MarginContainer/VBoxContainer/TabContainer/Properties/DictEditor"
@onready var _sockets_tab: VBoxContainer = %SocketsContent
@onready var _texture_preview: TextureRect = %TexturePreview
@onready var _item_name_label: Label = %ItemName
@onready var _item_type_label: Label = %ItemType
@onready var _item_stack_label: Label = %ItemStack

var item: ItemStack = null:
	set(new_item):
		if new_item == null:
			return
		item = new_item
		_refresh()


func _ready() -> void:
	about_to_popup.connect(func(): _refresh())
	close_requested.connect(func(): hide())
	_dict_editor.value_changed.connect(func(key: String, new_value): _on_value_changed(key, new_value))
	_dict_editor.value_removed.connect(func(key: String): _on_value_removed(key))
	hide()


func _on_value_changed(key: String, new_value) -> void:
	_Undoables.undoable_action(item, "Set Item Property", func():
		if key == "stack_size":
			return item.set_stack_size(new_value)
		else:
			item.set_property(key, new_value)
			return true
	)
	# TODO: Figure out why this is needed
	_refresh.call_deferred()


func _on_value_removed(key: String) -> void:
	_Undoables.undoable_action(item, "Clear Item Property", func():
		if key == "stack_size":
			return item.set_stack_size(1)
		else:
			item.clear_property(key)
			return true
	)
	_refresh()


func _refresh() -> void:
	_refresh_header()
	_refresh_properties()

	# Show/hide sockets tab based on whether item has sockets
	var has_sockets = item != null and item.has_sockets()
	var sockets_tab_idx = _tab_container.get_tab_idx_from_control(_sockets_tab)
	if sockets_tab_idx >= 0:
		_tab_container.set_tab_hidden(sockets_tab_idx, not has_sockets)

	if has_sockets:
		_refresh_sockets()


func _refresh_header() -> void:
	if item == null:
		_texture_preview.texture = null
		_item_name_label.text = "No Item"
		_item_type_label.text = ""
		_item_stack_label.text = ""
		return

	_texture_preview.texture = item.get_texture()
	_item_name_label.text = item.get_title()

	if item.item_type != null:
		_item_type_label.text = "Type: %s" % item.item_type.id
	else:
		_item_type_label.text = "Type: (none)"

	var stack_size = item.get_stack_size()
	var max_stack = 1
	if item.item_type != null:
		max_stack = item.item_type.max_stack_size
	if max_stack > 1:
		_item_stack_label.text = "Stack: %d / %d" % [stack_size, max_stack]
		_item_stack_label.visible = true
	else:
		_item_stack_label.visible = false


func _refresh_properties() -> void:
	if _dict_editor.btn_add:
		_dict_editor.btn_add.icon = _EditorIcons.get_icon("Add")
	_dict_editor.dictionary = _get_dictionary()
	_dict_editor.color_map = _get_color_map()
	_dict_editor.remove_button_map = _get_remove_button_map()
	# Make ItemType properties readonly - they should be edited in the .tres file
	_dict_editor.immutable_keys = ["id", "name", "texture", "max_stack_size", "weight", "size"] as Array[String]
	_dict_editor.refresh()


func _refresh_sockets() -> void:
	# Clear existing socket entries
	for child in _sockets_tab.get_children():
		child.queue_free()

	if item == null or not item.has_sockets():
		return

	var socket_slots = item.get_socket_slots()
	for socket_def in socket_slots:
		var socket_entry = _create_socket_entry(socket_def)
		_sockets_tab.add_child(socket_entry)


func _create_socket_entry(socket_def: SocketSlotDefinition) -> Control:
	var panel = PanelContainer.new()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Socket header with name and ID
	var header_label = Label.new()
	header_label.text = "%s (%s)" % [socket_def.display_name, socket_def.id]
	header_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(header_label)

	# Constraints info
	if socket_def.constraints.size() > 0:
		var constraints_label = Label.new()
		var constraint_texts: Array[String] = []
		for constraint in socket_def.constraints:
			if constraint != null:
				constraint_texts.append(_get_constraint_description(constraint))
		constraints_label.text = "Constraints: %s" % ", ".join(constraint_texts)
		constraints_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		constraints_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(constraints_label)

	# Visual override info
	if socket_def.use_custom_position or socket_def.size_override != Vector2.ZERO:
		var visual_label = Label.new()
		var visual_parts: Array[String] = []
		if socket_def.use_custom_position:
			visual_parts.append("Position: (%d, %d)" % [socket_def.position.x, socket_def.position.y])
		if socket_def.size_override != Vector2.ZERO:
			visual_parts.append("Size: %dx%d" % [socket_def.size_override.x, socket_def.size_override.y])
		visual_label.text = ", ".join(visual_parts)
		visual_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		visual_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(visual_label)

	# Socketed item display
	var item_hbox = HBoxContainer.new()
	item_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(item_hbox)

	var socketed_item = item.get_socketed_item(socket_def.id)

	# Item texture
	var item_texture = TextureRect.new()
	item_texture.custom_minimum_size = Vector2(32, 32)
	item_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if socketed_item != null:
		item_texture.texture = socketed_item.get_texture()
	item_hbox.add_child(item_texture)

	# Item name or empty state
	var item_name_label = Label.new()
	item_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if socketed_item != null:
		item_name_label.text = socketed_item.get_title()
	else:
		item_name_label.text = "(empty)"
		item_name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	item_hbox.add_child(item_name_label)

	# Action button
	var action_btn = Button.new()
	if socketed_item != null:
		action_btn.icon = _EditorIcons.get_icon("Remove")
		action_btn.tooltip_text = "Remove socketed item"
		action_btn.pressed.connect(func(): _on_unsocket_item(socket_def.id))
	else:
		action_btn.text = "Select..."
		action_btn.tooltip_text = "Select an item to socket"
		action_btn.pressed.connect(func(): _on_select_socket_item(socket_def))
	item_hbox.add_child(action_btn)

	# Enable drag-drop on the panel
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("socket_def", socket_def)
	panel.gui_input.connect(func(event): _on_socket_panel_input(event, panel, socket_def))

	return panel


func _get_constraint_description(constraint: InventoryConstraint) -> String:
	# Try to get a readable description of the constraint
	if constraint.has_method("get_description"):
		return constraint.get_description()

	# Check for PropertyMatchConstraint
	if "required_properties" in constraint:
		var props = constraint.required_properties
		if props is Dictionary and props.size() > 0:
			var parts: Array[String] = []
			for key in props:
				parts.append("%s=%s" % [key, props[key]])
			return ", ".join(parts)

	return constraint.get_class()


func _on_unsocket_item(slot_id: String) -> void:
	_Undoables.undoable_action(item, "Unsocket Item", func():
		var removed = item.unsocket_item(slot_id)
		return removed != null
	)
	_refresh()


func _on_select_socket_item(socket_def: SocketSlotDefinition) -> void:
	# Open file dialog to select an ItemType
	var dialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.add_filter("*.tres", "Item Types")
	dialog.title = "Select Item to Socket"

	dialog.file_selected.connect(func(path: String):
		_socket_item_from_path(socket_def, path)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _socket_item_from_path(socket_def: SocketSlotDefinition, path: String) -> void:
	var resource = load(path)
	if resource == null:
		push_error("Failed to load resource: %s" % path)
		return

	if not resource is ItemType:
		push_error("Selected resource is not an ItemType: %s" % path)
		return

	var item_type = resource as ItemType

	# Create a new ItemStack from the ItemType
	var new_item = ItemStack.new()
	new_item.item_type = item_type

	# Check if it can be socketed
	if not socket_def.can_accept_item(new_item):
		push_error("Item '%s' does not meet socket constraints" % item_type.name)
		return

	_Undoables.undoable_action(item, "Socket Item", func():
		return item.socket_item(socket_def.id, new_item)
	)
	_refresh()


func _on_socket_panel_input(event: InputEvent, panel: Control, socket_def: SocketSlotDefinition) -> void:
	# Handle drag-drop
	pass


func _can_drop_data(_at_position: Vector2, data) -> bool:
	# Check if data is a file path to an ItemType
	if data is Dictionary and data.has("files"):
		for file_path in data["files"]:
			if file_path.ends_with(".tres") or file_path.ends_with(".res"):
				return true
	return false


func _drop_data(_at_position: Vector2, data) -> void:
	# This would need to determine which socket slot was dropped on
	# For now, we'll handle this in the socket panel input
	pass


func _get_dictionary() -> Dictionary:
	if item == null:
		return {}

	var result: Dictionary = {}

	# Get properties from item_type first
	if item.item_type != null:
		for key in item.item_type.get_property_names():
			result[key] = item.get_property(key)

	# Add stack_size for stackable items (it's a per-ItemStack property, not an ItemType property)
	if item.item_type != null and item.item_type.max_stack_size > 1:
		result["stack_size"] = item.get_stack_size()

	# Add overridden properties
	for key in item.get_overridden_properties():
		result[key] = item.get_property(key)

	return result


func _get_color_map() -> Dictionary:
	if item == null:
		return {}

	var result: Dictionary = {}
	var dictionary: Dictionary = _get_dictionary()
	for key in dictionary.keys():
		if key == "stack_size":
			# stack_size is "overridden" if it's different from 1
			if item.get_stack_size() != 1:
				result[key] = _COLOR_OVERRIDDEN
		elif item.is_property_overridden(key):
			result[key] = _COLOR_OVERRIDDEN

	return result


func _get_remove_button_map() -> Dictionary:
	if item == null:
		return {}

	var result: Dictionary = {}
	var dictionary: Dictionary = _get_dictionary()
	for key in dictionary.keys():
		result[key] = {}
		if key == "stack_size":
			# stack_size reset button
			result[key]["text"] = ""
			result[key]["icon"] = _EditorIcons.get_icon("Reload")
			result[key]["disabled"] = item.get_stack_size() == 1
		elif item.has_property(key):
			result[key]["text"] = ""
			result[key]["icon"] = _EditorIcons.get_icon("Reload")
			result[key]["disabled"] = not item.is_property_overridden(key)
		else:
			result[key]["text"] = ""
			result[key]["icon"] = _EditorIcons.get_icon("Remove")
			result[key]["disabled"] = not item.is_property_overridden(key)
	return result
