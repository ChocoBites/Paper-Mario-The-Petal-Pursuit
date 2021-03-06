extends Spatial
signal startBattle(freeAttack)
signal endBattle(playerWins)
signal mario_hit()
signal stop_enemy_attack()


var player_Reached_Target=false
var player_Attack_Started=false
var enemy_Attack_State=0
var player_Attack_Finished=false
var player_response=""
var plrAttackPhase =0 ### Maybe refactor attack code to use this ###
var double_Attack: bool = false
var actionCommand_Complete=false
onready var battleStatus: bool = Globals.battleStatus
onready var playerTurn: bool = Globals.playerTurn

var finished_Drop_Movement: bool = false

onready var Mario : Mario = Globals.get_Mario()
onready var enemy = Globals.get_Enemy("Goomba")

export (PackedScene) var EnemyScene

#var enemy: RigidBody
var player_camera = Camera.new()
var enemy_camera = Camera.new()

var player_Pos: Vector3
var enemy_Pos: Vector3


var time_limited_input_check
var input_timer = 0
var input_timer_max = 0.10 # should be 0.1/sec @ 60fps = 6frames


signal get_player_move

signal player_attack

var player_jump_num = -1
var player_jump_max = -1

enum enemyAttackStates{
	STARTED = 0,
	IN_PROGRESS = 1,
	FINISHED = 2
}

enum Attack_Phases{FREE_ATTACK, WAITING_FOR_TURN, STARTING, IN_PROGRESS, ACTION_COMMAND, FINISHING}

# Called when the node enters the scene tree for the first time.
func _ready():
	initVars()
	setupBattleSettings()
	load_players_and_enemies()
	load_and_setup_cameras()
	position_players_and_enemies()
	setupHUD()
	print_debug(Mario.transform.origin)

func initVars():
	player_Reached_Target = false
	player_Attack_Started = false

	enemy_Attack_State = 0

	player_Attack_Finished = false

	player_response=""

	##plrAttackPhase =-1 ### Maybe refactor attack code to use this ###

	double_Attack = false
	battleStatus = Globals.battleStatus
	playerTurn = Globals.playerTurn
	finished_Drop_Movement = false

	player_Pos = Vector3.ZERO
	enemy_Pos = Vector3.ZERO
	time_limited_input_check = 0
	input_timer = 0
	input_timer_max = 0.10 # should be 0.1/sec @ 60fps = 6frames

func setupHUD():
	$HUD.startBattle(true)
	yield(get_tree().create_timer(3.0), "timeout")
	print_debug(print_tree_pretty())
	self.update_GUI(Mario)
	$HUD.showGUI(0)

func update_GUI(Character: Node):
	$HUD.update(self.getPlayerSettings(Character))

func position_players_and_enemies():
	#player.setup()
	Mario.transform.origin.x=$PlayerSpawn.transform.origin.x
	Mario.transform.origin.y=$PlayerSpawn.transform.origin.y
	Mario.transform.origin.z=$PlayerSpawn.transform.origin.z

	$EnemySpawn.scale.y=enemy.scale.y
	$EnemySpawn.transform.origin.y=1.8 # Need to find a way to "fall down"
										 # to Ground Level

	enemy.set_positionV3($EnemySpawn.transform.origin)

	enemy.set_rotation(Vector3.ZERO)

	$PlayerSpawn/PlayerAttack_AnimationPlayer.set_current_animation("run_and_jump_up")
	$PlayerSpawn/PlayerAttack_AnimationPlayer.stop(true)

	$EnemySpawn/EnemyAttack_AnimationPlayer.set_current_animation("goomba_attack")
	$EnemySpawn/EnemyAttack_AnimationPlayer.stop(true)

	Mario.state=Globals.MarioStates.IDLE
	Mario.get_child(0).play("idleDown")
	Mario.hflip(true)

func load_and_setup_cameras():
#	load_players_and_enemies()
	Mario.add_child(player_camera)
	enemy.add_child(enemy_camera)
	player_camera=Mario.get_child(Mario.get_child_count()-1)
	enemy_camera=enemy.get_child(enemy.get_child_count()-1)
	player_camera.translate(Vector3(0,5,12))
	enemy_camera.translate(Vector3(0,5,9))
	player_camera.current=true
	player_camera.look_at(Mario.transform.origin,Vector3.UP)


