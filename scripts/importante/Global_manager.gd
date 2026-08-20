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

var diana_status = {
	"humor" : {
		"feliciade" : 1,
		"curiosidade" : 1,
		"confianca" : 1,
		"energia" : 1,
		"tedio" : 1,
	},
	"fazendo" : "",
}

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

	var caminho := pasta.path_join(
		"Python/roda_servidor.sh"
	)

	print("Servidor Python:")
	print(caminho)


	if not FileAccess.file_exists(caminho):

		print(
			"ERRO: roda_servidor.sh não encontrado!"
		)

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

		print(
			"ERRO: não foi possível abrir o terminal!"
		)

	else:

		print(
			"Terminal do servidor aberto!"
		)

		print(
			"PID:",
			pid
		)


# ============================================================
# PROCESSAR MENSAGEM
# ============================================================

func processar(msg: String) -> void: # nuca pagar nada dessa func

	if msg == "" or msg == null:
		return

	#processar_resposta(msg)
	#cliente.enviar(msg)
	cliente.chat(msg)
	
	#processar_resposta(msg)


# ============================================================
# PROCESSAR RESPOSTA DA DIANA
# ============================================================

func processar_resposta(resposta: String) -> void:

	var restante := resposta


	while true:

		var inicio := restante.find("<")


		# --------------------------------------------------------
		# Não existem mais blocos especiais
		# --------------------------------------------------------

		if inicio == -1:
			break


		# --------------------------------------------------------
		# Procura o fim da tag
		# --------------------------------------------------------

		var fim_tag := restante.find(
			">",
			inicio
		)


		# --------------------------------------------------------
		# Tag incompleta
		# --------------------------------------------------------

		if fim_tag == -1:
			break


		# --------------------------------------------------------
		# Nome da tag
		# --------------------------------------------------------

		var tag := restante.substr(
			inicio + 1,
			fim_tag - inicio - 1
		)


		# --------------------------------------------------------
		# Ignora tags de fechamento
		# --------------------------------------------------------

		if tag.begins_with("/"):

			restante = restante.substr(
				fim_tag + 1
			)

			continue


		# --------------------------------------------------------
		# Procura a tag de fechamento
		# --------------------------------------------------------

		var tag_fechamento := "</" + tag + ">"

		var fim := restante.find(
			tag_fechamento,
			fim_tag + 1
		)


		# --------------------------------------------------------
		# Bloco ainda não terminou
		# --------------------------------------------------------

		if fim == -1:
			break


		# --------------------------------------------------------
		# Conteúdo dentro da tag
		# --------------------------------------------------------

		var inicio_conteudo := fim_tag + 1

		var conteudo := restante.substr(
			inicio_conteudo,
			fim - inicio_conteudo
		).strip_edges()


		# --------------------------------------------------------
		# Processa o bloco
		# --------------------------------------------------------

		processar_bloco(
			tag,
			conteudo
		)


		# --------------------------------------------------------
		# Remove o bloco processado
		# --------------------------------------------------------

		restante = (
			restante.substr(
				0,
				inicio
			)
			+
			restante.substr(
				fim + tag_fechamento.length()
			)
		)


	# ============================================================
	# TEXTO QUE SOBROU
	# ============================================================

	restante = restante.strip_edges()


	# Se quiser enviar qualquer texto fora das tags para a fala:
	#
	# if not restante.is_empty():
	#     cliente.enviar(restante)


# ============================================================
# PROCESSAR BLOCO
# ============================================================

