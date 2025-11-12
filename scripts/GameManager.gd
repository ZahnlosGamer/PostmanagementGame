extends Node3D

## Controls the main logistics simulation loop.

@onready var logistics_root: Node3D = $LogisticsRoot
@onready var hud = $HUDLayer/HUD

const DAY_LENGTH := 12.0
var _day_timer := 0.0

func _ready() -> void:
    CompanyData.register_hud(hud)
    hud.set_logo_color(CompanyData.logo_color)
    logistics_root.initialize_network()
    CompanyData.register_world(logistics_root)
    CompanyData.update_hud()
    set_process(true)

func _process(delta: float) -> void:
    _day_timer += delta
    if _day_timer >= DAY_LENGTH:
        _day_timer = 0.0
        _advance_day()
    CompanyData.update_hud()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        _advance_day()

func _advance_day() -> void:
    CompanyData.advance_day()
    logistics_root.advance_day()
    CompanyData.update_hud()