func load_players_and_enemies():
	#Mario = Globals.get_Mario()
	#var enemyR=load("res://Goomba.tscn")
	#enemy=enemyR.instance()

	if enemy is Goomba:
		enemy as Goomba

	add_child(Mario)
	add_child(enemy)

	Globals.setPlayerSettings(self.Mario,self.getPlayerSettings(Mario))



func setupBattleSettings():
	$PlayerSpawn/PlayerAttack_AnimationPlayer.play("run_and_jump_up")
	$PlayerSpawn/PlayerAttack_AnimationPlayer.stop(true)

	if Globals.playerGoesFirst==true:
		_on_BattleArena_startBattle(true)
		Globals.setPlayerGoesFirst(true)

	if Globals.playerGoesFirst==false:
		_on_BattleArena_startBattle(false)
		Globals.setPlayerGoesFirst(false)


func getPlayerSettings(player: Node):
	return [player.name,
		player.getHeartPoints(),
		player.getFlowerPoints(),
		player.getBadgePoints(),
		player.getStarPoints(),
		player.getLevel(),
		player.getPetalPower(),
		player.getCoins()]

func setPlayerSettings(player, settings: Array):
	player.setHeartPoints(settings[1])
	player.setFlowerPoints(settings[2])
	player.setBadgePoints(settings[3])
	player.setStarPoints(settings[4])
	player.setLevel(settings[5])
	player.setPetalPower(settings[6])
	player.setCoins(settings[7])

func getWorldEdge():
	return $BattleStage.get_child(0).scale

func getEnemy():
	return enemy

func setPlayerGoesFirst(value: bool):
	Globals.setPlayerGoesFirst(value)

func resetCombatants(end_of_mario_turn=true): # if not false, we assume end of Mario's turn
	initVars()  # we want to effectively reload the battle,
				# but not reload the scene
	if Globals.playerTurn==true:
		if end_of_mario_turn==true: # if player finished turn then it's enemy's turn
			Globals.playerTurn=false
			Globals.playerGoesFirst=false
			enemy_Attack_State==enemyAttackStates.STARTED
	else:
		player_response=""
		if enemy_Attack_State==enemyAttackStates.FINISHED:
			Globals.enemy_turn_finished=true
		if Globals.enemy_turn_finished==true and end_of_mario_turn==true:
			Globals.playerTurn=true

	double_Attack=false
	actionCommand_Complete=false
	player_Attack_Started=false
	Mario.direction=Vector3.ZERO
	Mario.velocity=Vector3.ZERO
	$PlayerSpawn/PlayerAttack_AnimationPlayer.play("reset")
	$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)

	$EnemySpawn/EnemyAttack_AnimationPlayer.stop()
	$EnemySpawn/EnemyAttack_AnimationPlayer.seek(0,true)
	$EnemySpawn/EnemyAttack_AnimationPlayer.advance(0)
	position_players_and_enemies()

func _process_Phase_FreeAttack(delta):
	if $PlayerSpawn/PlayerAttack_AnimationPlayer.current_animation != "jump_on" and \
			actionCommand_Complete == false:
		$PlayerSpawn/PlayerAttack_AnimationPlayer.current_animation="jump_on"
		plrAttackPhase=Attack_Phases.IN_PROGRESS
		Mario.state=Globals.MarioStates.E

func _process_Phase_WaitingForTurn(delta):
	if Globals.playerGoesFirst==true:
		plrAttackPhase=Attack_Phases.FREE_ATTACK
	else:
		emit_signal("get_player_move", delta)
		# ... Make sure enemy position is reset, ...
		$EnemySpawn/EnemyAttack_AnimationPlayer.stop(true)
		$EnemySpawn/EnemyAttack_AnimationPlayer.seek(0,true)
		if player_response=="":
			$PlayerSpawn/PlayerAttack_AnimationPlayer.play("reset")
			$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)
			plrAttackPhase=Attack_Phases.WAITING_FOR_TURN
		else:
			$PlayerSpawn/PlayerAttack_AnimationPlayer.play("run_and_jump_up")
			$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)
			actionCommand_Complete=false
			plrAttackPhase=Attack_Phases.IN_PROGRESS

