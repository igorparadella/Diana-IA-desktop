extends Node3D
var janela : Window



@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	GlobalManager.Diana_area = self
	GlobalManager.voz = audio_stream_player
	
	janela = get_window()
	get_tree().set_auto_accept_quit(false)
	get_tree().root.gui_embed_subwindows = false
	# 1. Altera as configurações internas se necessário
	var config_mudou = false
	if not ProjectSettings.get_setting("display/window/per_pixel_transparency/allowed"):
		ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", true)
		config_mudou = true
	
	# OBRIGATÓRIO: Garante que o tamanho inicial e o modo da janela nasçam compatíveis no arquivo
	if not ProjectSettings.get_setting("display/window/size/borderless"):
		ProjectSettings.set_setting("display/window/size/borderless", true)
		config_mudou = true
		
	if config_mudou:
		ProjectSettings.save()
		print("Configurações críticas aplicadas! REINICIE O GODOT para funcionar em modo janela.")
		return # Evita executar o resto com erro na primeira execução

	# 2. Configura o tamanho da janela ANTES de aplicar as flags de transparência
	var window_size := Vector2i(350, 400)
	DisplayServer.window_set_size(window_size)

	# 3. Calcula e define a posição no canto inferior direito
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var margin_right := 100
	var margin_bottom := 0
	
	var position := Vector2i(
		screen_size.x - window_size.x - margin_right,
		screen_size.y - window_size.y - margin_bottom
	)
	DisplayServer.window_set_position(position)

	# 4. FORÇA o modo janela explicitamente para o SO processar corretamente
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# 5. Aplica as flags de transparência por último (Garante que o SO remova as bordas)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	# 6. Limpa o fundo da viewport
	get_viewport().transparent_bg = true
	
	criar_janela()


func criar_janela(
		titulo: String = "Nova Janela",
		cena: String = "res://cenas/campo.tscn",
		largura: int = 400,
		altura: int = 50
	) -> Window:
	var janela := Window.new()

	janela.title = titulo
	janela.size = Vector2i(largura, altura)
	janela.unresizable = false
	janela.always_on_top = true
	janela.transparent = true
	janela.maximize_disabled = true
	janela.borderless = true # Remove a borda e a barra de título

	# Centraliza na tela
	var tela := DisplayServer.screen_get_usable_rect()

	janela.position = Vector2i(
		tela.position.x + (tela.size.x - janela.size.x) / 2,
		tela.position.y + tela.size.y - janela.size.y
	)

	# Carrega e instancia a cena
	var packed_scene := load(cena) as PackedScene
	if packed_scene:
		var instancia := packed_scene.instantiate()
		janela.add_child(instancia)
	else:
		push_error("Não foi possível carregar a cena: " + cena)

	add_child(janela)

	janela.show()

	return janela

@onready var timer: Timer = $Timer
@export var contador = 0
@export var contador_limite = 60

func _on_timer_timeout() -> void:
	contador += 1
	if contador >= contador_limite:
		GlobalManager.diana_aleatoria()
		contador_limite = randf_range(300.0, 600.0)
		contador = 0
