extends Node


# ============================================================
# HTTP - FALA
# ============================================================

@onready var http_request_fala: HTTPRequest = $HTTPRequest_fala


# ============================================================
# HTTP - CHAT
# ============================================================

@onready var http_request_chat: HTTPRequest = $HTTPRequest_chat


# ============================================================
# HTTP - DESLIGAR
# ============================================================

@onready var http_request_desligar: HTTPRequest = $HTTPRequest_desligar


# ============================================================
# MEMÓRIA PERSISTENTE
# ============================================================

const CAMINHO_MEMORIA := "user://memoria_diana.json"

var memoria_persistente: Dictionary = {}


# ============================================================
# REGRAS DA DIANA
# ============================================================

const REGRAS_RESPOSTA := """
Você é Diana, uma assistente virtual com personalidade própria.
Seja levemente sarcastica e divertida

Suas repostas devem seguir a seguinte estrurta:
<fala>o texto vira para o usuario</fala>
<codigo>o codigo que vc criou e que quer apresentar para o usário</codigo>
<memoria>serve para guardar infromções para futuras conversas</memoria> use se quiser salvar algo
<fazendo>serve para que vc possa manter um objetivo</fazendo>
<humor>escolha um opção entre: neutra,brava,divertida,alegre,triste ou supresa</humor> isso vai mudar a expreção facial do seu avatar
"""
# ============================================================
# MEMÓRIA DA CONVERSA
# ============================================================

var memoria: Array = []


# ============================================================
# CONTADOR DE MEMÓRIA
# ============================================================

var proxima_memoria_id: int = 1


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	GlobalManager.cliente = self

	# --------------------------------------------------------
	# Carrega a memória persistente
	# --------------------------------------------------------

	carregar_memoria()

	# --------------------------------------------------------
	# Descobre o próximo ID disponível
	# --------------------------------------------------------

	atualizar_proximo_id()

	# --------------------------------------------------------
	# Cria a memória da conversa
	# --------------------------------------------------------

	memoria = [
		{
			"role": "system",
			"content": REGRAS_RESPOSTA
		}
	]

	print("Diana iniciada.")
	print("Memória persistente: ", memoria_persistente)


# ============================================================
# MEMÓRIA PERSISTENTE
# ============================================================


# ------------------------------------------------------------
# SALVAR UMA MEMÓRIA
#
# Recebe somente o texto que deve ser lembrado.
#
# Exemplo:
#
# salvar_memoria("O usuário está desenvolvendo a Diana.")
# ------------------------------------------------------------
const LIMITE_MEMORIAS := 100


func salvar_memoria(texto: String) -> bool:

	texto = texto.strip_edges()

	if texto.is_empty():
		print("Memória vazia. Nada para salvar.")
		return false


	# ============================================================
	# CRIA UMA NOVA CHAVE
	# ============================================================

	var chave := "memoria_" + str(proxima_memoria_id)

	proxima_memoria_id += 1


	# ============================================================
	# ADICIONA A MEMÓRIA
	# ============================================================

	memoria_persistente[chave] = texto


	# ============================================================
	# LIMITA A 100 MEMÓRIAS
	#
	# Se passar de 100, remove a mais antiga.
	# ============================================================

	while memoria_persistente.size() > LIMITE_MEMORIAS:

		var chaves := memoria_persistente.keys()

		if chaves.is_empty():
			break

		var chave_antiga = chaves[0]

		memoria_persistente.erase(
			chave_antiga
		)

		print(
			"Memória antiga removida: ",
			chave_antiga
		)


	# ============================================================
	# SALVA NO JSON
	# ============================================================

	var file := FileAccess.open(
		CAMINHO_MEMORIA,
		FileAccess.WRITE
	)

	if file == null:

		printerr(
			"Não foi possível abrir o arquivo de memória para escrita."
		)

		# Remove a memória caso o arquivo não possa ser salvo
		memoria_persistente.erase(chave)

		return false


	file.store_string(
		JSON.stringify(
			memoria_persistente,
			"\t"
		)
	)

	file.close()


	print("Memória salva com sucesso!")
	print("Chave: ", chave)
	print("Texto: ", texto)
	print(
		"Total de memórias: ",
		memoria_persistente.size(),
		"/",
		LIMITE_MEMORIAS
	)

	return true

# ------------------------------------------------------------
# ATUALIZAR PRÓXIMO ID
# ------------------------------------------------------------

func atualizar_proximo_id() -> void:

	var maior_id := 0

	for chave in memoria_persistente.keys():

		var texto_chave := str(chave)

		if not texto_chave.begins_with("memoria_"):
			continue

		var numero_texto := texto_chave.trim_prefix("memoria_")

		if numero_texto.is_valid_int():

			var numero := int(numero_texto)

			if numero > maior_id:
				maior_id = numero

	proxima_memoria_id = maior_id + 1


# ------------------------------------------------------------
# CARREGAR MEMÓRIA
# ------------------------------------------------------------

func carregar_memoria() -> void:

	if not FileAccess.file_exists(CAMINHO_MEMORIA):

		print("Arquivo de memória ainda não existe.")

		memoria_persistente = {}

		return


	var file := FileAccess.open(
		CAMINHO_MEMORIA,
		FileAccess.READ
	)

	if file == null:

		printerr(
			"Não foi possível abrir o arquivo de memória."
		)

		memoria_persistente = {}

		return


	var texto := file.get_as_text()

	file.close()


	if texto.is_empty():

		memoria_persistente = {}

		return


	var dados = JSON.parse_string(texto)


	if dados is Dictionary:

		memoria_persistente = dados

		print("Memória persistente carregada.")

	else:

		printerr(
			"O arquivo de memória possui um JSON inválido."
		)

		memoria_persistente = {}


