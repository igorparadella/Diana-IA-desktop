extends Node3D

# ============================================================
# BLEND SHAPES
# ============================================================
# ID:0  | Fcl_ALL_Neutral
# ID:1  | Fcl_ALL_Angry
# ID:2  | Fcl_ALL_Fun
# ID:3  | Fcl_ALL_Joy
# ID:4  | Fcl_ALL_Sorrow
# ID:5  | Fcl_ALL_Surprised
# ID:6  | Fcl_BRW_Angry
# ID:7  | Fcl_BRW_Fun
# ID:8  | Fcl_BRW_Joy
# ID:9  | Fcl_BRW_Sorrow
# ID:10 | Fcl_BRW_Surprised
# ID:11 | Fcl_EYE_Natural
# ID:12 | Fcl_EYE_Angry
# ID:13 | Fcl_EYE_Close
# ID:14 | Fcl_EYE_Close_R
# ID:15 | Fcl_EYE_Close_L
# ID:16 | Fcl_EYE_Fun
# ID:17 | Fcl_EYE_Joy
# ID:18 | Fcl_EYE_Joy_R
# ID:19 | Fcl_EYE_Joy_L
# ID:20 | Fcl_EYE_Sorrow
# ID:21 | Fcl_EYE_Surprised
# ID:22 | Fcl_EYE_Spread
# ID:23 | Fcl_EYE_Iris_Hide
# ID:24 | Fcl_EYE_Highlight_Hide
# ID:25 | Fcl_MTH_Close
# ID:26 | Fcl_MTH_Up
# ID:27 | Fcl_MTH_Down
# ID:28 | Fcl_MTH_Angry
# ID:29 | Fcl_MTH_Small
# ID:30 | Fcl_MTH_Large
# ID:31 | Fcl_MTH_Neutral
# ID:32 | Fcl_MTH_Fun
# ID:33 | Fcl_MTH_Joy
# ID:34 | Fcl_MTH_Sorrow
# ID:35 | Fcl_MTH_Surprised
# ID:36 | Fcl_MTH_SkinFung
# ID:37 | Fcl_MTH_SkinFung_R
# ID:38 | Fcl_MTH_SkinFung_L
# ID:39 | Fcl_MTH_A
# ID:40 | Fcl_MTH_I
# ID:41 | Fcl_MTH_U
# ID:42 | Fcl_MTH_E
# ID:43 | Fcl_MTH_O
# ID:44 | Fcl_HA_Hide
# ID:45 | Fcl_HA_Fung1
# ID:46 | Fcl_HA_Fung1_Low
# ID:47 | Fcl_HA_Fung1_Up
# ID:48 | Fcl_HA_Fung2
# ID:49 | Fcl_HA_Fung2_Low
# ID:50 | Fcl_HA_Fung2_Up
# ID:51 | Fcl_HA_Fung3
# ID:52 | Fcl_HA_Fung3_Up
# ID:53 | Fcl_HA_Fung3_Low
# ID:54 | Fcl_HA_Short
# ID:55 | Fcl_HA_Short_Up
# ID:56 | Fcl_HA_Short_Low


# ============================================================
# NÓS
# ============================================================

@onready var face: MeshInstance3D = $Armature/Skeleton3D/Face
@onready var timer: Timer = $Armature/Timer


# ============================================================
# OLHOS
# ============================================================

const EYE_CLOSE := 13


# ============================================================
# BOCA
# ============================================================

const MOUTH_A := 39
const MOUTH_I := 40
const MOUTH_U := 41
const MOUTH_E := 42
const MOUTH_O := 43


# ============================================================
# EXPRESSÕES
# ============================================================

const exprecoes = {
	"brava": 1,
	"divertida": 2,
	"alegre": 3,
	"triste": 4,
	"supresa": 5,
}


# ============================================================
# CONFIGURAÇÕES DA BOCA
# ============================================================

@export_category("Lip Sync")

# Multiplica a intensidade do áudio.
@export var intensidade_boca: float = 8.0

# Velocidade com que a boca acompanha o áudio.
@export var velocidade_boca: float = 15.0

# Quanto de áudio é necessário para começar a abrir a boca.
@export var limite_boca: float = 0.02

# ============================================================
# CONFIGURAÇÕES DAS EXPRESSÕES
# ============================================================

@export_category("Expressões")

@export var velocidade_transicao: float = 0.5


# ============================================================
# ÁUDIO
# ============================================================

var voz: AudioStreamPlayer


# ============================================================
# READY
# ============================================================
@onready var animation_player_2: AnimationPlayer = $Armature/AnimationPlayer2

func _ready() -> void:
	randomize()

	timer.wait_time = randf_range(2.0, 5.0)
	timer.start()
	GlobalManager.diana = self
	await get_tree().process_frame
	inicio() 


func inicio():
	voz = GlobalManager.voz
	animation_player_2.play("ola")
	voz.play()
	await animation_player_2.animation_finished
	animation_player_2.play("idle")

# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	# Se ainda não temos o áudio, tenta pegar novamente
	if voz == null:
		voz = GlobalManager.voz
		return

	# Faz a boca acompanhar a voz
	processar_boca(delta)


# ============================================================
# LIP SYNC
# ============================================================

