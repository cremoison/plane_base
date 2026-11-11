@tool
extends Resource
class_name AeroSurfaceConfig

@export var chord: float = 1.0:
    set(v):
        chord = v
        emit_changed()
@export var span: float = 1.0:
    set(v):
        span = v
        emit_changed()
@export var flap_fraction: float = 0.2:
    set(v):
        flap_fraction = v
        emit_changed()


@export var lift_slope: float = 6.28 
@export var skin_friction: float = 0.02 
@export var zero_lift_aoa: float = 0.0 
@export var stall_angle_high: float = deg_to_rad(15.0) 
@export var stall_angle_low: float = deg_to_rad(-15.0) 

var aspect_ratio: float:
    get: return span / chord if chord != 0 else 0.0

var area: float:
    get: return span * chord