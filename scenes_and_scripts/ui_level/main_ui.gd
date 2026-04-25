extends Control

@onready var score: Label = %Score
@onready var stars: Label = %Stars
@onready var health: Label = %health

var numberAnimDelay: float = 3/30 # of a second
var numberDelayRemaining: float = 0

var currentScore: int = 0
var currentStars: int = 0
var currentHealth: int = 0
var displayedScore: int = 0
var displayedStars: int = 0
var displayedHealth: int = 0

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
	
	var healthChange: int = abs(displayedHealth-currentHealth)
	var healthDelta: int = 1 # 10 if healthChange>10 else 1
	var starsChange: int = abs(displayedStars-currentStars)
	var starsDelta: int = 1 # 10 if starsChange>10 else 1
	var scoreChange: int = abs(displayedScore-currentScore)
	var scoreDelta: int = 50 if scoreChange>50 else 1 # go faster if big difference
	
	if healthChange!=0:
		if displayedHealth < currentHealth: displayedHealth += healthDelta
		if displayedHealth > currentHealth: displayedHealth -= healthDelta
		health.text = str(displayedHealth)
	if starsChange!=0:
		if displayedStars < currentStars: displayedStars += starsDelta
		if displayedStars > currentStars: displayedStars -= starsDelta
		stars.text = str(displayedStars)
	if scoreChange!=0:
		if displayedScore < currentScore: displayedScore += scoreDelta
		if displayedScore > currentScore: displayedScore -= scoreDelta
		score.text = str(displayedScore)
