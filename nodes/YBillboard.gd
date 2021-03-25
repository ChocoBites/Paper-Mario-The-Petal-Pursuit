class_name YBillboard
extends Spatial

export var animate_turn_around = false

var facing_offset = 0.0

func _process(delta) -> void:
	var cam = get_viewport().get_camera()

	if cam:
		var cam_yaw = cam.global_transform.basis.get_euler().y
		var parent_yaw = get_parent().global_transform.basis.get_euler().y
		var rot = cam_yaw - parent_yaw

		if animate_turn_around:
			# angle 0 is negative Z:
			#
			#     0
			# -90 . 90
			#    180
			#
			var deg = rot * (180 / PI)
			var facing_left = deg < 0

			if facing_left:
				facing_offset = lerp(facing_offset, PI, 0.1)
			else:
				facing_offset = lerp(facing_offset, 0, 0.1)

			rotation.y = rot + facing_offset

			# if we are visibly flipped (i.e. animated more than halfway), invert
			# the local z space so components stay in the expected order.
			if facing_offset > PI / 2:
				scale.z = -1
			else:
				scale.z = 1
		else:
			rotation.y = rot
