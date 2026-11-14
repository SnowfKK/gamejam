extends Node2D

@onready var levelroot: Node2D = $levelroot

var level:int = 1

var exit = %levelroot.get_node_or_null(exit)
if exit:
	exit.body_entered.connect(_on_exit_body_entered)

func _on_exit_body_entered(body: Node2D) -> void
print(body)
