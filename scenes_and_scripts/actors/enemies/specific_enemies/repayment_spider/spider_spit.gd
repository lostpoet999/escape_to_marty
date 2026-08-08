class_name SpiderSpit
extends EnemyActions

## Odds a spit tick actually throws; the rest idle. Trims coin rate without slowing WallCrawl, which shares the one action timer.
@export var spit_chance: float = 0.7

func execute_action(actor: PlacedEnemy) -> void:
	var spider: RepaymentSpider = actor as RepaymentSpider
	if spider == null:
		return
	if randf() >= spit_chance:
		return
	spider.perform_spit()
