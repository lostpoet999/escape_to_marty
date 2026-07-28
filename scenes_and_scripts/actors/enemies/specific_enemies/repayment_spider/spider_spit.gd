class_name SpiderSpit
extends EnemyActions

func execute_action(actor: PlacedEnemy) -> void:
	var spider: RepaymentSpider = actor as RepaymentSpider
	if spider == null:
		return
	spider.perform_spit()
