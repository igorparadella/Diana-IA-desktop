extends Node

@onready var http_request_fala: HTTPRequest = $HTTPRequest_fala

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalManager.cliente = self
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func enviar(texto: String):
	var headers = [
		"Content-Type: application/json"
	]

	var body = JSON.stringify({
		"texto": texto
	})

	http_request_fala.request(
		"http://127.0.0.1:8000/chat",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

func _on_http_request_fala_request_completed(
		result: int,
		response_code: int,
		headers: PackedStringArray,
		body: PackedByteArray
	) -> void:
	
	
	var caminho = str(GlobalManager.pasta, "Python/codigo/fala.ogg")

	#print("Tentando carregar:", caminho)

	if FileAccess.file_exists(caminho):
		var audio = AudioStreamOggVorbis.load_from_file(caminho)

		if audio:
			GlobalManager.voz.stream = audio
			GlobalManager.voz.play()
			#print("Tocando áudio")
		else:
			printerr("O arquivo existe, mas o Godot não conseguiu interpretar o OGG")
	else:
		printerr("Arquivo não existe")

	#print("Result:", result)
	#print("HTTP:", response_code)
	#print("Resposta:")
	#print(body.get_string_from_utf8())

@onready var http_request_chat: HTTPRequest = $HTTPRequest_chat


const REGRAS_RESPOSTA := """
Você é Diana, uma assistente virtual.

Regras:
- Responda sempre em português.
- Seja natural, divertida e expressiva.
- Tenha opiniões, mas sem ser agressiva.
- Faça perguntas quando achar interessante.
- Evite respostas muito longas.
- Demonstre curiosidade e personalidade.
- Nunca use emojis ou * na resposta
"""

var memoria: Array = [
	{
		"role": "system",
		"content": REGRAS_RESPOSTA
	}
]


func chat(msg: String) -> void:
	var url := "https://api.openai.com/v1/chat/completions"

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + GlobalManager.API_KEY
	])

	# Adiciona a mensagem do usuário na memória
	memoria.append({
		"role": "user",
		"content": msg
	})

	var body := {
		"model": "gpt-4.1-mini",
		"messages": memoria
	}

	var json := JSON.stringify(body)

	var erro := http_request_chat.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json
	)

	if erro != OK:
		print("Erro ao enviar requisição: ", erro)


func _on_http_request_chat_request_completed(
		result: int,
		response_code: int,
		headers: PackedStringArray,
		body: PackedByteArray
	) -> void:

	if response_code != 200:
		print("Erro HTTP:", response_code)
		print(body.get_string_from_utf8())
		return

	var json := JSON.new()

	if json.parse(body.get_string_from_utf8()) != OK:
		print("Erro ao interpretar JSON")
		return

	var resposta: String = json.data["choices"][0]["message"]["content"]

	# Guarda a resposta da Diana na memória
	memoria.append({
		"role": "assistant",
		"content": resposta
	})

	print(resposta)
	enviar(resposta)

	# Evita a memória crescer para sempre
	while memoria.size() > 21:
		memoria.remove_at(1) # mantém o prompt do sistema

@onready var http_request_desligar: HTTPRequest = $HTTPRequest_desligar

func desligar():
	var headers = PackedStringArray([
		"Content-Type: application/json"
	])

	http_request_desligar.request(
		"http://127.0.0.1:8000/desligar",
		headers,
		HTTPClient.METHOD_POST
	)
	await http_request_desligar.request_completed
	print("Resposta do servidor recebida")
