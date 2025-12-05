@tool
@icon("res://addons/gloot/images/icon_ctrl_inventory_item.svg")
class_name CtrlInventoryItemWithSockets
extends CtrlInventoryItem
## Inventory item control with socket slot overlays.
##
## Extends [CtrlInventoryItem] to display socket slots as visual overlays on the item.
## Socket slots can receive items via drag-and-drop. Emits signals for socket interactions
## that can be handled by parent controls.

const _CtrlSocketSlot = preload("res://addons/gloot/ui/ctrl_socket_slot.gd")

signal socket_drop_requested(slot_id: String, dropped_item: ItemStack) ## Emitted when an item is dropped on a socket.
signal socket_clicked(slot_id: String, mouse_button: int) ## Emitted when a socket is clicked.
signal socket_hovered(slot_id: String) ## Emitted when the mouse enters a socket.
signal socket_unhovered(slot_id: String) ## Emitted when the mouse exits a socket.

@export_group("Socket Display", "socket_")
## Size of each socket slot in pixels.
@export var socket_size: Vector2 = Vector2(16, 16):
	set(value):
		socket_size = value
		_layout_sockets()

## Margin from edge of item for socket placement.
@export var socket_margin: float = 2.0:
	set(value):
		socket_margin = value
		_layout_sockets()

## Spacing between sockets.
@export var socket_spacing: float = 2.0:
	set(value):
		socket_spacing = value
		_layout_sockets()

@export_group("Socket Styles", "socket_")
## Style applied when socket is empty.
@export var socket_empty_style: StyleBox = null:
	set(value):
		socket_empty_style = value
		_apply_socket_styles()

## Style applied when socket contains an item.
@export var socket_filled_style: StyleBox = null:
	set(value):
		socket_filled_style = value
		_apply_socket_styles()

## Style applied when a valid item is being dragged over a socket.
@export var socket_valid_drop_style: StyleBox = null:
	set(value):
		socket_valid_drop_style = value
		_apply_socket_styles()

var _socket_container: Control = null
var _socket_slots: Dictionary = {}  # slot_id -> CtrlSocketSlot


func _ready() -> void:
	super._ready()

	_socket_container = Control.new()
	_socket_container.name = "SocketContainer"
	_socket_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_socket_container)

	item_changed.connect(_on_item_changed_sockets)
	resized.connect(_on_resized_sockets)

	_refresh_sockets()


func _on_item_changed_sockets() -> void:
	_refresh_sockets()


func _on_resized_sockets() -> void:
	if is_instance_valid(_socket_container):
		_socket_container.size = size
	_layout_sockets()


func _refresh_sockets() -> void:
	_clear_sockets()

	if not is_instance_valid(item):
		return

	if not item.has_sockets():
		return

	var socket_defs := item.get_socket_slots()
	for socket_def in socket_defs:
		_create_socket_slot(socket_def)

	_layout_sockets()


func _create_socket_slot(socket_def: SocketSlotDefinition) -> void:
	var socket_slot := _CtrlSocketSlot.new()
	socket_slot.slot_id = socket_def.id
	socket_slot.socket_definition = socket_def
	socket_slot.parent_item = item
	socket_slot.size = socket_size
	socket_slot.mouse_filter = Control.MOUSE_FILTER_STOP

	# Apply styles
	socket_slot.empty_style = socket_empty_style
	socket_slot.filled_style = socket_filled_style
	socket_slot.valid_drop_style = socket_valid_drop_style

	# Connect signals
	socket_slot.drop_requested.connect(_on_socket_drop_requested)
	socket_slot.clicked.connect(_on_socket_clicked)
	socket_slot.hovered.connect(_on_socket_hovered)
	socket_slot.unhovered.connect(_on_socket_unhovered)

	_socket_container.add_child(socket_slot)
	_socket_slots[socket_def.id] = socket_slot


func _clear_sockets() -> void:
	for socket_slot in _socket_slots.values():
		if is_instance_valid(socket_slot):
			socket_slot.queue_free()
	_socket_slots.clear()


func _layout_sockets() -> void:
	if _socket_slots.is_empty():
		return

	# Layout sockets in a row at the bottom-right corner
	var slot_count := _socket_slots.size()
	var total_width := slot_count * socket_size.x + (slot_count - 1) * socket_spacing
	var start_x := size.x - socket_margin - total_width
	var y := size.y - socket_margin - socket_size.y

	var x := start_x
	for slot_id in _socket_slots:
		var socket_slot: Control = _socket_slots[slot_id]
		if is_instance_valid(socket_slot):
			socket_slot.position = Vector2(x, y)
			socket_slot.size = socket_size
			x += socket_size.x + socket_spacing


func _apply_socket_styles() -> void:
	for socket_slot in _socket_slots.values():
		if is_instance_valid(socket_slot):
			socket_slot.empty_style = socket_empty_style
			socket_slot.filled_style = socket_filled_style
			socket_slot.valid_drop_style = socket_valid_drop_style


func _on_socket_drop_requested(slot_id: String, dropped_item: ItemStack) -> void:
	socket_drop_requested.emit(slot_id, dropped_item)


func _on_socket_clicked(slot_id: String, mouse_button: int) -> void:
	socket_clicked.emit(slot_id, mouse_button)


func _on_socket_hovered(slot_id: String) -> void:
	socket_hovered.emit(slot_id)


func _on_socket_unhovered(slot_id: String) -> void:
	socket_unhovered.emit(slot_id)
