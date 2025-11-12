extends Control

## In-game HUD with company overview, asset management and finance controls.

@onready var company_label: Label = %CompanyLabel
@onready var funds_label: Label = %FundsLabel
@onready var reputation_label: Label = %ReputationLabel
@onready var day_label: Label = %DayLabel
@onready var shipment_list: ItemList = %ShipmentList
@onready var report_text: RichTextLabel = %ReportText
@onready var logo_rect: ColorRect = %LogoRect

@onready var building_market_list: ItemList = %BuildingMarketList
@onready var owned_buildings_list: ItemList = %OwnedBuildingsList
@onready var buy_building_button: Button = %BuyBuildingButton
@onready var upgrade_building_button: Button = %UpgradeBuildingButton

@onready var vehicle_market_list: ItemList = %VehicleMarketList
@onready var owned_vehicles_list: ItemList = %OwnedVehiclesList
@onready var buy_vehicle_button: Button = %BuyVehicleButton
@onready var assign_route_button: Button = %AssignRouteButton
@onready var route_origin_option: OptionButton = %RouteOriginOption
@onready var route_destination_option: OptionButton = %RouteDestinationOption
@onready var route_list: ItemList = %RouteList

@onready var loan_offer_list: ItemList = %LoanOfferList
@onready var active_loan_list: ItemList = %ActiveLoanList
@onready var take_loan_button: Button = %TakeLoanButton
@onready var repay_loan_button: Button = %RepayLoanButton

func _ready() -> void:
    building_market_list.item_selected.connect(_update_building_buttons)
    building_market_list.nothing_selected.connect(_update_building_buttons)
    owned_buildings_list.item_selected.connect(_update_building_buttons)
    owned_buildings_list.nothing_selected.connect(_update_building_buttons)
    vehicle_market_list.item_selected.connect(_update_vehicle_buttons)
    vehicle_market_list.nothing_selected.connect(_update_vehicle_buttons)
    owned_vehicles_list.item_selected.connect(_update_vehicle_buttons)
    owned_vehicles_list.nothing_selected.connect(_update_vehicle_buttons)
    loan_offer_list.item_selected.connect(_update_loan_buttons)
    loan_offer_list.nothing_selected.connect(_update_loan_buttons)
    active_loan_list.item_selected.connect(_update_loan_buttons)
    active_loan_list.nothing_selected.connect(_update_loan_buttons)

    buy_building_button.pressed.connect(_on_buy_building_button_pressed)
    upgrade_building_button.pressed.connect(_on_upgrade_building_button_pressed)
    buy_vehicle_button.pressed.connect(_on_buy_vehicle_button_pressed)
    assign_route_button.pressed.connect(_on_assign_route_button_pressed)
    take_loan_button.pressed.connect(_on_take_loan_button_pressed)
    repay_loan_button.pressed.connect(_on_repay_loan_button_pressed)

    _update_building_buttons()
    _update_vehicle_buttons()
    _update_loan_buttons()

func set_company_info(name: String, day: int, funds: float, reputation: float) -> void:
    company_label.text = name
    day_label.text = "Tag %d" % day
    var usd_value := CompanyData.convert_euro_to_usd(funds)
    funds_label.text = "Konto: %s € / $%s" % [_format_currency(funds), _format_currency(usd_value)]
    reputation_label.text = "Reputation: %.0f %%" % (reputation * 100.0)

func set_shipments(shipments: Array) -> void:
    shipment_list.clear()
    for shipment in shipments:
        var entry := "[%s] %s: %s → %s" % [shipment["status"], shipment["type"], shipment["origin"], shipment["destination"]]
        shipment_list.add_item(entry)

func set_market_offers(building_market: Array, vehicle_market: Array) -> void:
    building_market_list.clear()
    for offer in building_market:
        var text := "%s - %s €" % [offer["market_label"], _format_currency(offer["price"])]
        var index := building_market_list.add_item(text)
        building_market_list.set_item_metadata(index, offer)

    vehicle_market_list.clear()
    for offer in vehicle_market:
        var text := "%s (%s) - %s €" % [offer["name"], offer["type"], _format_currency(offer["price"])]
        var index := vehicle_market_list.add_item(text)
        vehicle_market_list.set_item_metadata(index, offer)
    _update_building_buttons()
    _update_vehicle_buttons()

func set_assets(owned_buildings: Array, owned_vehicles: Array, routes: Array) -> void:
    owned_buildings_list.clear()
    route_origin_option.clear()
    route_destination_option.clear()
    if owned_buildings.is_empty():
        route_origin_option.add_item("Keine Gebäude")
        route_origin_option.set_item_disabled(0, true)
        route_destination_option.add_item("Keine Gebäude")
        route_destination_option.set_item_disabled(0, true)
    else:
        for building in owned_buildings:
            var text := "%s · Stufe %d" % [building["name"], building["level"]]
            var index := owned_buildings_list.add_item(text)
            owned_buildings_list.set_item_metadata(index, building)
            var option_index := route_origin_option.get_item_count()
            route_origin_option.add_item(building["name"])
            route_origin_option.set_item_metadata(option_index, building["id"])
            route_destination_option.add_item(building["name"])
            route_destination_option.set_item_metadata(option_index, building["id"])
        route_origin_option.select(0)
        route_destination_option.select(min(1, route_destination_option.get_item_count() - 1))

    owned_vehicles_list.clear()
    for vehicle in owned_vehicles:
        var text := "%s (%s)" % [vehicle["id"], vehicle["name"]]
        var index := owned_vehicles_list.add_item(text)
        owned_vehicles_list.set_item_metadata(index, vehicle)

    route_list.clear()
    for route in routes:
        var text := "%s: %s → %s" % [route["vehicle_id"], route["origin_id"], route["destination_id"]]
        var index := route_list.add_item(text)
        route_list.set_item_metadata(index, route)

    _update_building_buttons()
    _update_vehicle_buttons()

