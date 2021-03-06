require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_spider.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_mushy.zip"),
}

local base_prefab = "backpack"

local tags = {"BACKPACK", "CRAFTABLE"}

local ui_preview =
{
	build = "swap_backpack_spider",
	bank = "swap_backpack_spider",
}

return CreatePrefabSkin("backpack_spider",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN",
	init_fn = function(inst) backpack_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_backpack_spider",
	rarity = "Elegant",
})