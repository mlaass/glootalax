@tool
extends Control

signal activated
signal clicked(at_position: Vector2, mouse_button_index: int)
signal socket_drop_requested(slot_id: String, dropped_item: ItemStack) ## Forwarded from CtrlInventoryItemWithSockets.
signal socket_clicked(slot_id: String, mouse_button: int) ## Forwarded from CtrlInventoryItemWithSockets.

var item: ItemStack:
	set(new_item):
		if item == new_item:
			return

		item = new_item
		if is_instance_valid(_ctrl_inventory_item):
			_ctrl_inventory_item.item = item
var icon_stretch_mode: TextureRect.StretchMode = TextureRect.StretchMode.STRETCH_SCALE:
	set(new_stretch_mode):
		if icon_stretch_mode == new_stretch_mode:
			return
		icon_stretch_mode = new_stretch_mode
		if is_instance_valid(_ctrl_inventory_item):
			_ctrl_inventory_item.icon_stretch_mode = icon_stretch_mode
var drag_tint := Color.WHITE
var ctrl_inventory_item_scene: PackedScene = null
var _ctrl_inventory_item: CtrlInventoryItemBase
var _initial_modulate := Color.WHITE
static var _grab_offset: Vector2


func _ready() -> void:
	_initial_modulate = modulate
	if ctrl_inventory_item_scene == null:
		_ctrl_inventory_item = CtrlInventoryItem.new()
	else:
		_ctrl_inventory_item = ctrl_inventory_item_scene.instantiate()
	_ctrl_inventory_item.name = "CtrlInventoryItemBase"
	_ctrl_inventory_item.size = size
	_ctrl_inventory_item.item = item
	_ctrl_inventory_item.icon_stretch_mode = icon_stretch_mode
	_ctrl_inventory_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_ctrl_inventory_item)

	resized.connect(func():
		_ctrl_inventory_item.size = size
	)

	# Forward socket signals if the item control supports them
	if _ctrl_inventory_item.has_signal("socket_drop_requested"):
		_ctrl_inventory_item.socket_drop_requested.connect(
			func(slot_id, gem): socket_drop_requested.emit(slot_id, gem)
		)
	if _ctrl_inventory_item.has_signal("socket_clicked"):
		_ctrl_inventory_item.socket_clicked.connect(
			func(slot_id, btn): socket_clicked.emit(slot_id, btn)
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var drag_data = get_viewport().gui_get_drag_data()
		if drag_data is ItemStack and drag_data == item:
			modulate = drag_tint
	elif what == NOTIFICATION_DRAG_END:
		modulate = _initial_modulate


func _get_drag_data(at_position: Vector2) -> Variant:
	if item == null:
		return null

	_grab_offset = at_position * get_global_transform().get_scale()

	var sub_preview: Control = null
	sub_preview = _create_preview()
	if sub_preview == null:
		return null
	var preview = Control.new()
	sub_preview.position = -_grab_offset
	preview.add_child(sub_preview)
	set_drag_preview(preview)

	return item


static func get_grab_offset_local_to(control: Control) -> Vector2:
	return _grab_offset / control.get_global_transform().get_scale()


func _create_preview() -> Control:
	var preview: CtrlInventoryItemBase
	if ctrl_inventory_item_scene == null:
		preview = CtrlInventoryItem.new()
	else:
		preview = ctrl_inventory_item_scene.instantiate()
	preview.item = item
	preview.size = size
	preview.icon_stretch_mode = icon_stretch_mode
	return preview


func _gui_input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return

	var mb_event: InputEventMouseButton = event
	if !mb_event.pressed:
		return
	if mb_event.button_index == MOUSE_BUTTON_LEFT:
		if mb_event.double_click:
			activated.emit()
	clicked.emit(mb_event.position, mb_event.button_index)
