extends Node3D

## Visualizes the OpenEarth-inspired world map, owned sites and vehicle routes.

@export var marker_mesh: Mesh
@export var vehicle_mesh: Mesh
@export var branch_material: StandardMaterial3D
@export var depot_material: StandardMaterial3D
@export var hub_material: StandardMaterial3D
@export var vehicle_material: StandardMaterial3D

@onready var map_plane: MeshInstance3D = $MapPlane
@onready var locations_root: Node3D = $Locations
@onready var routes_root: Node3D = $Routes
@onready var vehicles_root: Node3D = $Vehicles

var _locations: Dictionary = {}
var _route_nodes: Dictionary = {}
var _vehicle_states: Dictionary = {}

func _ready() -> void:
    set_process(true)

func initialize_network() -> void:
    _clear_children(locations_root)
    _clear_children(routes_root)
    _clear_children(vehicles_root)
    _locations.clear()
    _route_nodes.clear()
    _vehicle_states.clear()

    for location in CompanyData.get_map_locations():
        _create_location_marker(location)

func apply_company_state(owned_buildings: Array, routes: Array) -> void:
    var owned_lookup := {}
    for building in owned_buildings:
        owned_lookup[building["id"]] = building

    for location_id in _locations.keys():
        var marker_info: Dictionary = _locations[location_id]
        var marker: MeshInstance3D = marker_info["node"]
        var material: StandardMaterial3D = marker_info["material"]
        var owned := owned_lookup.has(location_id)
        var base_color := _base_color_for_type(marker_info["type"], owned)
        material.albedo_color = base_color
        material.emission_enabled = owned
        material.emission = owned ? base_color * 0.8 : Color.BLACK
        marker.scale = Vector3.ONE * (1.0 + (owned ? 0.2 : 0.0))

    _sync_routes(routes)

func _process(delta: float) -> void:
    for vehicle_id in _vehicle_states.keys():
        var state: Dictionary = _vehicle_states[vehicle_id]
        if not state.has("node"):
            continue
        var travel_time: float = max(1.0, state.get("travel_time", 12.0))
        state["progress"] = fmod(state.get("progress", 0.0) + delta / travel_time, 1.0)
        var origin: Vector3 = state["origin"]
        var destination: Vector3 = state["destination"]
        var node: Node3D = state["node"]
        var position := origin.lerp(destination, state["progress"])
        node.translation = position + Vector3(0, 0.6, 0)
        if origin.distance_to(destination) > 0.1:
            node.look_at(destination + Vector3(0, 0.6, 0), Vector3.UP)
        _vehicle_states[vehicle_id] = state

func _sync_routes(routes: Array) -> void:
    var active_routes: Dictionary = {}
    var active_vehicles: Dictionary = {}

    for route in routes:
        if not _locations.has(route["origin_id"]) or not _locations.has(route["destination_id"]):
            continue
        var route_id: String = route["id"]
        active_routes[route_id] = true

        var origin_info: Dictionary = _locations[route["origin_id"]]
        var destination_info: Dictionary = _locations[route["destination_id"]]
        var origin_pos: Vector3 = origin_info["position"]
        var destination_pos: Vector3 = destination_info["position"]

        var line: Line3D
        if _route_nodes.has(route_id):
            line = _route_nodes[route_id]
        else:
            line = Line3D.new()
            line.width = 0.35
            line.default_color = Color(0.95, 0.8, 0.2)
            line.joint_mode = Line3D.JOINT_SHARP
            routes_root.add_child(line)
            _route_nodes[route_id] = line
        line.points = PackedVector3Array([origin_pos + Vector3(0, 0.1, 0), destination_pos + Vector3(0, 0.1, 0)])

        var vehicle_id: String = route["vehicle_id"]
        active_vehicles[vehicle_id] = true
        _ensure_vehicle_state(vehicle_id, origin_pos, destination_pos, route)

    for route_id in _route_nodes.keys():
        if not active_routes.has(route_id):
            _route_nodes[route_id].queue_free()
            _route_nodes.erase(route_id)

    for vehicle_id in _vehicle_states.keys():
        if not active_vehicles.has(vehicle_id):
            var state: Dictionary = _vehicle_states[vehicle_id]
            if state.has("node"):
                state["node"].queue_free()
            _vehicle_states.erase(vehicle_id)

func _ensure_vehicle_state(vehicle_id: String, origin: Vector3, destination: Vector3, route: Dictionary) -> void:
    var state: Dictionary
    if _vehicle_states.has(vehicle_id):
        state = _vehicle_states[vehicle_id]
    else:
        var mesh_instance := MeshInstance3D.new()
        mesh_instance.mesh = vehicle_mesh
        mesh_instance.material_override = vehicle_material.duplicate() if vehicle_material != null else null
        mesh_instance.scale = Vector3(0.8, 0.8, 0.8)
        vehicles_root.add_child(mesh_instance)
        state = {
            "node": mesh_instance,
            "progress": 0.0
        }
    state["origin"] = origin
    state["destination"] = destination
    state["travel_time"] = route.get("travel_time", 12.0)
    _vehicle_states[vehicle_id] = state

func _create_location_marker(location: Dictionary) -> void:
    if marker_mesh == null:
        return
    var marker := MeshInstance3D.new()
    marker.mesh = marker_mesh
    marker.translation = location["position"] + Vector3(0, 0.5, 0)
    var material := _material_for_type(location["type"]).duplicate()
    marker.material_override = material
    marker.scale = Vector3.ONE * 0.9
    marker.name = location["id"]
    locations_root.add_child(marker)
    _locations[location["id"]] = {
        "node": marker,
        "material": material,
        "type": location["type"],
        "position": location["position"]
    }

func _material_for_type(location_type: String) -> StandardMaterial3D:
    match location_type:
        "sorting_center":
            return hub_material if hub_material != null else StandardMaterial3D.new()
        "depot":
            return depot_material if depot_material != null else StandardMaterial3D.new()
        _:
            return branch_material if branch_material != null else StandardMaterial3D.new()

func _base_color_for_type(location_type: String, owned: bool) -> Color:
    var color := Color(0.4, 0.6, 0.4)
    match location_type:
        "sorting_center":
            color = Color(0.9, 0.6, 0.2)
        "depot":
            color = Color(0.35, 0.55, 0.9)
        "branch":
            color = Color(0.4, 0.8, 0.5)
    return color.lightened(0.2) if owned else color.darkened(0.1)

func _clear_children(parent: Node) -> void:
    for child in parent.get_children():
        child.queue_free()

func advance_day() -> void:
    for vehicle_id in _vehicle_states.keys():
        var state: Dictionary = _vehicle_states[vehicle_id]
        state["progress"] = fmod(state.get("progress", 0.0) + 0.2, 1.0)
        _vehicle_states[vehicle_id] = state
