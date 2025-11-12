extends Node

## Holds persistent company state, market data and economy simulation.

const EURO_TO_USD := 1.08

const MAP_LOCATIONS := [
    {
        "id": "berlin_hub",
        "name": "Sortierzentrum Berlin",
        "type": "sorting_center",
        "position": Vector3(16, 0.2, -6),
        "price_range": Vector2(780000.0, 1150000.0),
        "base_capacity": 85000,
        "max_level": 4,
        "upgrade_multiplier": 1.45
    },
    {
        "id": "hamburg_branch",
        "name": "Postfiliale Hamburg",
        "type": "branch",
        "position": Vector3(-14, 0.2, 10),
        "price_range": Vector2(240000.0, 410000.0),
        "base_capacity": 1200,
        "max_level": 3,
        "upgrade_multiplier": 1.35
    },
    {
        "id": "munich_branch",
        "name": "Postfiliale München",
        "type": "branch",
        "position": Vector3(10, 0.2, 14),
        "price_range": Vector2(260000.0, 430000.0),
        "base_capacity": 1100,
        "max_level": 3,
        "upgrade_multiplier": 1.32
    },
    {
        "id": "cologne_branch",
        "name": "Postfiliale Köln",
        "type": "branch",
        "position": Vector3(-6, 0.2, -12),
        "price_range": Vector2(210000.0, 360000.0),
        "base_capacity": 950,
        "max_level": 3,
        "upgrade_multiplier": 1.28
    },
    {
        "id": "leipzig_depot",
        "name": "Regionaldepot Leipzig",
        "type": "depot",
        "position": Vector3(4, 0.2, -2),
        "price_range": Vector2(420000.0, 620000.0),
        "base_capacity": 15000,
        "max_level": 4,
        "upgrade_multiplier": 1.38
    }
]

const VEHICLE_CATALOG := [
    {
        "id": "transporter",
        "name": "Transporterklasse",
        "type": "Van",
        "price_range": Vector2(48000.0, 68000.0),
        "capacity": 120,
        "speed": 70.0
    },
    {
        "id": "box_truck",
        "name": "7.5t LKW",
        "type": "Truck",
        "price_range": Vector2(92000.0, 145000.0),
        "capacity": 420,
        "speed": 62.0
    },
    {
        "id": "tractor_trailer",
        "name": "Sattelzug",
        "type": "Long Haul",
        "price_range": Vector2(175000.0, 245000.0),
        "capacity": 1100,
        "speed": 80.0
    }
]

const LOAN_PRODUCTS := [
    {
        "id": "loan_small",
        "label": "Betriebsmittelkredit",
        "amount": 250000.0,
        "interest_rate": 0.035,
        "term_months": 24
    },
    {
        "id": "loan_expansion",
        "label": "Expansionsdarlehen",
        "amount": 600000.0,
        "interest_rate": 0.041,
        "term_months": 48
    },
    {
        "id": "loan_logistics",
        "label": "Logistikpark-Finanzierung",
        "amount": 1200000.0,
        "interest_rate": 0.049,
        "term_months": 72
    }
]

var company_name: String = "Neue Post AG"
var logo_color: Color = Color(0.9, 0.6, 0.2)
var funds: float = 1_000_000.0
var reputation: float = 0.55
var day: int = 1
var shipments: Array = []
var pending_report: String = ""
var building_market: Array = []
var vehicle_market: Array = []
var owned_buildings: Array = []
var owned_vehicles: Array = []
var vehicle_routes: Array = []
var active_loans: Array = []

var _hud: Node = null
var _world: Node = null
var _rng := RandomNumberGenerator.new()
var _vehicle_serial := 1

func _ready() -> void:
    _rng.randomize()

func register_hud(hud: Node) -> void:
    _hud = hud
    update_hud()

func register_world(world: Node) -> void:
    _world = world
    _update_world()

func initialize_new_game() -> void:
    funds = 1_000_000.0
    reputation = 0.55
    day = 1
    shipments.clear()
    pending_report = ""
    building_market.clear()
    vehicle_market.clear()
    owned_buildings.clear()
    owned_vehicles.clear()
    vehicle_routes.clear()
    active_loans.clear()
    _vehicle_serial = 1
    _refresh_markets()
    for i in range(6):
        create_random_shipment()
    update_hud()

func get_map_locations() -> Array:
    return MAP_LOCATIONS.duplicate(true)

func convert_euro_to_usd(amount: float) -> float:
    return amount * EURO_TO_USD

