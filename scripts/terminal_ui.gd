extends Control
class_name TerminalUI

@export var current_airport: AirportConfig

# order list
@onready var vbox_orders_list: VBoxContainer = $MarginContainer/VBoxContainer/HSplitContainer/OrderListPanel/ScrollContainer/VBoxOrdersList
@onready var order_list_panel: Control = $MarginContainer/VBoxContainer/HSplitContainer/OrderListPanel
@onready var details_panel: Control = $MarginContainer/VBoxContainer/HSplitContainer/OrderDetailsPanel

# Details
@onready var lbl_name: Label = $MarginContainer/VBoxContainer/HSplitContainer/OrderDetailsPanel/VBoxDetails/LabelOrderName
@onready var lbl_dest: Label = $MarginContainer/VBoxContainer/HSplitContainer/OrderDetailsPanel/VBoxDetails/LabelDestination
@onready var btn_accept: Button = $MarginContainer/VBoxContainer/HSplitContainer/OrderDetailsPanel/VBoxDetails/BtnAcceptOrder
@onready var btn_deliver: Button = $MarginContainer/VBoxContainer/HSplitContainer/OrderDetailsPanel/VBoxDetails/BtnDeliverOrder
@onready var btn_orders: Button = $MarginContainer/VBoxContainer/BtnOrders
@onready var btn_close: Button = $MarginContainer/VBoxContainer/BtnClose

var selected_order: OrderConfig = null

func _ready() -> void:
	order_list_panel.hide()
	order_list_panel.custom_minimum_size = Vector2(300.0, 200.0)
	details_panel.hide()
	btn_orders.disabled = false
	btn_orders.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_accept.pressed.connect(_on_accept_pressed)
	btn_deliver.pressed.connect(_on_deliver_pressed)
	btn_orders.pressed.connect(_on_orders_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	_populate_order_list()
	_update_delivery_button()

func setup_terminal(airport: AirportConfig) -> void:
	current_airport = airport
	_populate_order_list()
	_update_delivery_button()
	if btn_deliver.visible:
		_show_delivery_details()

func _update_delivery_button() -> void:
	btn_deliver.visible = MissionManager.can_complete_order_at(current_airport)

func _show_delivery_details() -> void:
	var active_order: OrderConfig = MissionManager.current_order
	if active_order == null:
		return

	order_list_panel.hide()
	details_panel.show()
	lbl_name.text = active_order.title
	lbl_dest.text = active_order.destination
	btn_accept.hide()

func _populate_order_list() -> void:
	for child in vbox_orders_list.get_children():
		child.queue_free()
	if current_airport == null:
		print("[!] current airport is null")
		return

	for order in current_airport.available_orders:
		var btn = Button.new()
		btn.text = order.title
		btn.pressed.connect(_on_order_selected.bind(order))
		vbox_orders_list.add_child(btn)

func _on_order_selected(order: OrderConfig) -> void:
	selected_order = order
	details_panel.show()
	btn_accept.show()
	btn_deliver.hide()

	lbl_name.text = order.title
	lbl_dest.text = order.destination
	
	btn_accept.disabled = MissionManager.has_active_order()

func _on_orders_pressed() -> void:
	_populate_order_list()
	order_list_panel.show()
	order_list_panel.custom_minimum_size = Vector2(300.0, 200.0)
	details_panel.hide()
	selected_order = null
	btn_orders.text = "ORDERS (OPEN)"

func _on_accept_pressed() -> void:
	if selected_order and not MissionManager.has_active_order():
		MissionManager.accept_order(selected_order)
		queue_free()

func _on_close_pressed() -> void:
	queue_free()

func _on_deliver_pressed() -> void:
	if MissionManager.complete_order_at(current_airport):
		queue_free()

	
