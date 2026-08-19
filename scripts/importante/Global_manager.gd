extends Node


var lib_data: LIB_DATA
var lib_func: LIB_FUNCS

var Diana_area
var cliente

var pasta: String
var voz

const CAMINHO_JSON := "user://dados.json"

var API_KEY


var servidor_pid: int = -1


func _ready() -> void:

	# ============================================================
	# LÊ O JSON
	# ============================================================

	var arquivo_leitura := FileAccess.open(
		CAMINHO_JSON,
		FileAccess.READ
	)

	if arquivo_leitura:
		var texto := arquivo_leitura.get_as_text()
		arquivo_leitura.close()

		var resultado = JSON.parse_string(texto)

		if resultado != null:
			API_KEY = resultado["chave"]


	# ============================================================
	# DEFINE A PASTA DA DIANA
	# ============================================================

	if OS.has_feature("editor"):
		pasta = ProjectSettings.globalize_path("res://")
	else:
		pasta = OS.get_executable_path().get_base_dir()


	# ============================================================
	# GARANTE QUE A PASTA TERMINA COM /
	# ============================================================

	if not pasta.ends_with("/"):
		pasta += "/"


	print("========================================")
	print("DIANA")
	print("========================================")
	print("Pasta da aplicação:")
	print(pasta)


	# ============================================================
	# INICIALIZA CLASSES
	# ============================================================

	lib_data = LIB_DATA.new()
	lib_func = LIB_FUNCS.new()


	# ============================================================
	# INICIA SERVIDOR PYTHON
	# ============================================================

	rodar_script_sh()



# ============================================================
# INICIAR SERVIDOR
# ============================================================

func rodar_script_sh() -> void:
	var caminho := pasta.path_join("Python/roda_servidor.sh")

	print("Servidor Python:")
	print(caminho)

	if not FileAccess.file_exists(caminho):
		print("ERRO: roda_servidor.sh não encontrado!")
		return

	var pid := OS.create_process(
		"gnome-terminal",
		[
			"--",
			"bash",
			caminho
		],
		false
	)

	if pid == -1:
		print("ERRO: não foi possível abrir o terminal!")
	else:
		print("Terminal do servidor aberto!")
		print("PID:", pid)

# ============================================================
# PROCESSAR MENSAGEM
# ============================================================

func processar(msg: String) -> void:

	if msg == "" or msg == null:
		return

	cliente.enviar(msg)
	#cliente.chat(msg)


# ============================================================
# FECHAMENTO DA JANELA
# ============================================================

func _notification(what: int) -> void:

	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		antes_de_fechar()


# ============================================================
# ANTES DE FECHAR
# ============================================================

func antes_de_fechar() -> void:

	print("Fechando app...")


	# ========================================================
	# DESLIGA CLIENTE
	# ========================================================

	if cliente != null:
		await cliente.desligar()


	# ========================================================
	# FECHA SERVIDOR PYTHON
	# ========================================================

	if servidor_pid != -1:

		print("Encerrando servidor Python...")

		OS.kill(
			servidor_pid
		)

		servidor_pid = -1


	# ========================================================
	# FECHA GODOT
	# ========================================================

	get_tree().quit()
