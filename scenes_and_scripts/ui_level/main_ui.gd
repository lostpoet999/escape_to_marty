extends Control

@onready var score: Label = %Score
@onready var gold: Label = %Gold
@onready var health: Label = %health
@onready var shields: Label = %shields

var numberAnimDelay: float = 3.0 / 60.0
var numberDelayRemaining: float = 0
var numberAnimTicks: int = 12
var goldStep: int = 1
var scoreStep: int = 1

var currentScore: int = 0
var currentGold: int = 0
var currentHealth: int = 0
var currentShields: int = 0
var displayedScore: int = 0
var displayedGold: int = 0
var displayedHealth: int = 0
var displayedShields: int = 0

func _ready() -> void:
	Signalbus.gold_updated.connect(update_gold_ui)
	Signalbus.score_updated.connect(update_score_ui)
	Signalbus.player_health_updated.connect(update_player_health)
	Signalbus.reflect_shield_changed.connect(update_player_shields)
	currentScore = PlayerData.get_player_score()
	currentGold = PlayerData.get_player_gold()
	currentHealth = PlayerData.get_player_health()
	currentShields = PlayerData.get_player_shields()
	displayedScore = currentScore
	displayedGold = currentGold
	displayedHealth = currentHealth
	displayedShields = currentShields
	health.text = str(displayedHealth)
	gold.text = str(displayedGold)
	score.text = str(displayedScore)
	shields.text = str(displayedShields)

func update_gold_ui() -> void:
	currentGold = PlayerData.get_player_gold()
	goldStep = maxi(1, ceili(absi(currentGold - displayedGold) / float(numberAnimTicks)))

func update_score_ui() -> void:
	currentScore = PlayerData.get_player_score()
	scoreStep = maxi(1, ceili(absi(currentScore - displayedScore) / float(numberAnimTicks)))
	
func update_player_health() -> void:
	currentHealth = PlayerData.get_player_health()

func update_player_shields(count: int) -> void:
	currentShields = PlayerData.get_player_shields()

# animate the numbers to count up to the real value over time
func _process(delta: float) -> void:
	
	numberDelayRemaining -= delta
	if numberDelayRemaining > 0: return
	numberDelayRemaining = numberAnimDelay
	
	var healthChange: int = abs(displayedHealth-currentHealth)
	var healthDelta: int = 1 # 10 if healthChange>10 else 1
	var goldChange: int = abs(displayedGold-currentGold)
	var scoreChange: int = abs(displayedScore-currentScore)
	var shieldDelta: int = abs(displayedShields-currentShields)
	
	if healthChange!=0:
		if displayedHealth < currentHealth: displayedHealth += healthDelta
		if displayedHealth > currentHealth: displayedHealth -= healthDelta
		health.text = str(displayedHealth)
	if goldChange!=0:
		if displayedGold < currentGold: displayedGold = mini(displayedGold + goldStep, currentGold)
		if displayedGold > currentGold: displayedGold = maxi(displayedGold - goldStep, currentGold)
		gold.text = str(displayedGold)
	if scoreChange!=0:
		if displayedScore < currentScore: displayedScore = mini(displayedScore + scoreStep, currentScore)
		if displayedScore > currentScore: displayedScore = maxi(displayedScore - scoreStep, currentScore)
		score.text = str(displayedScore)
	if shieldDelta!=0:
		if displayedShields < currentShields: displayedShields += shieldDelta
		if displayedShields > currentShields: displayedShields -= shieldDelta
		shields.text = str(displayedShields)