func set_loan_data(offers: Array, active_loans: Array) -> void:
    loan_offer_list.clear()
    for offer in offers:
        var text := "%s - %s €" % [offer["label"], _format_currency(offer["amount"])]
        var index := loan_offer_list.add_item(text)
        loan_offer_list.set_item_metadata(index, offer)

    active_loan_list.clear()
    for loan in active_loans:
        var text := "%s (%d Monate)" % [loan["label"], loan["remaining_months"]]
        var index := active_loan_list.add_item(text)
        active_loan_list.set_item_metadata(index, loan)
    _update_loan_buttons()

func show_report(text: String) -> void:
    report_text.text = text

func set_logo_color(color: Color) -> void:
    logo_rect.color = color

func _on_buy_building_button_pressed() -> void:
    var selection := building_market_list.get_selected_items()
    if selection.is_empty():
        return
    var offer: Dictionary = building_market_list.get_item_metadata(selection[0])
    CompanyData.purchase_building(offer["location_id"])

func _on_upgrade_building_button_pressed() -> void:
    var selection := owned_buildings_list.get_selected_items()
    if selection.is_empty():
        return
    var building: Dictionary = owned_buildings_list.get_item_metadata(selection[0])
    CompanyData.upgrade_building(building["id"])

func _on_buy_vehicle_button_pressed() -> void:
    var selection := vehicle_market_list.get_selected_items()
    if selection.is_empty():
        return
    var offer: Dictionary = vehicle_market_list.get_item_metadata(selection[0])
    CompanyData.buy_vehicle(offer["id"])

func _on_assign_route_button_pressed() -> void:
    var vehicle_selection := owned_vehicles_list.get_selected_items()
    if vehicle_selection.is_empty():
        return
    if route_origin_option.item_count == 0 or route_destination_option.item_count == 0:
        return
    var origin_index := route_origin_option.selected
    var destination_index := route_destination_option.selected
    if origin_index == -1 or destination_index == -1:
        return
    var origin_id := route_origin_option.get_item_metadata(origin_index)
    var destination_id := route_destination_option.get_item_metadata(destination_index)
    var vehicle: Dictionary = owned_vehicles_list.get_item_metadata(vehicle_selection[0])
    CompanyData.assign_vehicle_route(vehicle["id"], origin_id, destination_id)

func _on_take_loan_button_pressed() -> void:
    var selection := loan_offer_list.get_selected_items()
    if selection.is_empty():
        return
    var offer: Dictionary = loan_offer_list.get_item_metadata(selection[0])
    CompanyData.take_loan(offer["id"])

func _on_repay_loan_button_pressed() -> void:
    var selection := active_loan_list.get_selected_items()
    if selection.is_empty():
        return
    var loan: Dictionary = active_loan_list.get_item_metadata(selection[0])
    CompanyData.repay_loan(loan["id"])

func _update_building_buttons() -> void:
    buy_building_button.disabled = building_market_list.get_selected_items().is_empty()
    upgrade_building_button.disabled = owned_buildings_list.get_selected_items().is_empty()

func _update_vehicle_buttons() -> void:
    buy_vehicle_button.disabled = vehicle_market_list.get_selected_items().is_empty()
    var has_vehicle := not owned_vehicles_list.get_selected_items().is_empty()
    assign_route_button.disabled = not (has_vehicle and _has_valid_route_selection())

func _update_loan_buttons() -> void:
    take_loan_button.disabled = loan_offer_list.get_selected_items().is_empty()
    repay_loan_button.disabled = active_loan_list.get_selected_items().is_empty()

func _format_currency(amount: float) -> String:
    var value := int(round(amount))
    var abs_value := abs(value)
    var parts: Array[String] = []
    while abs_value >= 1000:
        parts.insert(0, "%03d" % (abs_value % 1000))
        abs_value = int(abs_value / 1000)
    parts.insert(0, str(abs_value))
    var text := parts.join(".")
    if value < 0:
        text = "-" + text
    return text

func _has_valid_route_selection() -> bool:
    if route_origin_option.get_item_count() == 0 or route_destination_option.get_item_count() == 0:
        return false
    var origin_index := route_origin_option.selected
    var destination_index := route_destination_option.selected
    if origin_index == -1 or destination_index == -1:
        return false
    var origin_meta = route_origin_option.get_item_metadata(origin_index)
    var destination_meta = route_destination_option.get_item_metadata(destination_index)
    return origin_meta != null and destination_meta != null
