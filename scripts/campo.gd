extends Control


var janela: Window

@onready var code_edit: CodeEdit = $Panel/MarginContainer/HBoxContainer/CodeEdit


func _ready() -> void:
	janela = get_window()

	# Captura as teclas pressionadas dentro do CodeEdit
	code_edit.gui_input.connect(_on_code_edit_gui_input)


func _on_code_edit_gui_input(event: InputEvent) -> void:

	if event is InputEventKey:
		if event.pressed and not event.echo:

			# ENTER = enviar
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:

				# SHIFT + ENTER = quebra de linha
				if event.shift_pressed:
					return

				_enviar_mensagem()

				# Impede o CodeEdit de inserir uma quebra de linha
				get_viewport().set_input_as_handled()


func _enviar_mensagem() -> void:

	var mensagem := code_edit.text.strip_edges()

	# Não envia mensagem vazia
	if mensagem.is_empty():
		return

	GlobalManager.processar(mensagem)

	code_edit.text = ""


func _on_btn_mover_pressed() -> void:

	janela.borderless = !janela.borderless

	GlobalManager.Diana_area.janela.borderless = !GlobalManager.Diana_area.janela.borderless


func _on_btn_enviar_pressed() -> void:

	_enviar_mensagem()