func create_random_shipment() -> Dictionary:
    var origin_entry = _pick_random_location()
    var destination_entry = _pick_random_location(origin_entry["id"])
    var distance = origin_entry["position"].distance_to(destination_entry["position"])
    var weight_categories = ["Briefe", "Standardpaket", "Expresspaket", "Sperrgut"]
    var parcel_type = weight_categories[_rng.randi_range(0, weight_categories.size() - 1)]
    var base_cost = max(120.0, distance * 22.5)
    var reward = base_cost * _rng.randf_range(1.25, 1.75)
    var duration = clamp(int(distance / 6.0), 1, 4)
    var shipment := {
        "id": "%08X" % _rng.randi(),
        "type": parcel_type,
        "origin": origin_entry["name"],
        "destination": destination_entry["name"],
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
                elif _rng.randf() < 0.12:
                    shipment["status"] = "Delayed"
            "Delayed":
                shipment["days_remaining"] -= 1
                if shipment["days_remaining"] <= 0:
                    shipment["status"] = "Delivered"
                    income += shipment["reward"]
                    completed.append(shipment)
                elif _rng.randf() < 0.2:
                    shipment["status"] = "Lost"
                    reputation = max(0.0, reputation - 0.02)
            _:
                pass

    for shipment in completed:
        shipments.erase(shipment)

    var new_shipments := 1 + vehicle_routes.size()
    for i in range(new_shipments):
        create_random_shipment()

    var loan_cost := _process_loans()
    expenses += loan_cost

    funds += income - expenses
    reputation = clamp(reputation + 0.01 * completed.size(), 0.0, 1.0)

    report_lines.append("Einnahmen: %.2f €" % income)
    report_lines.append("Ausgaben: %.2f €" % expenses)
    report_lines.append("Bilanz: %.2f €" % (income - expenses))
    report_lines.append("Reputation: %.0f %%" % (reputation * 100.0))
    report_lines.append("Aktiver Bestand: %d Sendungen" % shipments.size())

    pending_report = "\n".join(report_lines)
    _refresh_markets()
    update_hud()

func update_hud() -> void:
    if _hud != null:
        if _hud.has_method("set_company_info"):
            _hud.set_company_info(company_name, day, funds, reputation)
        if _hud.has_method("set_shipments"):
            _hud.set_shipments(shipments)
        if _hud.has_method("set_market_offers"):
            _hud.set_market_offers(building_market, vehicle_market)
        if _hud.has_method("set_assets"):
            _hud.set_assets(owned_buildings, owned_vehicles, vehicle_routes)
        if _hud.has_method("set_loan_data"):
            _hud.set_loan_data(LOAN_PRODUCTS, active_loans)
        if _hud.has_method("show_report") and pending_report != "":
            _hud.show_report(pending_report)
            pending_report = ""
    _update_world()

func purchase_building(location_id: String) -> bool:
    var offer = _find_building_offer(location_id)
    if offer == null:
        _append_report_line("Kein Gebäudeangebot für Standort %s gefunden." % location_id)
        update_hud()
        return false
    if funds < offer["price"]:
        _append_report_line("Nicht genug Kapital für %s." % offer["name"])
        update_hud()
        return false

    var location = _get_location(location_id)
    var building_entry := {
        "id": location_id,
        "name": location["name"],
        "type": location["type"],
        "level": 1,
        "max_level": location.get("max_level", 3),
        "upgrade_multiplier": location.get("upgrade_multiplier", 1.3),
        "base_value": offer["price"],
        "capacity": location.get("base_capacity", 800),
        "position": location["position"],
        "market_label": offer["market_label"]
    }

    funds -= offer["price"]
    owned_buildings.append(building_entry)
    building_market.erase(offer)
    _append_report_line("%s übernommen für %.0f €." % [building_entry["name"], offer["price"]])
    _refresh_markets()
    update_hud()
    return true

func upgrade_building(location_id: String) -> bool:
    for i in owned_buildings.size():
        if owned_buildings[i]["id"] == location_id:
            var building = owned_buildings[i]
            if building["level"] >= building["max_level"]:
                _append_report_line("%s ist bereits maximal ausgebaut." % building["name"])
                update_hud()
                return false
            var upgrade_cost = building["base_value"] * pow(building["upgrade_multiplier"], building["level"])
            if funds < upgrade_cost:
                _append_report_line("Nicht genug Kapital für Ausbau von %s." % building["name"])
                update_hud()
                return false
            funds -= upgrade_cost
            building["level"] += 1
            building["capacity"] = int(building["capacity"] * 1.25)
            owned_buildings[i] = building
            _append_report_line("%s auf Stufe %d erweitert (%.0f €)." % [building["name"], building["level"], upgrade_cost])
            update_hud()
            return true
    _append_report_line("Kein Besitz in %s gefunden." % location_id)
    update_hud()
    return false

func buy_vehicle(vehicle_id: String) -> bool:
    var offer = _find_vehicle_offer(vehicle_id)
    if offer == null:
        _append_report_line("Fahrzeugangebot %s nicht verfügbar." % vehicle_id)
        update_hud()
        return false
    if funds < offer["price"]:
        _append_report_line("Nicht genug Kapital für %s." % offer["name"])
        update_hud()
        return false

    funds -= offer["price"]
    var instance_id = "%s-%04d" % [vehicle_id.upper(), _vehicle_serial]
    _vehicle_serial += 1
    var vehicle_entry := {
        "id": instance_id,
        "template_id": offer["id"],
        "name": offer["name"],
        "type": offer["type"],
        "capacity": offer["capacity"],
        "speed": offer["speed"],
        "value": offer["price"],
        "status": "Idle"
    }
    owned_vehicles.append(vehicle_entry)
    _append_report_line("%s erworben für %.0f €." % [vehicle_entry["name"], offer["price"]])
    update_hud()
    return true

func assign_vehicle_route(vehicle_instance_id: String, origin_id: String, destination_id: String) -> bool:
    if origin_id == destination_id:
        _append_report_line("Start- und Zielstandort müssen unterschiedlich sein.")
        update_hud()
        return false
    var vehicle = _find_vehicle(vehicle_instance_id)
    if vehicle == null:
        _append_report_line("Fahrzeug %s nicht gefunden." % vehicle_instance_id)
        update_hud()
        return false
    if _get_owned_building(origin_id) == null or _get_owned_building(destination_id) == null:
        _append_report_line("Route erfordert eigene Gebäude in Start und Ziel.")
        update_hud()
        return false

    var route_id = "route_%s" % vehicle_instance_id
    var existing := _find_route(route_id)
    var location_a = _get_location(origin_id)
    var location_b = _get_location(destination_id)
    var distance = location_a["position"].distance_to(location_b["position"])
    var travel_time = max(8.0, distance / max(10.0, vehicle["speed"]))
    var route_entry := {
        "id": route_id,
        "vehicle_id": vehicle_instance_id,
        "origin_id": origin_id,
        "destination_id": destination_id,
        "speed": vehicle["speed"],
        "distance": distance,
        "travel_time": travel_time
    }

    if existing != null:
        vehicle_routes[vehicle_routes.find(existing)] = route_entry
    else:
        vehicle_routes.append(route_entry)
    vehicle["status"] = "Einsatz"
    _replace_vehicle(vehicle_instance_id, vehicle)
    _append_report_line("Route %s → %s für %s eingerichtet." % [location_a["name"], location_b["name"], vehicle_instance_id])
    update_hud()
    return true

func take_loan(loan_id: String) -> bool:
    if _find_active_loan(loan_id) != null:
        _append_report_line("Kredit %s ist bereits aktiv." % loan_id)
        update_hud()
        return false
    var offer = _find_loan_product(loan_id)
    if offer == null:
        _append_report_line("Kreditangebot %s nicht gefunden." % loan_id)
        update_hud()
        return false

    var monthly_rate = _calculate_monthly_payment(offer["amount"], offer["interest_rate"], offer["term_months"])
    var loan_entry := {
        "id": offer["id"],
        "label": offer["label"],
        "principal": offer["amount"],
        "interest_rate": offer["interest_rate"],
        "term_months": offer["term_months"],
        "remaining_months": offer["term_months"],
        "monthly_payment": monthly_rate,
        "days_until_payment": 30
    }

    active_loans.append(loan_entry)
    funds += offer["amount"]
    _append_report_line("%s aufgenommen: %.0f € zu %.2f %% p.a." % [offer["label"], offer["amount"], offer["interest_rate"] * 100.0])
    update_hud()
    return true

func repay_loan(loan_id: String) -> bool:
    for loan in active_loans:
        if loan["id"] == loan_id:
            var payoff = loan["remaining_months"] * loan["monthly_payment"]
            if funds < payoff:
                _append_report_line("Nicht genug Kapital zur vorzeitigen Ablöse von %s." % loan["label"])
                update_hud()
                return false
            funds -= payoff
            active_loans.erase(loan)
            _append_report_line("%s vorzeitig getilgt (%.0f €)." % [loan["label"], payoff])
            update_hud()
            return true
    _append_report_line("Kein laufender Kredit %s gefunden." % loan_id)
    update_hud()
    return false

func add_funds(amount: float, description: String = "") -> void:
    funds += amount
    if description != "":
        _append_report_line("%s: %.2f €" % [description, amount])
    update_hud()

func _refresh_markets() -> void:
    building_market.clear()
    for location in MAP_LOCATIONS:
        if _get_owned_building(location["id"]) == null:
            var price = _rng.randf_range(location["price_range"].x, location["price_range"].y)
            var market_label = "%s (%s)" % [location["name"], _translate_location_type(location["type"])]
            building_market.append({
                "location_id": location["id"],
                "name": location["name"],
                "type": location["type"],
                "price": price,
                "market_label": market_label
            })
    vehicle_market.clear()
    for vehicle in VEHICLE_CATALOG:
        var price = _rng.randf_range(vehicle["price_range"].x, vehicle["price_range"].y)
        vehicle_market.append({
            "id": vehicle["id"],
            "name": vehicle["name"],
            "type": vehicle["type"],
            "price": price,
            "capacity": vehicle["capacity"],
            "speed": vehicle["speed"]
        })

func _process_loans() -> float:
    var total_payment := 0.0
    for loan in active_loans:
        loan["days_until_payment"] -= 1
        if loan["days_until_payment"] <= 0:
            loan["days_until_payment"] = 30
            if loan["remaining_months"] > 0:
                total_payment += loan["monthly_payment"]
                loan["remaining_months"] -= 1
                _append_report_line("Kreditzahlung %s: %.0f €" % [loan["label"], loan["monthly_payment"]])
    active_loans = active_loans.filter(func(loan): return loan["remaining_months"] > 0)
    return total_payment

func _calculate_monthly_payment(principal: float, interest_rate: float, term_months: int) -> float:
    var monthly_rate := interest_rate / 12.0
    if monthly_rate <= 0.0:
        return principal / float(term_months)
    var factor := pow(1.0 + monthly_rate, term_months)
    return principal * (monthly_rate * factor) / (factor - 1.0)

func _pick_random_location(exclude_id: String = "") -> Dictionary:
    var options: Array = []
    if owned_buildings.size() > 0:
        for building in owned_buildings:
            if building["id"] != exclude_id:
                options.append(building)
    if options.is_empty():
        for location in MAP_LOCATIONS:
            if location["id"] != exclude_id:
                options.append(location)
    return options[_rng.randi_range(0, options.size() - 1)]

func _get_location(location_id: String) -> Dictionary:
    for location in MAP_LOCATIONS:
        if location["id"] == location_id:
            return location
    return {}

func _get_owned_building(location_id: String) -> Dictionary:
    for building in owned_buildings:
        if building["id"] == location_id:
            return building
    return null

func _find_building_offer(location_id: String) -> Dictionary:
    for offer in building_market:
        if offer["location_id"] == location_id:
            return offer
    return null

func _find_vehicle_offer(vehicle_id: String) -> Dictionary:
    for offer in vehicle_market:
        if offer["id"] == vehicle_id:
            return offer
    return null

func _find_vehicle(vehicle_instance_id: String) -> Dictionary:
    for vehicle in owned_vehicles:
        if vehicle["id"] == vehicle_instance_id:
            return vehicle
    return null

func _replace_vehicle(vehicle_instance_id: String, updated: Dictionary) -> void:
    for i in owned_vehicles.size():
        if owned_vehicles[i]["id"] == vehicle_instance_id:
            owned_vehicles[i] = updated
            return

func _find_route(route_id: String) -> Dictionary:
    for route in vehicle_routes:
        if route["id"] == route_id:
            return route
    return null

func _find_loan_product(loan_id: String) -> Dictionary:
    for offer in LOAN_PRODUCTS:
        if offer["id"] == loan_id:
            return offer
    return null

func _find_active_loan(loan_id: String) -> Dictionary:
    for loan in active_loans:
        if loan["id"] == loan_id:
            return loan
    return null

func _translate_location_type(location_type: String) -> String:
    match location_type:
        "sorting_center":
            return "Sortierzentrum"
        "depot":
            return "Depot"
        "branch":
            return "Filiale"
        _:
            return location_type.capitalize()

func _append_report_line(text: String) -> void:
    if pending_report.is_empty():
        pending_report = text
    else:
        pending_report += "\n" + text

func _update_world() -> void:
    if _world == null:
        return
    if _world.has_method("apply_company_state"):
        _world.apply_company_state(owned_buildings, vehicle_routes)
