extends Control

var janela : Window
@onready var code_edit: CodeEdit = $Panel/MarginContainer/HBoxContainer/CodeEdit
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	janela = get_window()
	pass # Replace with function body.



func _on_btn_mover_pressed() -> void:
	janela.borderless = !janela.borderless
	GlobalManager.Diana_area.janela.borderless = !GlobalManager.Diana_area.janela.borderless
	pass # Replace with function body.


func _on_btn_enviar_pressed() -> void:
	GlobalManager.processar(code_edit.text)
	code_edit.text = ""
	pass # Replace with function body.