func processar_boca(delta: float) -> void:

	# Se a voz não está tocando,
	# fecha a boca suavemente.
	if voz == null or not voz.playing:
		fechar_boca(delta)
		return


	# ========================================================
	# PEGA O ÍNDICE DO AUDIO BUS
	# ========================================================

	var indice_bus := AudioServer.get_bus_index(voz.bus)

	if indice_bus == -1:
		fechar_boca(delta)
		return


	# ========================================================
	# PEGA O VOLUME
	# ========================================================

	var volume_db := AudioServer.get_bus_peak_volume_left_db(
		indice_bus,
		0
	)


	# Converte dB para valor linear
	var volume := db_to_linear(volume_db)


	# Amplifica
	var abertura := volume * intensidade_boca


	# Limita entre 0 e 1
	abertura = clamp(abertura, 0.0, 1.0)


	# Pequenos ruídos ficam como boca fechada
	if abertura < limite_boca:
		abertura = 0.0


	# ========================================================
	# FORMAS DA BOCA
	# ========================================================

	var alvo_a := 0.0
	var alvo_i := 0.0
	var alvo_u := 0.0
	var alvo_e := 0.0
	var alvo_o := 0.0


	# Alterna os formatos para não ficar
	# sempre com a boca em A.
	var tempo := Time.get_ticks_msec() / 100.0
	var escolha := int(tempo) % 5


	match escolha:

		0:
			alvo_a = abertura

		1:
			alvo_i = abertura

		2:
			alvo_u = abertura

		3:
			alvo_e = abertura

		4:
			alvo_o = abertura


	# ========================================================
	# TRANSIÇÃO
	# ========================================================

	var velocidade = clamp(
		velocidade_boca * delta,
		0.0,
		1.0
	)


	face.set_blend_shape_value(
		MOUTH_A,
		lerp(
			face.get_blend_shape_value(MOUTH_A),
			alvo_a,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_I,
		lerp(
			face.get_blend_shape_value(MOUTH_I),
			alvo_i,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_U,
		lerp(
			face.get_blend_shape_value(MOUTH_U),
			alvo_u,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_E,
		lerp(
			face.get_blend_shape_value(MOUTH_E),
			alvo_e,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_O,
		lerp(
			face.get_blend_shape_value(MOUTH_O),
			alvo_o,
			velocidade
		)
	)

# ============================================================
# FECHAR BOCA
# ============================================================

func fechar_boca(delta: float) -> void:

	var velocidade = velocidade_boca * delta

	face.set_blend_shape_value(
		MOUTH_A,
		lerp(
			face.get_blend_shape_value(MOUTH_A),
			0.0,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_I,
		lerp(
			face.get_blend_shape_value(MOUTH_I),
			0.0,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_U,
		lerp(
			face.get_blend_shape_value(MOUTH_U),
			0.0,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_E,
		lerp(
			face.get_blend_shape_value(MOUTH_E),
			0.0,
			velocidade
		)
	)

	face.set_blend_shape_value(
		MOUTH_O,
		lerp(
			face.get_blend_shape_value(MOUTH_O),
			0.0,
			velocidade
		))


# ============================================================
# PISCAR
# ============================================================

func _on_timer_timeout() -> void:

	await piscar()

	timer.wait_time = randf_range(2.0, 5.0)
	timer.start()


func piscar() -> void:

	# Fecha suavemente
	for i in range(6):

		face.set_blend_shape_value(
			EYE_CLOSE,
			i / 5.0
		)

		await get_tree().create_timer(0.01).timeout


	# Mantém fechado
	await get_tree().create_timer(0.05).timeout


	# Abre suavemente
	for i in range(5, -1, -1):

		face.set_blend_shape_value(
			EYE_CLOSE,
			i / 5.0
		)

		await get_tree().create_timer(0.01).timeout


# ============================================================
# EXPRESSÕES
# ============================================================

func exprecao(nome: String, velocidade: float = 0.0):

	if velocidade != 0.0:
		velocidade_transicao = velocidade


	# ========================================================
	# VOLTAR PARA NEUTRA
	# ========================================================

	if nome == "neutra":

		var tween := create_tween()

		for i in exprecoes:

			var id = exprecoes[i]

			tween.parallel().tween_method(
				func(v):
					face.set_blend_shape_value(id, v),
				face.get_blend_shape_value(id),
				0.0,
				velocidade_transicao
			)

		return


	# ========================================================
	# EXPRESSÃO
	# ========================================================

	if not exprecoes.has(nome):
		push_warning("Expressão não encontrada: " + nome)
		return


	var id = exprecoes[nome]

	var tween := create_tween()

	tween.tween_method(
		func(v):
			face.set_blend_shape_value(id, v),
		face.get_blend_shape_value(id),
		1.0,
		velocidade_transicao
	)



@onready var celular: Node3D = $Armature/Skeleton3D/BoneAttachment3D/celular


var fazendo = ""

func tedio(oque):
	if fazendo != oque:
		match fazendo:
			"celular":
				animation_player_2.play_backwards("pegar_celular")
				await animation_player_2.animation_finished
				animation_player_2.play("idle")
				celular.visible = false
				
	fazendo = oque
	match oque:
		"celular":
			celular.visible = true
			animation_player_2.play("pegar_celular")
			await animation_player_2.animation_finished
			animation_player_2.play("mecher_no_celular")
		
		"idle":
			animation_player_2.play("idle")
		
