class_name Pick2Payload extends BonusPayload

@export var vouchers: int = 1

func apply() -> void:
	PlayerData.grant_pick2_voucher(vouchers)
