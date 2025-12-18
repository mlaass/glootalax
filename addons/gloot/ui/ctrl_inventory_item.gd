@tool
@icon("res://addons/gloot/images/icon_ctrl_inventory_item.svg")
class_name CtrlInventoryItem
extends CtrlInventoryItemBase
## Control node for displaying inventory items.
##
## Displays an [ItemStack] icon and its stack size. Consists of a [TextureRect] (the icon) and a [Label] (the stack
## size). If the item has sockets, socket slot overlays are displayed automatically.

const _Utils = preload("res://addons/gloot/core/utils.gd")
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

var _texture_rect: TextureRect
var _stack_size_label: Label
var _old_item: ItemStack = null
var _socket_container: Control = null
var _socket_slots: Dictionary = {}  # slot_id -> CtrlSocketSlot
var _connected_socket_defs: Array[SocketSlotDefinition] = []  # Track connected definitions


func _connect_item_signals(new_item: ItemStack) -> void:
	if !is_instance_valid(new_item):
		return
	_Utils.safe_connect(new_item.property_changed, _on_item_property_changed)


func _disconnect_item_signals(old_item: ItemStack) -> void:
	if !is_instance_valid(old_item):
		return
	_Utils.safe_disconnect(old_item.property_changed, _on_item_property_changed)


func _on_item_property_changed(_property: String) -> void:
	_refresh()


func _get_item_position() -> Vector2:
	if is_instance_valid(item) && item.get_inventory():
		return item.get_inventory().get_item_position(item)
	return Vector2(0, 0)


func _ready() -> void:
	item_changed.connect(_on_item_changed)
	icon_stretch_mode_changed.connect(_on_icon_stretch_mode_changed)

	_texture_rect = TextureRect.new()
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = icon_stretch_mode

	_stack_size_label = Label.new()
	_stack_size_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack_size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stack_size_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	_socket_container = Control.new()
	_socket_container.name = "SocketContainer"
	_socket_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_texture_rect)
	add_child(_stack_size_label)
	add_child(_socket_container)

	resized.connect(func():
		_texture_rect.size = size
		_stack_size_label.size = size
		if is_instance_valid(_socket_container):
			_socket_container.size = size
		_layout_sockets()
	)

	_refresh()


func _on_item_changed() -> void:
	_disconnect_item_signals(_old_item)
	_old_item = item
	_connect_item_signals(item)
	_refresh()


func _on_icon_stretch_mode_changed() -> void:
	if is_instance_valid(_texture_rect):
		_texture_rect.stretch_mode = icon_stretch_mode


func _update_texture() -> void:
	if !is_instance_valid(_texture_rect):
		return

	if is_instance_valid(item):
		_texture_rect.texture = item.get_texture()
	else:
		_texture_rect.texture = null
		return

	if is_instance_valid(item) && GridConstraint.is_item_rotated(item):
		_texture_rect.size = Vector2(size.y, size.x)
		if GridConstraint.is_item_rotation_positive(item):
			_texture_rect.position = Vector2(_texture_rect.size.y, 0)
			_texture_rect.rotation = PI / 2
		else:
			_texture_rect.position = Vector2(0, _texture_rect.size.x)
			_texture_rect.rotation = -PI / 2

	else:
		_texture_rect.size = size
		_texture_rect.position = Vector2.ZERO
		_texture_rect.rotation = 0


func _update_stack_size() -> void:
	if !is_instance_valid(_stack_size_label):
		return
	if !is_instance_valid(item):
		_stack_size_label.text = ""
		return
	var stack_size: int = item.get_stack_size()
	if stack_size <= 1:
		_stack_size_label.text = ""
	else:
		_stack_size_label.text = "%d" % stack_size
	_stack_size_label.size = size


func _refresh() -> void:
	_update_texture()
	_update_stack_size()
	_refresh_sockets()


#region Socket Support

func _get_texture_scale() -> Vector2:
	## Returns the scale factor from original texture size to current control size.
	## Used to scale socket visual overrides proportionally.
	if not is_instance_valid(item):
		return Vector2.ONE
	var texture = item.get_texture()
	if texture == null:
		return Vector2.ONE
	var original_size = texture.get_size()
	if original_size.x <= 0 or original_size.y <= 0:
		return Vector2.ONE
	return size / original_size


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

	# Apply size (per-slot override scaled, or default)
	var scale := _get_texture_scale()
	var slot_size := socket_def.size_override * scale if socket_def.size_override != Vector2.ZERO else socket_size
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

	# Get scale factor for socket visual overrides (relative to original texture size)
	var scale := _get_texture_scale()

	# Get socket definitions for per-slot configuration
	var socket_defs: Array[SocketSlotDefinition] = []
	if is_instance_valid(item) and item.has_sockets():
		socket_defs = item.get_socket_slots()

	# Build a map of slot_id -> socket_def for easy lookup
	var def_map: Dictionary = {}
	for socket_def in socket_defs:
		def_map[socket_def.id] = socket_def

	# Calculate total width considering per-slot size overrides (scaled)
	var total_width: float = 0.0
	var slot_count := _socket_slots.size()
	var idx := 0
	for slot_id in _socket_slots:
		var socket_def: SocketSlotDefinition = def_map.get(slot_id)
		var slot_size := socket_size
		if socket_def != null and socket_def.size_override != Vector2.ZERO:
			slot_size = socket_def.size_override * scale
		total_width += slot_size.x
		if idx < slot_count - 1:
			total_width += socket_spacing
		idx += 1

	# Calculate base position based on corner
	var base_pos := _get_corner_base_position(total_width, scale)

	# Layout sockets in a row from the base position
	var x := base_pos.x
	for slot_id in _socket_slots:
		var socket_slot: Control = _socket_slots[slot_id]
		if not is_instance_valid(socket_slot):
			continue

		var socket_def: SocketSlotDefinition = def_map.get(slot_id)
		var slot_size := socket_size
		if socket_def != null and socket_def.size_override != Vector2.ZERO:
			slot_size = socket_def.size_override * scale

		# Determine position: absolute (custom) or auto-layout
		var slot_pos: Vector2
		if socket_def != null and socket_def.use_custom_position:
			# Absolute position relative to item (scaled)
			slot_pos = socket_def.position * scale
		else:
			# Auto-layout position
			slot_pos = Vector2(x, base_pos.y)
			x += slot_size.x + socket_spacing

		socket_slot.position = slot_pos
		socket_slot.size = slot_size


func _get_corner_base_position(total_width: float, scale: Vector2 = Vector2.ONE) -> Vector2:
	## Returns the starting position for socket layout based on the selected corner.
	var max_slot_height := socket_size.y
	# Check for any per-slot size overrides to get max height (scaled)
	if is_instance_valid(item) and item.has_sockets():
		for socket_def in item.get_socket_slots():
			if socket_def.size_override != Vector2.ZERO:
				max_slot_height = max(max_slot_height, socket_def.size_override.y * scale.y)

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

#endregion
