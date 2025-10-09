extends CanvasLayer

@onready var port_number_entry: TextEdit = $TextEntry/PortNumberEntry
@onready var i_pv_6_entry: TextEdit = $TextEntry/IPv6Entry
@onready var start_connecting_button: Button = $Buttons/StartConnectingButton
@onready var connection_timer: Timer = $ConnectionTimer

var message_to_send_as_bytes : PackedByteArray
var message_received : String
var peer : PacketPeerUDP
var port_num : int 
var their_ip : String
var is_connecting : bool = false
var is_it_connected : bool = false
var is_started : bool = false

var wait_timer : float = 0.0
var time_between_packets : float = 1.0
const MAX_TIME_BETWEEN_PACKETS : float = 0.1

func exit_screen() -> void:
	if peer:
		peer.close()
	is_connecting = false
	is_it_connected = false
	start_connecting_button.button_pressed = false
	GameState.change_state(GameState.TITLE_SCREEN)


func calculate_wait_time(delta : float) -> bool:
	wait_timer += delta
	if wait_timer > time_between_packets:
		wait_timer = 0.0
		time_between_packets = randf_range(0, MAX_TIME_BETWEEN_PACKETS)
		return true
	return false


func _ready() -> void:
	EventBus.connect("state_changed", _on_state_changed)


func _process(delta: float) -> void:
	if GameState.current_state != GameState.JOIN_SERVER_SCREEN: 
		visible = false
	else:
	
		if Input.is_action_just_pressed("cancel"):
			exit_screen()
		
		if is_connecting and not is_it_connected:
			if calculate_wait_time(delta):
				peer.put_packet(message_to_send_as_bytes)
				if peer.get_available_packet_count() > 0:
					message_received = bytes_to_var(peer.get_packet())
					if message_received == "CONFIRM_START":
						# we have connected to the host, but we don't know if the host has heard us yet
						message_to_send_as_bytes = var_to_bytes("START_CONFIRMED")
					elif message_received == "START_CONFIRMED":
						is_it_connected = true
		elif is_it_connected:
			pass
	
	# the server will keep leting us know when they have started until they hear back from us.
	# we need to be ready to confirm even if we have moved on
	if peer and peer.get_available_packet_count() > 0:
		if bytes_to_var(peer.get_packet()) == "GAME_STARTED":
			peer.put_packet(var_to_bytes("GAME_STARTED"))
			if not is_started:
				is_started = true
				connection_timer.start(5)
				GameState.reset_game()


func _on_start_connecting_button_pressed() -> void:
	message_to_send_as_bytes = var_to_bytes("START")
	message_received = ""
	port_num = int(port_number_entry.text)
	their_ip = i_pv_6_entry.text
	GameState.port_number = port_num
	GameState.ipv6_number = their_ip
	peer = PacketPeerUDP.new()
	
	""" <- uncomment here for local testing
	peer.bind(port_num)
	"""
	peer.bind(port_num+1)# - different ports for local testing"""
	
	peer.set_dest_address(their_ip, port_num)
	is_connecting = true


func _on_state_changed() -> void:
	visible = GameState.current_state == GameState.JOIN_SERVER_SCREEN


func _on_cancel_button_pressed() -> void:
	exit_screen()


func _on_connection_timer_timeout() -> void:
	peer.close()
	EventBus.begin_join_server.emit()
	GameState.change_state(GameState.MOVE)
