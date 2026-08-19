extends Node

@onready var skeleton_3d: Skeleton3D = $"../Armature/Skeleton3D"

var head_bone: int
var current_rotation := Vector3.ZERO


func _ready() -> void:
	head_bone = skeleton_3d.find_bone("J_Bip_C_Head")

	if head_bone == -1:
		print("Osso J_Bip_C_Head não encontrado!")


func _process(delta: float) -> void:
	if head_bone == -1:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return


	var mouse_pos := get_viewport().get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)

	var target := ray_origin + ray_direction * 20.0


	var bone_transform := skeleton_3d.get_bone_global_pose(head_bone)
	var head_transform := skeleton_3d.global_transform * bone_transform
	var head_position := head_transform.origin


	var direction := (target - head_position).normalized()


	var rotation := Transform3D().looking_at(
		direction,
		Vector3.UP
	).basis.get_euler()


	# correção dos eixos do modelo
	rotation.x = -rotation.x  # vertical
	rotation.y = -rotation.y  # horizontal


	rotation.x = clamp(rotation.x, deg_to_rad(-25), deg_to_rad(25))
	rotation.y = clamp(rotation.y, deg_to_rad(-50), deg_to_rad(50))


	current_rotation = current_rotation.lerp(
		rotation,
		delta * 5.0
	)


	var pose := skeleton_3d.get_bone_pose(head_bone)

	pose.basis = Basis.from_euler(current_rotation)

	skeleton_3d.set_bone_pose(
		head_bone,
		pose
	)
