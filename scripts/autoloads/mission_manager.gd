extends Node

signal order_started(order)
signal order_completed(order)
signal order_abandoned()

var current_order: OrderConfig = null

func has_active_order() -> bool:
    return current_order != null

func accept_order(order: OrderConfig) -> void:
    if has_active_order():
        print("[!] An order is already active.")
        return
    current_order = order
    order_started.emit(current_order)

func can_complete_order_at(airport: AirportConfig) -> bool:
    return has_active_order() \
        and airport != null \
        and current_order.destination == airport.code

func complete_order_at(airport: AirportConfig) -> bool:
    if not can_complete_order_at(airport):
        return false

    var finished_order := current_order
    current_order = null
    order_completed.emit(finished_order)
    print("[!] Order completed. Reward: ", finished_order.reward)
    return true

func completed_order() -> void:
    if not has_active_order():
        return 
    
    var finished_order = current_order
    current_order = null

    order_completed.emit(finished_order)

func abandoned_order() -> void:
    if not has_active_order():
        return

    current_order = null
    order_abandoned.emit()
