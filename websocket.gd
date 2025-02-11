extends Node

# This code was taken from a Godot Demo PR
# https://github.com/godotengine/godot-demo-projects/pull/781/files#diff-e2023bfc2a5e8780024f6dc43d57746b9fa235534905b69559c3a8139f12434b
class_name WebSocketClient

@export var handshake_headers : PackedStringArray
@export var supported_protocols : PackedStringArray

# These will only be useful if validating a tls certificate
# We turn that off for local development
var tls_options := TLSOptions.client_unsafe()

var socket = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED

# This time, we will emit those signals ourselves
signal connected_to_server()
signal connection_closed()
signal message_received(message: Variant)


func connect_to_url(url) -> int:
	socket.supported_protocols = supported_protocols
	socket.handshake_headers = handshake_headers
	var err = socket.connect_to_url(url, tls_options)
	print(err)
	if err != OK:
		return err
	last_state = socket.get_ready_state()
	return OK


func send(message) -> int:
	if typeof(message) == TYPE_STRING:
		return socket.send_text(message)
	return socket.send(var_to_bytes(message))


func get_message() -> Variant:
	if socket.get_available_packet_count() < 1:
		return null
	var pkt = socket.get_packet()
	if socket.was_string_packet():
		return pkt.get_string_from_utf8()
	return bytes_to_var(pkt)


func close(code := 1000, reason := "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()


func clear() -> void:
	socket = WebSocketPeer.new()
	last_state = socket.get_ready_state()


func get_socket() -> WebSocketPeer:
	return socket


func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()
	var state = socket.get_ready_state()
	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		message_received.emit(get_message())


func _process(delta):
	poll()
