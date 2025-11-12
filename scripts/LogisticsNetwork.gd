extends Node3D

## Simple animated representation of the parcel center workflow.

@onready var delivery_van: Node3D = $DeliveryVan
@onready var sorting_center: Node3D = $SortingCenter
@onready var loading_dock: Node3D = $LoadingDock

var _route_points: Array = []
var _travel_time := 10.0
var _progress := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()
    set_process(true)

func initialize_network() -> void:
    _route_points = [Vector3(-12, 0.5, -8), Vector3(0, 0.5, 6), Vector3(14, 0.5, -4)]
    _progress = 0.0

func _process(delta: float) -> void:
    if _route_points.is_empty():
        return
    _progress = (_progress + delta / _travel_time) % 1.0
    var segment := float(_route_points.size() - 1) * _progress
    var index := int(floor(segment))
    var t := segment - float(index)
    var start_point: Vector3 = _route_points[index]
    var end_point: Vector3 = _route_points[min(index + 1, _route_points.size() - 1)]
    delivery_van.translation = start_point.lerp(end_point, t)

    var pulse := 1.0 + sin(Time.get_ticks_msec() / 200.0) * 0.1
    sorting_center.scale = Vector3.ONE * pulse

func advance_day() -> void:
    _route_points.shuffle()
    _travel_time = _rng.randf_range(8.0, 16.0)
    _progress = 0.0
    loading_dock.rotation.y += deg_to_rad(_rng.randf_range(-25.0, 25.0))