func processar_bloco(
		tipo: String,
		conteudo: String
	) -> void:

	match tipo:

		# --------------------------------------------------------
		# CÓDIGO
		# --------------------------------------------------------

		"codigo":

			mostrar_codigo({
				"codigo": conteudo
			})


		# --------------------------------------------------------
		# COMANDO
		# --------------------------------------------------------

		"comando":

			print(
				"Comando: ",
				conteudo
			)
		
		"felicidade":
			diana_status["humor"]["felicidade"] = float(conteudo)
		"curiosidade":
			diana_status["humor"]["curiosidade"] = float(conteudo)
		"confianca":
			diana_status["humor"]["confianca"] = float(conteudo)
		"energia":
			diana_status["humor"]["energia"] = float(conteudo)
		"tedio":
			diana_status["humor"]["tedio"] = float(conteudo)
		"fazendo":
			diana_status["fazendo"] = float(conteudo)


		# --------------------------------------------------------
		# MEMÓRIA
		#
		# O conteúdo inteiro é a memória.
		#
		# Exemplo:
		#
		# <memoria>O usuário gosta de Godot.</memoria>
		#
		# Não existe mais:
		#
		# chave: valor
		# --------------------------------------------------------

		"memoria":

			salvar_memoria(
				conteudo
			)


		# --------------------------------------------------------
		# FALA
		# --------------------------------------------------------

		"fala":

			if cliente != null:

				cliente.enviar(
					conteudo
				)

			else:

				print(
					"Erro: cliente não está disponível."
				)


		# --------------------------------------------------------
		# DESCONHECIDO
		# --------------------------------------------------------

		_:

			print(
				"Bloco desconhecido: <",
				tipo,
				">"
			)

			print(conteudo)


# ============================================================
# SALVAR MEMÓRIA
# ============================================================

func salvar_memoria(conteudo: String) -> void:

	conteudo = conteudo.strip_edges()


	# --------------------------------------------------------
	# Não salva memória vazia
	# --------------------------------------------------------

	if conteudo.is_empty():

		print(
			"Memória vazia. Nada para salvar."
		)

		return


	# --------------------------------------------------------
	# Verifica se o cliente existe
	# --------------------------------------------------------

	if cliente == null:

		print(
			"Erro: cliente não está disponível."
		)

		return


	# --------------------------------------------------------
	# Envia o texto inteiro para o cliente
	# --------------------------------------------------------

	var sucesso = cliente.salvar_memoria(
		conteudo
	)


	# --------------------------------------------------------
	# Resultado
	# --------------------------------------------------------

	if sucesso:

		print(
			"========================================"
		)

		print(
			"MEMÓRIA REGISTRADA"
		)

		print(
			conteudo
		)

		print(
			"========================================"
		)

	else:

		print(
			"Falha ao salvar memória."
		)


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

	print(
		"Fechando app..."
	)


	# ========================================================
	# DESLIGA CLIENTE
	# ========================================================

	if cliente != null:

		await cliente.desligar()


	# ========================================================
	# FECHA SERVIDOR PYTHON
	# ========================================================

	if servidor_pid != -1:

		print(
			"Encerrando servidor Python..."
		)

		OS.kill(
			servidor_pid
		)

		servidor_pid = -1


	# ========================================================
	# FECHA GODOT
	# ========================================================

	get_tree().quit()


# ============================================================
# MOSTRAR CÓDIGO
# ============================================================

func mostrar_codigo(
	dados: Dictionary = {}
) -> Window:

	var titulo: String = "Nova Janela"

	var cena: String = (
		"res://prefabs/codigo.tscn"
	)

	var largura: int = 400

	var altura: int = 500

	var janela := Window.new()


	# ============================================================
	# CONFIGURAÇÃO
	# ============================================================

	janela.title = titulo

	janela.size = Vector2i(
		largura,
		altura
	)

	janela.unresizable = false

	janela.always_on_top = false

	janela.transparent = true

	janela.maximize_disabled = false

	janela.borderless = false


	# ============================================================
	# FECHAR
	# ============================================================

	janela.close_requested.connect(
		func():
			janela.queue_free()
	)


	# ============================================================
	# POSIÇÃO
	# ============================================================

	var tela := DisplayServer.screen_get_usable_rect()

	janela.position = Vector2i(
		tela.position.x,
		tela.position.y
		+ (tela.size.y - janela.size.y) / 2
	)


	# ============================================================
	# CARREGA A CENA
	# ============================================================

	var packed_scene := load(cena) as PackedScene


	if packed_scene:

		var instancia := packed_scene.instantiate()


		# --------------------------------------------------------
		# Passa o dicionário para a cena
		# --------------------------------------------------------

		instancia.dados = dados


		janela.add_child(
			instancia
		)

	else:

		push_error(
			"Não foi possível carregar a cena: "
			+ cena
		)


	# ============================================================
	# MOSTRA
	# ============================================================

	add_child(
		janela
	)

	janela.show()


	return janela


func diana_aleatoria():
	var n = 1
	
	match n:
		1:
			cliente.chat("O usuário não interagiu com vc")
		_:
			print("tédio")
	
	pass
