class_name ShopRestockPayload extends BonusPayload

@export var vouchers: int = 1

func apply() -> void:
	PlayerData.grant_shop_restock_voucher(vouchers)