func _process_Phase_InProgress(delta):
	if $PlayerSpawn/PlayerAttack_AnimationPlayer. \
			current_animation == "jump_on":
		if $PlayerSpawn/PlayerAttack_AnimationPlayer. \
				current_animation_position==0:
			plrAttackPhase=Attack_Phases.ACTION_COMMAND

func _process_Phase_ActionCommand(delta):
	if actionCommand_Complete == true:
		plrAttackPhase=Attack_Phases.IN_PROGRESS
	else:
		$PlayerSpawn/PlayerAttack_AnimationPlayer.stop(false)
		$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)
		input_timer+=delta
		$HUD/AttackMessages.popup()
		if (Mario.checkforAttackInput() == true):
			if (input_timer<input_timer_max): # if input within timelimit
				$HUD/AttackMessages/GratsMessage.show()
				$HUD/AttackMessages/Dmg_Info.text="1"
				double_Attack=true
				actionCommand_Complete=true
				plrAttackPhase=Attack_Phases.IN_PROGRESS
				$PlayerSpawn/PlayerAttack_AnimationPlayer.play()
				$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)
				$HUD/AttackMessages/Dmg_Info.show()
		else:
			$HUD/AttackMessages/NintendoAButton.show()
			$PlayerSpawn/PlayerAttack_AnimationPlayer.stop()
			$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)
			plrAttackPhase=Attack_Phases.ACTION_COMMAND
			# dont do anything until input_timer>= input_timer_max:
			if input_timer>= input_timer_max:
				$HUD/AttackMessages/NintendoAButton.hide()
				double_Attack=false
				actionCommand_Complete=true
				plrAttackPhase=Attack_Phases.IN_PROGRESS
				$PlayerSpawn/PlayerAttack_AnimationPlayer.play()

func _process_Phase_Finishing(delta):
	$HUD/AttackMessages.hide()
	$HUD/AttackMessages/NintendoAButton.hide()
	$HUD/AttackMessages/GratsMessage.hide()
	$PlayerSpawn/PlayerAttack_AnimationPlayer.play("run_and_jump_up")
	if Globals.playerGoesFirst==true:
		Globals.playerGoesFirst=false
		$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)
		Mario.state=Globals.MarioStates.E

		#	if double_Attack==true:
		#		enemy.receive_damage(1)
		if Globals.playerGoesFirst==true:
			resetCombatants(false)
			plrAttackPhase=Attack_Phases.FREE_ATTACK
			Globals.playerGoesFirst==false
		else:
			resetCombatants(false)
			$PlayerSpawn/PlayerAttack_AnimationPlayer.play("reset")
			plrAttackPhase=Attack_Phases.WAITING_FOR_TURN



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var plrAnimationPlayer: AnimationPlayer
	plrAnimationPlayer = $PlayerSpawn/PlayerAttack_AnimationPlayer
	if enemy.get_Heart_Points()>0:
		$HUD/EnemyHP.text="Enemy HP: "+str(enemy.get_Heart_Points())
	if Globals.battleStatus ==true: # if we are in battle
		if Globals.playerTurn == true: # if it's players turn...
			match plrAttackPhase:
				Attack_Phases.FREE_ATTACK:
					_process_Phase_FreeAttack(delta)
				Attack_Phases.WAITING_FOR_TURN:
					_process_Phase_WaitingForTurn(delta)
				Attack_Phases.IN_PROGRESS:
					_process_Phase_InProgress(delta)
				Attack_Phases.ACTION_COMMAND:
					_process_Phase_ActionCommand(delta)
				Attack_Phases.FINISHING:
					_process_Phase_Finishing(delta)
			### if player_Attack_Started: # once player has specified their attack
			###	# start player attack
			###	_on_BattleArena_player_attack(delta, "Jump")
		else: # Its not players turn
			match enemy_Attack_State:
				enemyAttackStates.STARTED:
					enemy_Attack_State=enemyAttackStates.IN_PROGRESS
					if $EnemySpawn/EnemyAttack_AnimationPlayer.is_playing()==false:
						$EnemySpawn/EnemyAttack_AnimationPlayer.play("goomba_attack")
				enemyAttackStates.IN_PROGRESS:
					if not $EnemySpawn/EnemyAttack_AnimationPlayer.is_playing():
						enemy_Attack_State=enemyAttackStates.FINISHED
				enemyAttackStates.FINISHED:
					$EnemySpawn/EnemyAttack_AnimationPlayer.stop(true)
					$EnemySpawn/EnemyAttack_AnimationPlayer.seek(0,true)
					Globals.playerTurn=true
					player_Attack_Started=false
					$HUD._ready()
