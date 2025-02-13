extends PanelContainer

# The URL to connect to, should be your mud.
var websocket_url = "ws://localhost:40997"

# These are references to controls in the scene
@onready
var label: RichTextLabel = get_node("%ChatLog")
@onready
var chat_input: LineEdit = get_node("%ChatInput")
@onready
var websocket = get_node("WebSocketClient")

func _ready():
	# We connect the various signals
	websocket.connect('connected_to_server', self._connected)
	websocket.connect('connection_closed', self._closed)
	websocket.connect('message_received', self._on_data)
	
	# We attempt to connect and print out the error if we have one.
	var result = websocket.connect_to_url(websocket_url)
	print(result)
	if result != OK:
		print('Could not connect:' + str(result))


func _closed():
	# This emits if the connection was closed by the remote host or unexpectedly
	print('Connection closed.')
	set_process(false)

func _connected():
	# This emits when the connection succeeds.
	print('Connected!')

func _on_data(data):
	# This is called when Godot receives data from evennia
	var json_data = JSON.parse_string(data)
	# Here we have the data from Evennia which is an array.
	# The first element will be text if it is a message
	# and would be the key of the OOB data you passed otherwise.
	if json_data[0] == 'text':
		# In this case, we simply append the data as bbcode to our label.
		for msg in json_data[1]:
			# Here we include a newline at every message.
			label.append_text("\n" + msg)
	elif json_data[0] == 'coordinates':
		# Dummy signal emitted if we wanted to handle the new coordinates
		# elsewhere in the project.
		self.emit_signal('updated_coordinates', json_data[1])

	# We only print this for easier debugging.
	print(data)

func _on_button_pressed():
	# This is called when we press the button in the scene
	# with a connected signal, it sends the written message to Evennia.
	var msg = chat_input.text
	_send_message(msg)
	chat_input.text = ""


func _on_chat_input_text_submitted(new_text: String) -> void:
	_send_message(new_text)
	chat_input.text = ""
	

func _send_message(msg: String) -> void:
	var msg_str = JSON.stringify(['text', [msg], {}])
	websocket.send(msg_str)
	

func _on_chat_log_meta_clicked(meta: Variant) -> void:
	var meta_str: String = str(meta)
	var cmd_str: String = meta_str.split("=", true, 1)[1]
	_send_message(cmd_str)
