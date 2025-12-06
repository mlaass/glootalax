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

## Corner positions for socket layout.
enum SocketCorner { BOTTOM_RIGHT, BOTTOM_LEFT, TOP_RIGHT, TOP_LEFT }

@export_group("Socket Layout", "socket_")
## Corner where sockets are positioned.
@export var socket_corner: SocketCorner = SocketCorner.BOTTOM_RIGHT:
	set(value):
		socket_corner = value
		_layout_sockets()

## Default scene for socket slots (null = use built-in CtrlSocketSlot).
## Custom scenes should extend CtrlSocketSlot or implement compatible interface.
@export var socket_scene: PackedScene = null:
	set(value):
		socket_scene = value
		_refresh_sockets()

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
var _connected_socket_defs: Array[SocketSlotDefinition] = []  # Track connected definitions


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
	# Determine which scene to use: per-slot override > default scene > built-in
	var socket_slot: Control
	if socket_def.custom_scene != null:
		socket_slot = socket_def.custom_scene.instantiate()
	elif socket_scene != null:
		socket_slot = socket_scene.instantiate()
	else:
		socket_slot = _CtrlSocketSlot.new()

	# Configure the socket slot
	socket_slot.slot_id = socket_def.id
	socket_slot.socket_definition = socket_def
	socket_slot.parent_item = item
	socket_slot.mouse_filter = Control.MOUSE_FILTER_STOP

	# Apply size (per-slot override or default)
	var slot_size := socket_def.size_override if socket_def.size_override != Vector2.ZERO else socket_size
	socket_slot.size = slot_size

	# Apply styles if socket supports them
	if socket_slot.has_method("set") or "empty_style" in socket_slot:
		socket_slot.empty_style = socket_empty_style
		socket_slot.filled_style = socket_filled_style
		socket_slot.valid_drop_style = socket_valid_drop_style

	# Connect signals
	socket_slot.drop_requested.connect(_on_socket_drop_requested)
	socket_slot.clicked.connect(_on_socket_clicked)
	socket_slot.hovered.connect(_on_socket_hovered)
	socket_slot.unhovered.connect(_on_socket_unhovered)

	# Connect to socket definition changes for editor preview
	if not socket_def.changed.is_connected(_on_socket_def_changed):
		socket_def.changed.connect(_on_socket_def_changed)
		_connected_socket_defs.append(socket_def)

	_socket_container.add_child(socket_slot)
	_socket_slots[socket_def.id] = socket_slot


func _clear_sockets() -> void:
	# Disconnect from socket definition signals
	for socket_def in _connected_socket_defs:
		if is_instance_valid(socket_def) and socket_def.changed.is_connected(_on_socket_def_changed):
			socket_def.changed.disconnect(_on_socket_def_changed)
	_connected_socket_defs.clear()

	for socket_slot in _socket_slots.values():
		if is_instance_valid(socket_slot):
			socket_slot.queue_free()
	_socket_slots.clear()


func _on_socket_def_changed() -> void:
	# Refresh sockets when any socket definition changes (for editor preview)
	_refresh_sockets()


func _layout_sockets() -> void:
	if _socket_slots.is_empty():
		return

	# Get socket definitions for per-slot configuration
	var socket_defs: Array[SocketSlotDefinition] = []
	if is_instance_valid(item) and item.has_sockets():
		socket_defs = item.get_socket_slots()

	# Build a map of slot_id -> socket_def for easy lookup
	var def_map: Dictionary = {}
	for socket_def in socket_defs:
		def_map[socket_def.id] = socket_def

	# Calculate total width considering per-slot size overrides
	var total_width: float = 0.0
	var slot_count := _socket_slots.size()
	var idx := 0
	for slot_id in _socket_slots:
		var socket_def: SocketSlotDefinition = def_map.get(slot_id)
		var slot_size := socket_size
		if socket_def != null and socket_def.size_override != Vector2.ZERO:
			slot_size = socket_def.size_override
		total_width += slot_size.x
		if idx < slot_count - 1:
			total_width += socket_spacing
		idx += 1

	# Calculate base position based on corner
	var base_pos := _get_corner_base_position(total_width)

	# Layout sockets in a row from the base position
	var x := base_pos.x
	for slot_id in _socket_slots:
		var socket_slot: Control = _socket_slots[slot_id]
		if not is_instance_valid(socket_slot):
			continue

		var socket_def: SocketSlotDefinition = def_map.get(slot_id)
		var slot_size := socket_size
		if socket_def != null and socket_def.size_override != Vector2.ZERO:
			slot_size = socket_def.size_override

		# Base position for this slot
		var slot_pos := Vector2(x, base_pos.y)

		# Apply per-slot position offset
		if socket_def != null and socket_def.position_offset != Vector2.ZERO:
			slot_pos += socket_def.position_offset

		socket_slot.position = slot_pos
		socket_slot.size = slot_size
		x += slot_size.x + socket_spacing


func _get_corner_base_position(total_width: float) -> Vector2:
	## Returns the starting position for socket layout based on the selected corner.
	var max_slot_height := socket_size.y
	# Check for any per-slot size overrides to get max height
	if is_instance_valid(item) and item.has_sockets():
		for socket_def in item.get_socket_slots():
			if socket_def.size_override != Vector2.ZERO:
				max_slot_height = max(max_slot_height, socket_def.size_override.y)

	match socket_corner:
		SocketCorner.BOTTOM_RIGHT:
			return Vector2(size.x - socket_margin - total_width, size.y - socket_margin - max_slot_height)
		SocketCorner.BOTTOM_LEFT:
			return Vector2(socket_margin, size.y - socket_margin - max_slot_height)
		SocketCorner.TOP_RIGHT:
			return Vector2(size.x - socket_margin - total_width, socket_margin)
		SocketCorner.TOP_LEFT:
			return Vector2(socket_margin, socket_margin)
		_:
			return Vector2(size.x - socket_margin - total_width, size.y - socket_margin - max_slot_height)


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