#func playerJump(delta):
#	if plrJumpPhase==3:
#		return true


func _on_BattleArena_startBattle(freeAttack):
	#breakpoint
	if freeAttack:
		setPlayerGoesFirst(true)
	self.battleStatus=true
	Globals.battleStatus=self.battleStatus


		#attack($Mario)
#	else:
#		attack($Goombah)

#func attack(object):
#	if object.is_in_group("Player"):
#		$Mario.attack()
#	else:
#		get_tree().call_group("Enemies", "attack()")


func _on_BattleArena_endBattle(playerWins):
#	if playerWins=="true":
#		playerWins = true
#	else:
#		playerWins = false

	Globals.set_Mario(self.Mario)
	self.remove_child(Mario)
	queue_free()
	Globals.endBattle(playerWins, Globals.get_child(0))


func _on_PlayerAttack_AnimationPlayer_animation_finished(anim_name):
	if anim_name=="run_and_jump_up":
		$PlayerSpawn/PlayerAttack_AnimationPlayer.play("jump_on")
	else:
		if actionCommand_Complete == true:
			plrAttackPhase=Attack_Phases.FINISHING
		else:
			$PlayerSpawn/PlayerAttack_AnimationPlayer.seek(0)
			$PlayerSpawn/PlayerAttack_AnimationPlayer.stop(true)
			$PlayerSpawn/PlayerAttack_AnimationPlayer.advance(0)
			$PlayerSpawn/PlayerAttack_AnimationPlayer.play()


func _on_AttackInputTimer_timeout():
	time_limited_input_check=false


func _on_BattleArena_get_player_move(delta):
	if player_response=="Jump" and plrAttackPhase==Attack_Phases.WAITING_FOR_TURN:
		plrAttackPhase=Attack_Phases.STARTING
		emit_signal("player_attack", delta, player_response)
		player_response=null
	else:
		player_response = $HUD.showTurnPanel()


func _on_BattleArena_player_attack(delta, playerAttack:String):
	if plrAttackPhase==Attack_Phases.STARTING:
		plrAttackPhase=Attack_Phases.IN_PROGRESS
		if playerAttack=="Jump":
			$PlayerSpawn/PlayerAttack_AnimationPlayer.play("run_and_jump_up")

func _on_PlayerAttack_AnimationPlayer_animation_changed(old_name, new_name):
	Mario.transform.origin=$PlayerSpawn.transform.origin


func _on_EnemyAttack_AnimationPlayer_animation_changed(old_name, new_name):
	enemy.transform.origin=$EnemySpawn.transform.origin


func _on_EnemyAttack_AnimationPlayer_animation_finished(anim_name):
	print_debug("Enemy attack finished")
	if anim_name=="goomba_attack":
		enemy_Attack_State==enemyAttackStates.FINISHED
		$EnemySpawn/EnemyAttack_AnimationPlayer.stop(true)
		$EnemySpawn/EnemyAttack_AnimationPlayer.seek(0,true)
	Globals.enemy_turn_finished=true
	Globals.playerTurn == true
	enemy_Attack_State==enemyAttackStates.FINISHED
	resetCombatants(false)



func _on_BattleArena_mario_hit():
	self.update_GUI(self.Mario)#getPlayerSettings(self.Mario))
	plrAttackPhase=Attack_Phases.FINISHING

	if Globals.playerTurn==false:
		_on_EnemyAttack_AnimationPlayer_animation_finished("goomba_attack")
		Globals.enemy_turn_finished=true
		Globals.playerTurn=true
		resetCombatants(false)



func _on_BattleArena_stop_enemy_attack() -> void:
	enemy_Attack_State==enemyAttackStates.FINISHED
	$EnemySpawn/EnemyAttack_AnimationPlayer.stop(true)
	$EnemySpawn/EnemyAttack_AnimationPlayer.seek(0,true)
	resetCombatants(false)
