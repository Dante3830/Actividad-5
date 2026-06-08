extends Control

# Rana
@onready var frog = %FrogIdle
@onready var frog_position_label = %Position

# Botones de guardado y cargado
@onready var save_01 = %Save01
@onready var load_01 = %Load01
@onready var save_03 = %Save03
@onready var load_03 = %Load03

@onready var save_text = %SaveText

# Botones de sonido y música
@onready var sfx_button = %SFXButton
@onready var bgm_button = %BGMButton
var sfx_is_on = true
var bgm_is_on = true

# Contador de clicks (score)
var click_count = 0

# Versiones
const VERSION_01 = 0.1
const VERSION_03 = 0.3

# Archivo de guardado JSON
const SAVE_PATH = "user://savedata.json"

# Sincronizar la UI con la música y audio
func _sync_audio_ui() -> void:
	if sfx_button and sfx_button is BaseButton:
		sfx_button.button_pressed = sfx_is_on
	
	if bgm_button and bgm_button is BaseButton:
		bgm_button.button_pressed = bgm_is_on
	
	if has_node("Game/BGM"):
		$Game/BGM.stream_paused = !bgm_is_on

# Cambiar color si el mensaje es de error o de carga exitosa
func _show_message(text: String, is_error: bool = false) -> void:
	save_text.text = text
	if is_error:
		save_text.add_theme_color_override("font_color", Color(1, 0.0, 0.0))
		push_error(text)
	else:
		save_text.add_theme_color_override("font_color", Color(0.0, 1, 0.0))
		print(text)
	
	await get_tree().create_timer(5.0).timeout
	if save_text.text == text:
		save_text.text = ""

# Juego clicker principal
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("Click"):
		var mouse_pos = get_global_mouse_position()
		var game_area = $HBoxContainer/GamePanel
		if game_area.get_global_rect().has_point(mouse_pos):
			frog.global_position = mouse_pos
			if sfx_is_on:
				$Game/FrogIdle/SFX.play()
			click_count += 1
	
	frog_position_label.text = "X: " + str(snappedi(frog.global_position.x, 1)) \
							+ "  Y: " + str(snappedi(frog.global_position.y, 1))
	%Score.text = "SCORE: " + str(int(click_count))

# Botones de audio y música
func _on_sfx_button_toggled(toggled_on: bool) -> void:
	sfx_is_on = toggled_on

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	bgm_is_on = toggled_on
	if has_node("Game/BGM"):
		$Game/BGM.stream_paused = !bgm_is_on

# Clear data
func _on_clear_data_pressed() -> void:
	click_count = 0
	_show_message("Datos borrados", true)

# VERSIÓN 0.1 - Guarda versión, música y score
func _on_save_01_pressed() -> void:
	var data = {
		"version": VERSION_01,
		"bgm_state": bgm_is_on,
		"score": click_count
	}
	_write_json(data)
	_show_message("Partida versión 0.1 guardada exitosamente", false)

func _on_load_01_pressed() -> void:
	var data = _read_json()
	if data == null:
		_show_message("ERROR: No se encontró archivo de guardado.", true)
		return
	
	var file_version = float(data.get("version", 0.0))
	
	if file_version > VERSION_01:
		_show_message("ERROR: No puedes cargar una versión superior a 0.1", true)
		return
	
	# Cargar datos
	bgm_is_on = data.get("bgm_state", true)
	
	click_count = data.get("score", true)
	
	_sync_audio_ui()
	
	_show_message("Partida versión 0.1 cargada exitosamente", false)

# VERSIÓN 0.3 - Guarda versión, música, sonido, score y posición
func _on_save_03_pressed() -> void:
	var data = {
		"version": VERSION_03,
		"bgm_state": bgm_is_on,
		"sfx_state": sfx_is_on,
		"score": click_count,
		"frog_x": frog.global_position.x,
		"frog_y": frog.global_position.y
	}
	_write_json(data)
	_show_message("Partida versión 0.3 guardada exitosamente", false)

func _on_load_03_pressed() -> void:
	var data = _read_json()
	if data == null:
		_show_message("ERROR: No se encontró archivo de guardado.", true)
		return
	
	var file_version = float(data.get("version", 0.0))
	
	# Datos base (ambas versiones)
	bgm_is_on = data.get("bgm_state", true)
	
	if file_version < VERSION_03:
		# Valores predeterminados para los datos que no existían en la versión 0.1
		sfx_is_on = true
		click_count = 0
		_show_message("Partida versión 0.1 cargada exitosamente", false)
	else:
		# Versión 0.3: cargar TODOS los datos
		sfx_is_on = data.get("sfx_state", true)
		click_count = data.get("score", 0)
		var fx = data.get("frog_x", frog.global_position.x)
		var fy = data.get("frog_y", frog.global_position.y)
		frog.global_position = Vector2(fx, fy)
		
		_show_message("Partida versión 0.3 cargada exitosamente", false)
	
	_sync_audio_ui()

# Guardar partida en JSON
func _write_json(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_show_message("ERROR: No se pudo guardar la partida.", true)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# Cargar partida escrita en JSON
func _read_json() -> Variant:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return null
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Error al parsear el JSON del archivo de guardado.")
	return parsed
