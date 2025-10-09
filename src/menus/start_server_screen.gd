extends CanvasLayer

@onready var port_number_entry: TextEdit = $TextEntry/PortNumberEntry
@onready var i_pv_6_entry: TextEdit = $TextEntry/IPv6Entry
@onready var start_game_button: Button = $Buttons/StartGameButton
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
var is_client_started : bool = false

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
	if GameState.current_state != GameState.START_SERVER_SCREEN: 
		visible = false
	else:
	
		if Input.is_action_just_pressed("cancel"):
			exit_screen()
	
		if is_connecting and not is_it_connected:
			if calculate_wait_time(delta):
				peer.put_packet(message_to_send_as_bytes)
				if peer.get_available_packet_count() > 0:
					message_received = bytes_to_var(peer.get_packet())
					if message_received == "START_CONFIRMED":
						is_it_connected = true
						start_game_button.disabled = false
						message_to_send_as_bytes = var_to_bytes("START_CONFIRMED")
		elif is_it_connected:
			if peer.get_available_packet_count() > 0:
				message_received = bytes_to_var(peer.get_packet())
				if message_received == "START_CONFIRMED":
					peer.put_packet(message_to_send_as_bytes)
	
	# let the client know that we have started the server.
	# need to repeat until we hear confirmation, even if we have moved on
	if is_started and not is_client_started:
		peer.put_packet(var_to_bytes("GAME_STARTED"))
		if peer.get_available_packet_count() > 0:
			if bytes_to_var(peer.get_packet()) == "GAME_STARTED":
				is_client_started = true

func _on_start_connecting_button_pressed() -> void:
	message_to_send_as_bytes = var_to_bytes("CONFIRM_START")
	message_received = ""
	port_num = int(port_number_entry.text)
	their_ip = i_pv_6_entry.text
	GameState.port_number = port_num
	GameState.ipv6_number = their_ip
	peer = PacketPeerUDP.new()
	peer.bind(port_num)
	
	""" <- uncomment here for local testing
	peer.set_dest_address(their_ip, port_num)
	"""
	peer.set_dest_address(their_ip, port_num+1)# - differnt ports for local testing"""
	
	is_connecting = true


func _on_state_changed() -> void:
	visible = GameState.current_state == GameState.START_SERVER_SCREEN


func _on_cancel_button_pressed() -> void:
	exit_screen()


func _on_start_game_button_pressed() -> void:
	is_started = true
	start_game_button.disabled = true
	connection_timer.start(5)
	GameState.reset_game()


func _on_connection_timer_timeout() -> void:
	peer.close()
	GameState.change_state(GameState.MOVE)
	EventBus.begin_start_server.emit()
