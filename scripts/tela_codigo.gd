extends Control

var dados
@onready var code_edit: CodeEdit = $MarginContainer/CodeEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	code_edit.text = str(dados["codigo"])
