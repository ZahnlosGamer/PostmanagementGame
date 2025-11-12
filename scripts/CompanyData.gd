extends Node

## Holds persistent company state and economy simulation.

var company_name: String = "Neue Post AG"
var logo_color: Color = Color(0.9, 0.6, 0.2)
var funds: float = 100000.0
var reputation: float = 0.55
var day: int = 1
var shipments: Array = []
var pending_report: String = ""

var _hud: Node = null
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()

func register_hud(hud: Node) -> void:
    _hud = hud
    update_hud()

func initialize_new_game() -> void:
    funds = 100000.0
    reputation = 0.55
    day = 1
    shipments.clear()
    pending_report = ""
    for i in range(4):
        create_random_shipment()
    update_hud()

func create_random_shipment() -> Dictionary:
    var parcel_types = ["Standardpaket", "Expresspaket", "Briefpost", "Sperrgut"]
    var destinations = ["Berlin", "Hamburg", "München", "Köln", "Leipzig", "Stuttgart", "Bremen"]
    var origins = ["Frankfurt", "Düsseldorf", "Dresden", "Hannover", "Nürnberg"]
    var type = parcel_types[_rng.randi_range(0, parcel_types.size() - 1)]
    var origin = origins[_rng.randi_range(0, origins.size() - 1)]
    var destination = destinations[_rng.randi_range(0, destinations.size() - 1)]
    var distance_factor = 1.0 + float(abs(origins.find(origin) - destinations.find(destination))) * 0.1
    var base_cost = 150.0 * distance_factor
    var reward = base_cost * _rng.randf_range(1.3, 1.8)
    var duration = _rng.randi_range(1, 3)
    var shipment := {
        "id": "%08X" % _rng.randi(),
        "type": type,
        "origin": origin,
        "destination": destination,
        "status": "Queued",
        "days_remaining": duration,
        "cost": base_cost,
        "reward": reward
    }
    shipments.append(shipment)
    update_hud()
    return shipment

func advance_day() -> void:
    day += 1
    var completed := []
    var report_lines: Array[String] = ["Tagesbericht Tag %d" % day]
    var expenses := 0.0
    var income := 0.0

    for shipment in shipments:
        match shipment["status"]:
            "Queued":
                shipment["status"] = "In Transit"
                expenses += shipment["cost"]
            "In Transit":
                shipment["days_remaining"] -= 1
                if shipment["days_remaining"] <= 0:
                    shipment["status"] = "Delivered"
                    income += shipment["reward"]
                    completed.append(shipment)
                elif _rng.randf() < 0.15:
                    shipment["status"] = "Delayed"
            "Delayed":
                shipment["days_remaining"] -= 1
                if shipment["days_remaining"] <= 0:
                    shipment["status"] = "Delivered"
                    income += shipment["reward"]
                    completed.append(shipment)
                elif _rng.randf() < 0.25:
                    shipment["status"] = "Lost"
                    reputation = max(0.0, reputation - 0.02)
            "Delivered":
                pass
            "Lost":
                pass

    for shipment in completed:
        shipments.erase(shipment)

    for i in range(_rng.randi_range(1, 3)):
        create_random_shipment()

    funds += income - expenses
    reputation = clamp(reputation + 0.01 * completed.size(), 0.0, 1.0)

    report_lines.append("Einnahmen: %.2f €" % income)
    report_lines.append("Ausgaben: %.2f €" % expenses)
    report_lines.append("Bilanz: %.2f €" % (income - expenses))
    report_lines.append("Reputation: %.0f %%" % (reputation * 100.0))
    report_lines.append("Aktiver Bestand: %d Sendungen" % shipments.size())

    pending_report = "\n".join(report_lines)
    update_hud()

func update_hud() -> void:
    if _hud == null:
        return
    if _hud.has_method("set_company_info"):
        _hud.set_company_info(company_name, day, funds, reputation)
    if _hud.has_method("set_shipments"):
        _hud.set_shipments(shipments)
    if _hud.has_method("show_report") and pending_report != "":
        _hud.show_report(pending_report)
        pending_report = ""

func add_funds(amount: float, description: String = "") -> void:
    funds += amount
    if description != "":
        pending_report += "\n%s: %.2f €" % [description, amount]
    update_hud()
