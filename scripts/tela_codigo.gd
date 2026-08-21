extends Control

var dados

@onready var code_edit: CodeEdit = $MarginContainer/CodeEdit
@onready var texture_rect: TextureRect = $TextureRect


func _ready() -> void:
	code_edit.text = str(dados["codigo"])

	var codigo: String = str(dados["codigo"])

	if codigo.strip_edges().begins_with("<svg"):
		carregar_svg(codigo)


func carregar_svg(codigo: String) -> void:
	var imagem := Image.new()

	var erro := imagem.load_svg_from_string(codigo)

	if erro != OK:
		print("Erro ao carregar SVG: ", erro)
		return

	var textura := ImageTexture.create_from_image(imagem)
	
	
	$MarginContainer.visible = false
	texture_rect.texture = textura
	texture_rect.visible = true
