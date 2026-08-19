extends Node
var lib_data : LIB_DATA
var lib_func : LIB_FUNCS

var Diana_area
var cliente

var pasta
var voz



const CAMINHO_JSON := "user://dados.json"
var API_KEY 


func _ready() -> void:
	# ============================================================
	# LÊ O JSON
	# ============================================================

	var arquivo_leitura := FileAccess.open(CAMINHO_JSON, FileAccess.READ)

	if arquivo_leitura:
		var texto := arquivo_leitura.get_as_text()
		arquivo_leitura.close()

		var resultado = JSON.parse_string(texto)

		if resultado != null:
			API_KEY = resultado["chave"]

	if OS.has_feature("editor"):
		pasta = ProjectSettings.globalize_path("res://")
	else:
		pasta = OS.get_executable_path().get_base_dir()
	
	#print(pasta)
	
	lib_data = LIB_DATA.new()
	lib_func = LIB_FUNCS.new()
	rodar_script_sh()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func rodar_script_sh():
	var caminho = str(pasta, "Python/roda_servidor.sh")
	
	OS.execute(
		"gnome-terminal",
		[
			"--",
			"bash",
			caminho
		],
		[],
		false
	)

func processar(msg : String):
	if msg == "" or msg == null: return
	#cliente.enviar(msg)
	cliente.chat(msg)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		antes_de_fechar()


func antes_de_fechar() -> void:
	print("Fechando app...")
	
	# coloque aqui o que precisa acontecer antes de fechar
	# exemplo:
	# salvar dados
	# avisar servidor
	# desligar processos
	await cliente.desligar()
	get_tree().quit()
