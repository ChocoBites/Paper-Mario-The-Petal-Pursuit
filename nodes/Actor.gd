extends Spatial

onready var billboard: YBillboard = $YBillboard

func _process(delta) -> void:
	var facing_forward = abs(billboard.rotation_degrees.y) < 90

	if facing_forward:
		$YBillboard/Sprite.modulate = Color(1, 1, 1)
	else:
		$YBillboard/Sprite.modulate = Color(0, 0, 0)
