extends Control

@onready var frog = %FrogIdle
@onready var frog_position_label = %Position

@onready var save_01 = %Save01
@onready var load_01 = %Load01
@onready var save_03 = %Save03
@onready var load_03 = %Load03

var sfx_is_on = true
var bgm_is_on = true

var click_count = 0

const SAVE_PATH = "user://savedata.json"

# ─── Versiones ───────────────────────────────────────────────
const VERSION_01 = 0.1
const VERSION_03 = 0.3

# Proceso principal (con tu solución del GameArea)
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("Click"):
		# Tu solución: solo permite clics en el área de juego
		var mouse_pos = get_global_mouse_position()
		var game_area = $HBoxContainer/GamePanel  # El nodo Control que cubre el área jugable
		if game_area.get_global_rect().has_point(mouse_pos):
			frog.global_position = mouse_pos
			if sfx_is_on:
				$Game/FrogIdle/SFX.play()
			click_count += 1

	frog_position_label.text = "X: " + str(snappedi(frog.global_position.x, 1)) \
							+ "  Y: " + str(snappedi(frog.global_position.y, 1))
	%Score.text = "SCORE: " + str(int(click_count))

# ─── Botones de audio ───────────────────────────────────────
func _on_sfx_button_toggled(toggled_on: bool) -> void:
	sfx_is_on = toggled_on

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	bgm_is_on = toggled_on
	if has_node("Game/BGM"):
		$Game/BGM.stream_paused = !bgm_is_on

# ─── Clear data ─────────────────────────────────────────────
func _on_clear_data_pressed() -> void:
	click_count = 0

# ════════════════════════════════════════════════════════════
#  VERSIÓN 0.1 - Guarda: versión + BGM
# ════════════════════════════════════════════════════════════
func _on_save_01_pressed() -> void:
	var data = {
		"version": VERSION_01,
		"bgm_state": bgm_is_on
	}
	_write_json(data)
	print("[Save v0.1] Guardado: ", data)

func _on_load_01_pressed() -> void:
	var data = _read_json()
	if data == null:
		push_error("[Load v0.1] No se encontró archivo de guardado.")
		return

	var file_version = float(data.get("version", 0.0))

	# v0.1 NO puede cargar una versión superior
	if file_version > VERSION_01:
		push_error("[Load v0.1] Error: el archivo es de versión %.1f, esta versión (%.1f) no puede cargarlo." \
				% [file_version, VERSION_01])
		return

	# Cargar datos
	bgm_is_on = data.get("bgm_state", true)
	if has_node("Game/BGM"):
		$Game/BGM.stream_paused = !bgm_is_on
	
	print("[Load v0.1] Cargado correctamente (v%.1f)" % file_version)

# ════════════════════════════════════════════════════════════
#  VERSIÓN 0.3 - Guarda: versión + BGM + SFX + score + posición
# ════════════════════════════════════════════════════════════
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
	print("[Save v0.3] Guardado: ", data)

func _on_load_03_pressed() -> void:
	var data = _read_json()
	if data == null:
		push_error("[Load v0.3] No se encontró archivo de guardado.")
		return

	var file_version = float(data.get("version", 0.0))

	# Datos que existen en todas las versiones (compatibilidad base)
	bgm_is_on = data.get("bgm_state", true)
	if has_node("Game/BGM"):
		$Game/BGM.stream_paused = !bgm_is_on

	# Manejo de versiones inferiores (retrocompatibilidad)
	if file_version < VERSION_03:
		print("[Load v0.3] Archivo de versión inferior (%.1f). Resolviendo datos faltantes..." \
				% file_version)
		
		# Valores por defecto para datos que no existían en v0.1
		sfx_is_on = true                    # SFX activado por defecto
		click_count = 0                     # Score empieza en 0
		# La posición de la rana NO se modifica (se queda donde está)
	else:
		# Versión igual o superior: cargar todos los datos
		sfx_is_on = data.get("sfx_state", true)
		click_count = data.get("score", 0)
		var fx = data.get("frog_x", frog.global_position.x)
		var fy = data.get("frog_y", frog.global_position.y)
		frog.global_position = Vector2(fx, fy)
	
	# Sincronizar UI del botón SFX (si existe)
	var sfx_button = get_node_or_null("%SfxButton")
	if sfx_button and sfx_button is BaseButton:
		sfx_button.button_pressed = sfx_is_on
	
	print("[Load v0.3] Cargado correctamente (v%.1f)" % file_version)

# ════════════════════════════════════════════════════════════
#  Helpers de I/O
# ════════════════════════════════════════════════════════════
func _write_json(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo abrir el archivo para escribir: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

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
