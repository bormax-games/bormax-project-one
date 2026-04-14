extends Node3D

@onready var players: Node3D = $Players
@onready var items: Node3D = $Items
@onready var status_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var help_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/HelpLabel

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 7777

func _ready() -> void:
	_ensure_test_inputs()
	Net.configure(self, players, items)
	Net.status_changed.connect(_on_net_status_changed)
	help_label.text = "F1 = host | F2 = join 127.0.0.1 | Esc = stop | WASD move | Space jump | E pickup"
	status_label.text = "Ready"

	var args := OS.get_cmdline_user_args()
	if "--server" in args:
		Net.host(DEFAULT_PORT)
	elif "--client" in args:
		var host_ip := DEFAULT_IP
		for i in args.size():
			if args[i] == "--ip" and i + 1 < args.size():
				host_ip = args[i + 1]
		Net.join(host_ip, DEFAULT_PORT)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			Net.host(DEFAULT_PORT)
		elif event.keycode == KEY_F2:
			Net.join(DEFAULT_IP, DEFAULT_PORT)
		elif event.keycode == KEY_ESCAPE:
			Net.stop()


func _on_net_status_changed(message: String) -> void:
	status_label.text = message


func _ensure_test_inputs() -> void:
	if not InputMap.has_action("ui_cancel"):
		InputMap.add_action("ui_cancel")
