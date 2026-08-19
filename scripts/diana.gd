extends Node3D

#=== Blend Shapes ===
#ID:0 | Nome:Fcl_ALL_Neutral | Valor:0.0
#ID:1 | Nome:Fcl_ALL_Angry | Valor:0.0
#ID:2 | Nome:Fcl_ALL_Fun | Valor:0.0
#ID:3 | Nome:Fcl_ALL_Joy | Valor:0.0
#ID:4 | Nome:Fcl_ALL_Sorrow | Valor:0.0
#ID:5 | Nome:Fcl_ALL_Surprised | Valor:0.0
#ID:6 | Nome:Fcl_BRW_Angry | Valor:0.0
#ID:7 | Nome:Fcl_BRW_Fun | Valor:0.0
#ID:8 | Nome:Fcl_BRW_Joy | Valor:0.0
#ID:9 | Nome:Fcl_BRW_Sorrow | Valor:0.0
#ID:10 | Nome:Fcl_BRW_Surprised | Valor:0.0
#ID:11 | Nome:Fcl_EYE_Natural | Valor:0.0
#ID:12 | Nome:Fcl_EYE_Angry | Valor:0.0
#ID:13 | Nome:Fcl_EYE_Close | Valor:0.0
#ID:14 | Nome:Fcl_EYE_Close_R | Valor:0.0
#ID:15 | Nome:Fcl_EYE_Close_L | Valor:0.0
#ID:16 | Nome:Fcl_EYE_Fun | Valor:0.0
#ID:17 | Nome:Fcl_EYE_Joy | Valor:0.0
#ID:18 | Nome:Fcl_EYE_Joy_R | Valor:0.0
#ID:19 | Nome:Fcl_EYE_Joy_L | Valor:0.0
#ID:20 | Nome:Fcl_EYE_Sorrow | Valor:0.0
#ID:21 | Nome:Fcl_EYE_Surprised | Valor:0.0
#ID:22 | Nome:Fcl_EYE_Spread | Valor:0.0
#ID:23 | Nome:Fcl_EYE_Iris_Hide | Valor:0.0
#ID:24 | Nome:Fcl_EYE_Highlight_Hide | Valor:0.0
#ID:25 | Nome:Fcl_MTH_Close | Valor:0.0
#ID:26 | Nome:Fcl_MTH_Up | Valor:0.0
#ID:27 | Nome:Fcl_MTH_Down | Valor:0.0
#ID:28 | Nome:Fcl_MTH_Angry | Valor:0.0
#ID:29 | Nome:Fcl_MTH_Small | Valor:0.0
#ID:30 | Nome:Fcl_MTH_Large | Valor:0.0
#ID:31 | Nome:Fcl_MTH_Neutral | Valor:0.0
#ID:32 | Nome:Fcl_MTH_Fun | Valor:0.0
#ID:33 | Nome:Fcl_MTH_Joy | Valor:0.0
#ID:34 | Nome:Fcl_MTH_Sorrow | Valor:0.0
#ID:35 | Nome:Fcl_MTH_Surprised | Valor:0.0
#ID:36 | Nome:Fcl_MTH_SkinFung | Valor:0.0
#ID:37 | Nome:Fcl_MTH_SkinFung_R | Valor:0.0
#ID:38 | Nome:Fcl_MTH_SkinFung_L | Valor:0.0
#ID:39 | Nome:Fcl_MTH_A | Valor:0.0
#ID:40 | Nome:Fcl_MTH_I | Valor:0.0
#ID:41 | Nome:Fcl_MTH_U | Valor:0.0
#ID:42 | Nome:Fcl_MTH_E | Valor:0.0
#ID:43 | Nome:Fcl_MTH_O | Valor:0.0
#ID:44 | Nome:Fcl_HA_Hide | Valor:0.0
#ID:45 | Nome:Fcl_HA_Fung1 | Valor:0.0
#ID:46 | Nome:Fcl_HA_Fung1_Low | Valor:0.0
#ID:47 | Nome:Fcl_HA_Fung1_Up | Valor:0.0
#ID:48 | Nome:Fcl_HA_Fung2 | Valor:0.0
#ID:49 | Nome:Fcl_HA_Fung2_Low | Valor:0.0
#ID:50 | Nome:Fcl_HA_Fung2_Up | Valor:0.0
#ID:51 | Nome:Fcl_HA_Fung3 | Valor:0.0
#ID:52 | Nome:Fcl_HA_Fung3_Up | Valor:0.0
#ID:53 | Nome:Fcl_HA_Fung3_Low | Valor:0.0
#ID:54 | Nome:Fcl_HA_Short | Valor:0.0
#ID:55 | Nome:Fcl_HA_Short_Up | Valor:0.0
#ID:56 | Nome:Fcl_HA_Short_Low | Valor:0.0


@onready var face: MeshInstance3D = $Armature/Skeleton3D/Face
@onready var timer: Timer = $Armature/Timer

const EYE_CLOSE := 13
const exprecoes = {
	"brava" : 1,
	"divertida" : 2,
	"alegre" : 3,
	"triste" : 4,
	"supresa" : 5,
}

func _ready() -> void:
	randomize()
	timer.wait_time = randf_range(2.0, 5.0)
	timer.start()
	






func _on_timer_timeout() -> void:
	await piscar()

	timer.wait_time = randf_range(2.0, 5.0)
	timer.start()

func piscar() -> void:
	# Fecha suavemente
	for i in range(6):
		face.set_blend_shape_value(EYE_CLOSE, i / 5.0)
		await get_tree().create_timer(0.01).timeout

	# Mantém fechado por um instante
	await get_tree().create_timer(0.05).timeout

	# Abre suavemente
	for i in range(5, -1, -1):
		face.set_blend_shape_value(EYE_CLOSE, i / 5.0)
		await get_tree().create_timer(0.01).timeout

@export var velocidade_transicao: float = 0.5

func exprecao(nome: String, velocidade : float = 0.0):
	if velocidade != 0.0: velocidade_transicao = velocidade
	
	if nome == "neutra":
		var tween = create_tween()

		for i in exprecoes:
			var id = exprecoes[i]
			tween.parallel().tween_method(
				func(v): face.set_blend_shape_value(id, v),
				face.get_blend_shape_value(id),
				0.0,
				velocidade_transicao
			)

		return

	var id = exprecoes[nome]

	var tween = create_tween()
	tween.tween_method(
		func(v): face.set_blend_shape_value(id, v),
		face.get_blend_shape_value(id),
		1.0,
		velocidade_transicao
	)

func falar():
	var A = 39
	var I = 40
	var U = 41
	var E = 42
	var O = 43
	
	
	
	
	pass
