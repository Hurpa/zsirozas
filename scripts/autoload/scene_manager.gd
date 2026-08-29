extends Node
## Autoload singleton: a jelenetek (főmenü / játék / eredmény) közti
## váltásért felel, és átadja az eredményt a leosztás végén.

const MAIN_MENU := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://scenes/game.tscn"
const RESULT_SCENE := "res://scenes/result_screen.tscn"

var last_result: Dictionary = {}

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)

func go_to_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func go_to_result(result: Dictionary) -> void:
	last_result = result
	get_tree().change_scene_to_file(RESULT_SCENE)
