require "map/room_functions"

---------------------------------------------
-- Rabbit Lair
---------------------------------------------

-- Loose village
AddRoom("RabbitArea", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.SINKHOLE,
    type = NODE_TYPE.Room,
    --tags = {"ForceConnected"},
    contents =  {
        distributepercent = .2,
        distributeprefabs=
        {
            cavelight = 0.05,
            cavelight_small = 0.05,
            cavelight_tiny = 0.05,
            flower_cave = 0.5,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.05,
            carrot_planted = 1,
            rabbithouse = 0.21,
            cave_fern=0.5,
            fireflies = 0.01,

            red_mushroom = 0.1,
            green_mushroom = 0.1,
            blue_mushroom = 0.1,
        }
    }
})

-- Robust town
AddRoom("RabbitTown", {
    colour={r=0.3,g=0.2,b=0.3,a=0.9},
    value = GROUND.SINKHOLE,
    contents =  {
        countstaticlayouts={
            ["RabbitTown"]=1,
        },
        distributepercent = .2,
        distributeprefabs=
        {
            cavelight = 0.1,
            cavelight_small = 0.1,
            cavelight_tiny = 0.1,
            flower_cave=0.75,
            carrot_planted = 1,
            cave_fern=0.75,
            rabbithouse = 0.51,
            fireflies = 0.01,
        }
    }
})

-- City
AddRoom("RabbitCity", {
    colour={r=0.3,g=0.2,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,
    contents =  {
        countstaticlayouts={
            ["RabbitCity"]=1,
        },
        distributepercent = .15,
        distributeprefabs=
        {
            cavelight = 0.1,
            cavelight_small = 0.1,
            cavelight_tiny = 0.1,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.05,
            flower_cave=0.75,
            carrot_planted = 1,
            cave_fern=0.75,
            rabbithouse = 0.51,
            fireflies = 0.01,
        }
    }
})

-- Sinkhole gathering
AddRoom("RabbitSinkhole", {
    colour={r=.15,g=.18,b=.15,a=.50},
    value = GROUND.SINKHOLE,
    type = NODE_TYPE.Room,
    custom_tiles={
        GeneratorFunction = RUNCA.GeneratorFunction,
        data = {
            iterations=8,
            seed_mode=CA_SEED_MODE.SEED_CENTROID,
            num_random_points=1,
            translate={
                {tile=GROUND.GRASS, items={"sapling","berrybush"}, 	item_count=5},
                {tile=GROUND.GRASS, items={"grass", "berrybush", "rabbithouse"}, 	item_count=10},
                {tile=GROUND.GRASS, items={"grass", "sapling", "evergreen", "rabbithouse"},	item_count=12},
                {tile=GROUND.GRASS, items={"evergreen", "sapling", "rabbithouse"}, 		item_count=10},
                {tile=GROUND.GRASS, items={"not_used"}, 		item_count=300},
            },
            centroid= 	{tile=GROUND.FOREST, 	items={"cavelight"},			item_count=1},
        },
    },
    contents =  {
        distributepercent = .175,
        distributeprefabs =
        {
            cavelight = 25,
            cavelight_small = 25,
            cavelight_tiny = 25,

            spiderden = .1,
            rabbithouse = 1,

            fireflies = 1,
            sapling = 15,
            evergreen = .25,
            berrybush = .5,
            blue_mushroom = .5,
            green_mushroom = .3,
            red_mushroom = .4,
            grass = .25,
            cave_fern = 20,
        },
    }
})

-- Spider incursion (overworld spiders)
AddRoom("SpiderIncursion", {
    colour={r=.10,g=.08,b=.05,a=.50},
    value = GROUND.SINKHOLE,
    type = NODE_TYPE.Room,
    custom_tiles={
        GeneratorFunction = RUNCA.GeneratorFunction,
        data = {
            iterations=3,
            seed_mode=CA_SEED_MODE.SEED_CENTROID,
            num_random_points=1,
            translate={
                {tile=GROUND.SINKHOLE, items={"grass"}, 		item_count=3},
                {tile=GROUND.SINKHOLE, items={"sapling","berrybush"}, 	item_count=5},
                {tile=GROUND.GRASS, items={"grass", "berrybush", "spiderden"}, 	item_count=10},
                {tile=GROUND.GRASS,  items={"grass", "sapling", "evergreen", "spiderden"},	item_count=12},
                {tile=GROUND.GRASS,items={"evergreen", "sapling", "spiderden"}, 		item_count=10},
            },
            centroid= 	{tile=GROUND.FOREST, 	items={"cavelight"},			item_count=1},
        },
    },
    contents =  {
        distributepercent = .175,
        distributeprefabs =
        {
            cavelight = 25,
            cavelight_small = 25,
            cavelight_tiny = 25,

            spiderden = .1,
            rabbithouse = 1,

            fireflies = 1,
            sapling = 15,
            evergreen = .25,
            berrybush = .5,
            blue_mushroom = .5,
            green_mushroom = .3,
            red_mushroom = .4,
            grass = .25,
            cave_fern = 20,
        },
    }
})

