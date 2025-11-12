extends Control

## Handles company creation and menu navigation.

@onready var name_input: LineEdit = %CompanyNameInput
@onready var color_picker: ColorPickerButton = %ColorPicker
@onready var logo_rect: ColorRect = %LogoPreview
@onready var start_button: Button = %StartButton
@onready var dialog: AcceptDialog = %InfoDialog

func _ready() -> void:
    color_picker.color = CompanyData.logo_color
    name_input.text = CompanyData.company_name
    _update_logo()

func _on_start_button_pressed() -> void:
    var name := name_input.text.strip_edges()
    if name.is_empty():
        dialog.dialog_text = "Bitte gib deiner Firma einen Namen."
        dialog.popup_centered()
        return

    CompanyData.company_name = name
    CompanyData.logo_color = color_picker.color
    CompanyData.initialize_new_game()
    get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_exit_button_pressed() -> void:
    get_tree().quit()

func _on_color_picker_color_changed(color: Color) -> void:
    CompanyData.logo_color = color
    _update_logo()

func _on_info_button_pressed() -> void:
    dialog.dialog_text = "Wirtschaftssimulation einer fiktiven Post- und Paketfirma."
    dialog.popup_centered()

func _update_logo() -> void:
    logo_rect.color = color_picker.color
