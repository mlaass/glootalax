@tool
extends Control
class_name CtrlSocketSlot
## Visual representation of a single socket slot that can receive items via drag-and-drop.
##
## This control displays a socket slot and handles drop interactions. It validates drops
## using the parent item's can_socket_item() method and emits signals for the parent
## to handle the actual socketing logic.

const _Utils = preload("res://addons/gloot/core/utils.gd")

signal drop_requested(slot_id: String, dropped_item: ItemStack) ## Emitted when a valid item is dropped on this socket.
signal clicked(slot_id: String, mouse_button: int) ## Emitted when this socket is clicked.
signal hovered(slot_id: String) ## Emitted when the mouse enters this socket.
signal unhovered(slot_id: String) ## Emitted when the mouse exits this socket.

## The ID of this socket slot (matches SocketSlotDefinition.id).
var slot_id: String = ""

## The parent item that owns this socket.
var parent_item: ItemStack = null:
	set(value):
		_disconnect_parent_signals()
		parent_item = value
		_connect_parent_signals()
		_refresh()

## The socket slot definition resource.
var socket_definition: SocketSlotDefinition = null

## Style applied when socket is empty.
@export var empty_style: StyleBox = null:
	set(value):
		empty_style = value
		_refresh_style()

## Style applied when socket contains an item.
@export var filled_style: StyleBox = null:
	set(value):
		filled_style = value
		_refresh_style()

## Style applied when a valid item is being dragged over this socket.
@export var valid_drop_style: StyleBox = null:
	set(value):
		valid_drop_style = value
		_refresh_style()

var _background_panel: Panel = null
var _socketed_item_texture: TextureRect = null
var _is_valid_drop_target: bool = false


func _ready() -> void:
	# Create background panel
	_background_panel = Panel.new()
	_background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background_panel)

	# Create socketed item texture
	_socketed_item_texture = TextureRect.new()
	_socketed_item_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_socketed_item_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_socketed_item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_socketed_item_texture)

	resized.connect(_on_resized)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_on_resized()
	_refresh()


func _on_resized() -> void:
	if is_instance_valid(_background_panel):
		_background_panel.size = size
	if is_instance_valid(_socketed_item_texture):
		_socketed_item_texture.size = size


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not data is ItemStack:
		_update_drop_highlight(false)
		return false

	if not is_instance_valid(parent_item):
		_update_drop_highlight(false)
		return false

	var can_socket := parent_item.can_socket_item(slot_id, data as ItemStack)
	_update_drop_highlight(can_socket)
	return can_socket


func _drop_data(_at_position: Vector2, data) -> void:
	if data is ItemStack:
		drop_requested.emit(slot_id, data as ItemStack)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			clicked.emit(slot_id, mb.button_index)


func _update_drop_highlight(valid: bool) -> void:
	_is_valid_drop_target = valid
	_refresh_style()


func _refresh() -> void:
	_refresh_style()
	_refresh_socketed_item()


func _refresh_style() -> void:
	if not is_instance_valid(_background_panel):
		return

	# Style priority: drop highlight > filled > empty
	var style: StyleBox = null
	if _is_valid_drop_target and valid_drop_style != null:
		style = valid_drop_style
	elif _get_socketed_item() != null and filled_style != null:
		style = filled_style
	else:
		style = empty_style

	_set_panel_style(style)


func _refresh_socketed_item() -> void:
	if not is_instance_valid(_socketed_item_texture):
		return

	var socketed := _get_socketed_item()
	if socketed != null:
		_socketed_item_texture.texture = socketed.get_texture()
	else:
		_socketed_item_texture.texture = null


func _get_socketed_item() -> ItemStack:
	if not is_instance_valid(parent_item):
		return null
	return parent_item.get_socketed_item(slot_id)


func _connect_parent_signals() -> void:
	if not is_instance_valid(parent_item):
		return
	_Utils.safe_connect(parent_item.socket_changed, _on_socket_changed)


func _disconnect_parent_signals() -> void:
	if not is_instance_valid(parent_item):
		return
	_Utils.safe_disconnect(parent_item.socket_changed, _on_socket_changed)


func _on_socket_changed(changed_slot_id: String) -> void:
	if changed_slot_id == slot_id:
		_refresh()


func _on_mouse_entered() -> void:
	hovered.emit(slot_id)


func _on_mouse_exited() -> void:
	_is_valid_drop_target = false
	_refresh_style()
	unhovered.emit(slot_id)


func _set_panel_style(style: StyleBox) -> void:
	if not is_instance_valid(_background_panel):
		return
	_background_panel.remove_theme_stylebox_override("panel")
	if style != null:
		_background_panel.add_theme_stylebox_override("panel", style)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_is_valid_drop_target = false
		_refresh_style()
