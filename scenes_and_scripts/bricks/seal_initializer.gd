class_name SealInitializer extends Node

#super_easy = 0 (just health seal)
	#easy = 1 stages before health stage
	#medium = 2-3 stages before health stage
	#hard = 4-5 stages before health stage
	#floor 1: denial, 2: anger 3: bargaining 4: edpression 5: acceptance

static func determine_rarity()->int:
	var rates = GameManager.floor_data.seal_difficulty_rates
	var total: float = rates.super_easy + rates.easy + rates.medium + rates.hard
	var roll: float = randf() * total
	var cumulative: float = 0.0
	
	print("rates: ", rates.super_easy, rates.easy, rates.medium, rates.hard)
	print("total: ", total, " | roll: ", roll)
	
	cumulative += rates.super_easy
	if roll < cumulative: return 0
	cumulative += rates.easy
	if roll < cumulative: return 1
	cumulative += rates.medium
	if roll < cumulative: return randi_range(2, 3)
	return randi_range(4, 5)

static func _get_health_value() -> float:
	var config: SealPhaseConfig = GameManager.floor_data.seal_health_phase
	return ceili(randf_range(config.min_health, config.max_health)) if config else 5.0


static func initialize_seal() -> Dictionary[GameManager.PhaseType, float]:
	var final_phase_pool: Dictionary[GameManager.PhaseType, float] = {}
	var available_pool: Array = GameManager.floor_data.seal_phase_pool.duplicate()
	var iterations: int = determine_rarity()
	
	if iterations == 0:
		final_phase_pool[GameManager.PhaseType.HEALTH] = _get_health_value()
		return final_phase_pool
	
	available_pool.shuffle()
	var count: int = mini(iterations, available_pool.size())
	
	for i in count:
		var config: SealPhaseConfig = available_pool[i]
		final_phase_pool[config.phase_type] = ceili(randf_range(config.min_health, config.max_health))
	
	final_phase_pool[GameManager.PhaseType.HEALTH] = _get_health_value()	
	
	return final_phase_pool
