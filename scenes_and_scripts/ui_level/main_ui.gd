extends Control

@onready var score: Label = %Score
@onready var stars: Label = %Stars
@onready var health: Label = %health

var numberAnimDelay = 0.1
var numberDelayRemaining = 0

var currentScore = 0
var currentStars = 0
var currentHealth = 0
var displayedScore = 0
var displayedStars = 0
var displayedHealth = 0

func _ready() -> void:
	Signalbus.stars_updated.connect(update_star_ui)
	Signalbus.score_updated.connect(update_score_ui)
	Signalbus.player_health_updated.connect(update_player_health)
	health.text = str(displayedHealth)
	stars.text = str(displayedStars)
	score.text = str(displayedScore)

func update_star_ui() -> void:
	currentStars = PlayerData.get_player_stars()

func update_score_ui() -> void:
	currentScore = PlayerData.get_player_score()
	
func update_player_health() -> void:
	currentHealth = PlayerData.get_player_health()

# animate the numbers to count up to the real value over time
func _process(delta: float) -> void:
	
	numberDelayRemaining -= delta
	if numberDelayRemaining > 0: return
	numberDelayRemaining = numberAnimDelay
	
	if displayedHealth != currentHealth:
		if displayedHealth < currentHealth: displayedHealth += 1
		if displayedHealth > currentHealth: displayedHealth -= 1
		health.text = str(displayedHealth)
	if displayedStars != currentStars:
		if displayedStars < currentStars: displayedStars += 1
		if displayedStars > currentStars: displayedStars -= 1
		stars.text = str(displayedStars)
	if displayedScore != currentScore:
		if displayedScore < currentScore: displayedScore += 1
		if displayedScore > currentScore: displayedScore -= 1
		score.text = str(displayedScore)
