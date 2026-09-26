class_name ShopItemDefinition
extends RefCounted
## Static presentation data. Prices and availability stay with the owning systems.
var id: String
var title: String
var category: String
var description: String
var icon: String

func _init(item_id: String, item_title: String, item_category: String, item_description: String, item_icon: String) -> void:
	id = item_id
	title = item_title
	category = item_category
	description = item_description
	icon = item_icon

static func catalog() -> Array[ShopItemDefinition]:
	return [
		ShopItemDefinition.new("fish", "Young fish", "LIVESTOCK", "Add a young Amberfin with a random sex to the aquarium.", "fish"),
		ShopItemDefinition.new("snail", "Snail", "HELPER", "Collects coins along the tank floor, but must sleep after spending its stamina.", "snail"),
		ShopItemDefinition.new("shrimp", "Cleanup shrimp", "HELPER", "Unlocked by an Auto-feeder or Seahorse. Forages for settled waste and expiring pellets.", "shrimp"),
		ShopItemDefinition.new("seahorse", "Seahorse", "HELPER", "Unlocked by Premium feed. Produces free pellets when fish are hungry.", "seahorse"),
		ShopItemDefinition.new("puffer", "Bubble puffer", "HELPER", "Unlocked by any Income Bubbles upgrade. May chase bubbles during active play.", "puffer"),
		ShopItemDefinition.new("feeder", "Auto-feeder", "EQUIPMENT", "Uses purchased pellet stock to feed hungry fish automatically.", "feeder"),
		ShopItemDefinition.new("stock", "Pellet stock", "SUPPLY", "Load up to 20 pellets of the currently unlocked feed into the auto-feeder.", "stock"),
		ShopItemDefinition.new("feed", "Feed quality", "UPGRADE", "Permanently replace manual feed with the next quality tier.", "feed"),
		ShopItemDefinition.new("coins", "Fish coins", "UPGRADE", "Improve the floor lifetime and value of ordinary coins produced by fish.", "coin"),
		ShopItemDefinition.new("diamond_value", "Diamonds", "UPGRADE", "Unlocked by any Fish Coins upgrade. Improve diamond floor lifetime and value independently.", "diamond"),
		ShopItemDefinition.new("idle_duration", "Away time", "UPGRADE", "Unlock and extend the real time simulated after leaving the aquarium.", "clock"),
		ShopItemDefinition.new("bubbles", "Income bubbles", "UPGRADE", "Increase the number of simultaneous bubbles and the value of every pop.", "bubble")]