# ------------------------------------------------------------
# PEGAR UMA MEMÓRIA
# ------------------------------------------------------------

func obter_memoria(
	chave: String,
	valor_padrao = null
):

	if memoria_persistente.has(chave):

		return memoria_persistente[chave]

	return valor_padrao


# ------------------------------------------------------------
# REMOVER UMA MEMÓRIA
# ------------------------------------------------------------

func remover_memoria(chave: String) -> bool:

	if not memoria_persistente.has(chave):

		return false

	memoria_persistente.erase(chave)

	return salvar_todas_memorias()


# ------------------------------------------------------------
# SALVAR TODA A MEMÓRIA ATUAL
# ------------------------------------------------------------

func salvar_todas_memorias() -> bool:

	var file := FileAccess.open(
		CAMINHO_MEMORIA,
		FileAccess.WRITE
	)

	if file == null:

		printerr(
			"Não foi possível salvar a memória."
		)

		return false


	file.store_string(
		JSON.stringify(
			memoria_persistente,
			"\t"
		)
	)

	file.close()

	print("Memória persistente salva.")

	return true


# ------------------------------------------------------------
# LIMPAR TODA A MEMÓRIA
# ------------------------------------------------------------

func limpar_memoria_persistente() -> bool:

	memoria_persistente.clear()

	proxima_memoria_id = 1

	return salvar_todas_memorias()


# ============================================================
# CONVERTER MEMÓRIA PARA A DIANA
# ============================================================

func obter_memoria_para_diana() -> String:

	if memoria_persistente.is_empty():

		return "Nenhuma memória persistente foi registrada."


	return JSON.stringify(
		memoria_persistente,
		"\t"
	)


# ============================================================
# ENVIAR FALA PARA O SERVIDOR PYTHON
# ============================================================

func enviar(texto: String):

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var body := JSON.stringify({
		"texto": texto
	})

	http_request_fala.request(
		"http://127.0.0.1:8000/chat",
		headers,
		HTTPClient.METHOD_POST,
		body
	)


# ============================================================
# RESPOSTA DO SERVIDOR DE FALA
# ============================================================

func _on_http_request_fala_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	var caminho := str(
		GlobalManager.pasta,
		"Python/codigo/fala.ogg"
	)

	if FileAccess.file_exists(caminho):

		var audio := AudioStreamOggVorbis.load_from_file(caminho)

		if audio:

			GlobalManager.voz.stream = audio
			GlobalManager.voz.play()

		else:

			printerr(
				"O arquivo existe, mas o Godot não conseguiu interpretar o OGG."
			)

	else:

		printerr(
			"Arquivo não existe: ",
			caminho
		)


# ============================================================
# CHAT
# ============================================================

func chat(msg: String) -> void:

	var url := "https://api.openai.com/v1/chat/completions"

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + GlobalManager.API_KEY
	])


	# --------------------------------------------------------
	# MEMÓRIA PERSISTENTE
	# --------------------------------------------------------

	var memoria_texto := obter_memoria_para_diana()


	# --------------------------------------------------------
	# SYSTEM PROMPT + MEMÓRIA
	# --------------------------------------------------------

	var sistema_com_memoria := REGRAS_RESPOSTA + """

MEMÓRIA PERSISTENTE DA DIANA:

As informações abaixo foram salvas anteriormente.
Considere-as quando forem relevantes para responder.
Não invente informações que não estejam aqui.

""" + memoria_texto


	# --------------------------------------------------------
	# Atualiza o system prompt
	# --------------------------------------------------------

	memoria[0] = {
		"role": "system",
		"content": sistema_com_memoria
	}


	# --------------------------------------------------------
	# Adiciona mensagem do usuário
	# --------------------------------------------------------

	memoria.append({
		"role": "user",
		"content": msg
	})


	# --------------------------------------------------------
	# BODY
	# --------------------------------------------------------

	var body := {
		"model": "gpt-4.1-mini",
		"messages": memoria
	}


	var json := JSON.stringify(body)


	# --------------------------------------------------------
	# REQUISIÇÃO
	# --------------------------------------------------------

	var erro := http_request_chat.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json
	)


	if erro != OK:

		print(
			"Erro ao enviar requisição: ",
			erro
		)


# ============================================================
# RESPOSTA DO CHAT
# ============================================================

func _on_http_request_chat_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	if response_code != 200:

		print(
			"Erro HTTP: ",
			response_code
		)

		print(
			body.get_string_from_utf8()
		)

		return


	var json := JSON.new()


	if json.parse(
		body.get_string_from_utf8()
	) != OK:

		print(
			"Erro ao interpretar JSON."
		)

		return


	var resposta: String = json.data[
		"choices"
	][0][
		"message"
	][
	"content"
	]


	# --------------------------------------------------------
	# Guarda resposta na memória temporária
	# --------------------------------------------------------

	memoria.append({
		"role": "assistant",
		"content": resposta
	})


	print(resposta)


	# --------------------------------------------------------
	# Processa <fala>, <codigo> e <memoria>
	# --------------------------------------------------------

	GlobalManager.processar_resposta(
		resposta
	)


	# --------------------------------------------------------
	# Limita memória da conversa
	#
	# Mantém o system prompt.
	# --------------------------------------------------------

	while memoria.size() > 21:

		memoria.remove_at(1)


# ============================================================
# DESLIGAR SERVIDOR
# ============================================================

func desligar():

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	http_request_desligar.request(
		"http://127.0.0.1:8000/desligar",
		headers,
		HTTPClient.METHOD_POST
	)

	await http_request_desligar.request_completed

	print(
		"Resposta do servidor recebida."
	)
