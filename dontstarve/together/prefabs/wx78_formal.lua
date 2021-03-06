local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_formal.zip"),
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
}

local skins =
{
	normal_skin = "wx78_formal",
	ghost_skin = "ghost_wx78_build",
}

local base_prefab = "wx78"

local tags = {"WX78", "CHARACTER"}

local ui_preview =
{
	build = "wx78_formal",
}


return CreatePrefabSkin("wx78_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wx78_formal" },
	has_alternate_body = { "wx78_formal" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
	
	rarity = "Elegant",
})