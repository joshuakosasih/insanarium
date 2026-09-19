class_name Economy
extends Node
signal money_changed(amount: float)
const FISH_BASE_PRICE: int = 50
const FISH_PRICE_GROWTH: float = 1.65
var money_cents: int = 10000
var money: float:
	get:
		return money_cents / 100.0
	set(value):
		money_cents = maxi(0, roundi(value * 100.0))

static func format_money(value: float) -> String:
	return str(roundi(value)) if roundi(value * 100.0) % 100 == 0 else "%.2f" % value

func credit(amount: float) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)

static func fish_price(population: int) -> int:
	var exponent: int = maxi(0, population - 2)
	return maxi(FISH_BASE_PRICE, roundi((FISH_BASE_PRICE * pow(FISH_PRICE_GROWTH, exponent)) / 5.0) * 5)

func buy_fish(population: int) -> bool:
	return spend(fish_price(population))

func spend(price: float) -> bool:
	var cents: int = roundi(price * 100.0)
	if cents <= 0 or money_cents < cents:
		return false
	money_cents -= cents
	money_changed.emit(money)
	return true
