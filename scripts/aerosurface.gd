@tool
extends Node3D
class_name AeroSurface

@export var config : AeroSurfaceConfig:
    set(value):
        if config and config.is_connected("changed", _on_config_changed):
            config.disconnect("changed", _on_config_changed)

        config = value


        if config:
            config.connect("changed", _on_config_changed)
            
        _update_gizmo()


@export var is_control_surface : bool = false:
    set(v): 
        is_control_surface = v
        _update_gizmo()


@export var input_multiplier : float = 1.0
var _gizmo_mesh_instance : MeshInstance3D

var flap_angle : float = 0.0

func _ready():
    if Engine.is_editor_hint():
        _setup_gizmo()
        _update_gizmo()
    else: 
        if _gizmo_mesh_instance:
            _gizmo_mesh_instance.queue_free()

# calculate aerodynamic forces (lift, drag ...)
func calculate_forces(world_velocity: Vector3, air_density : float) -> Dictionary:
    if not config: return {"force" : Vector3.ZERO, "position" : global_position}
    
    var local_velocity = global_transform.basis.inverse() * world_velocity
    var air_flow = -local_velocity

    var flow_yz = Vector2(air_flow.z, air_flow.y)
    var dynamic_pressure = 0.5 * air_density * flow_yz.length_squared()

    if dynamic_pressure < 0.01:
        return {"force" : Vector3.ZERO, "position" : global_position}

    var aoa = atan2(flow_yz.y, flow_yz.x)

    var coeffs = calculate_coefficients(aoa)
    var cl = coeffs.x
    var cd = coeffs.y

    # forces
    var lift_mag = cl * dynamic_pressure * config.area
    var drag_mag = cd * dynamic_pressure * config.area

    # flow direction and lift direction
    var flow_dir_local = air_flow.normalized()
    var lift_dir_local = Vector3(0, flow_dir_local.z, -flow_dir_local.y).normalized()

    var local_force = (lift_dir_local * lift_mag) + (flow_dir_local * drag_mag)

    var global_force = global_transform.basis * local_force

    return {
        "force" : global_force,
        "position" : global_position
    }


func calculate_coefficients(aoa : float) -> Vector2:
    
    var effective_aoa = aoa + (flap_angle * config.flap_fraction)

    var cl = 0
    var cd = 0

    if effective_aoa >= config.stall_angle_low and effective_aoa <= config.stall_angle_high:
        cl = config.lift_slope * (effective_aoa - config.zero_lift_aoa)
        var induced_cd = (cl * cl) / (PI * 0.8 * config.aspect_ratio) # 0.8 = Oswald efficiency factor
        cd = config.skin_friction + induced_cd
    else:
        # stall
        # var max_cl = config.lift_slope * (config.stall_angle_high - config.zero_lift_aoa)
        # var post_stall_cl = 2.0 * sin(effective_aoa) * cos(effective_aoa)
        
        cl = 2.0 * sin(effective_aoa) * cos(effective_aoa)
        cd = 2.0 * pow(sin(effective_aoa), 2) + config.skin_friction

    return Vector2(cl,cd)

func set_flap_angle(angle_deg : float) -> void:
    flap_angle = deg_to_rad(angle_deg * input_multiplier)

# gizmo logic
func _setup_gizmo():
    if not _gizmo_mesh_instance:
        _gizmo_mesh_instance = MeshInstance3D.new()
        add_child(_gizmo_mesh_instance)
        _gizmo_mesh_instance.owner = null

func _on_config_changed():
    _update_gizmo()

func _update_gizmo():
    if not Engine.is_editor_hint() or not config or not _gizmo_mesh_instance:
        return
    
    var mesh = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   
    material.albedo_color = Color(0.2, 0.6, 1.0) if not is_control_surface else Color(1.0, 0.6, 0.0)
    material.vertex_color_use_as_albedo = true

    mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

    var s = config.span / 2.0
    var c = config.chord / 2.0
    var flap_z = c - (config.chord * config.flap_fraction)

    var color = Color(0.2, 0.6, 1.0)        # for the wings (blue)
    var flap_color = Color(1.0, 0.6, 0.0)   # for the flaps (orange)

    _draw_line(mesh, Vector3(-s, 0, -c), Vector3(s, 0, -c), color) # Bordo frontale
    _draw_line(mesh, Vector3(s, 0, -c), Vector3(s, 0, c), color)   # Bordo destro
    _draw_line(mesh, Vector3(s, 0, c), Vector3(-s, 0, c), color)   # Bordo posteriore
    _draw_line(mesh, Vector3(-s, 0, c), Vector3(-s, 0, -c), color) # Bordo sinistro

    # Disegna l'area del flap se presente
    if config.flap_fraction > 0.0:
        _draw_line(mesh, Vector3(-s, 0, flap_z), Vector3(s, 0, flap_z), flap_color)
        _draw_line(mesh, Vector3(-s, 0, flap_z), Vector3(-s, 0, c), flap_color)
        _draw_line(mesh, Vector3(s, 0, flap_z), Vector3(s, 0, c), flap_color)
        _draw_line(mesh, Vector3(-s, 0, c), Vector3(s, 0, c), flap_color)

    # Disegna una freccia che indica la direzione di volo (davanti: -Z)
    _draw_line(mesh, Vector3(0, 0, 0), Vector3(0, 0, -c * 1.5), Color.GREEN)
    _draw_line(mesh, Vector3(0, 0, -c * 1.5), Vector3(-s*0.1, 0, -c * 1.2), Color.GREEN)
    _draw_line(mesh, Vector3(0, 0, -c * 1.5), Vector3(s*0.1, 0, -c * 1.2), Color.GREEN)

    mesh.surface_end()

    _gizmo_mesh_instance.mesh = mesh
    _gizmo_mesh_instance.material_override = material

func _draw_line(mesh: ImmediateMesh, p1: Vector3, p2: Vector3, color: Color):
    mesh.surface_set_color(color)
    mesh.surface_add_vertex(p1)
    mesh.surface_set_color(color)
    mesh.surface_add_vertex(p2)