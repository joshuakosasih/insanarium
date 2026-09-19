class_name FeedProfile
extends Resource
## Food purchase and growth data; nutrition is independent of growth credit.
@export var title: String = "Basic"
@export var price: int = 2
@export var growth_credit: int = 1
@export var nutrition: float = 0.65
@export var color: Color = Color("ffa86b")

static func tiers() -> Array[FeedProfile]:
	var result: Array[FeedProfile] = []
	for i in range(3):
		var feed := FeedProfile.new()
		feed.title = ["Basic", "Premium", "Deluxe"][i]
		feed.price = (i + 1) * 2
		feed.growth_credit = i + 1
		feed.color = [Color("ffa86b"), Color("9fd5ef"), Color("dcafea")][i]
		result.append(feed)
	return result
