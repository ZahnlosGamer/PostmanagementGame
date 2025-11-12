extends Control

## In-game HUD and daily report panel.

@onready var company_label: Label = %CompanyLabel
@onready var funds_label: Label = %FundsLabel
@onready var reputation_label: Label = %ReputationLabel
@onready var day_label: Label = %DayLabel
@onready var shipment_list: ItemList = %ShipmentList
@onready var report_text: RichTextLabel = %ReportText
@onready var logo_rect: ColorRect = %LogoRect

func set_company_info(name: String, day: int, funds: float, reputation: float) -> void:
    company_label.text = name
    day_label.text = "Tag %d" % day
    funds_label.text = "Konto: %.2f €" % funds
    reputation_label.text = "Reputation: %.0f %%" % (reputation * 100.0)

func set_shipments(shipments: Array) -> void:
    shipment_list.clear()
    for shipment in shipments:
        var entry := "[%s] %s %s → %s" % [shipment["status"], shipment["type"], shipment["origin"], shipment["destination"]]
        shipment_list.add_item(entry)

func show_report(text: String) -> void:
    report_text.text = text

func set_logo_color(color: Color) -> void:
    logo_rect.color = color
