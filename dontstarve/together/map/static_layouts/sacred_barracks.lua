return {
  version = "1.1",
  luaversion = "5.1",
  orientation = "orthogonal",
  width = 40,
  height = 40,
  tilewidth = 16,
  tileheight = 16,
  properties = {},
  tilesets = {
    {
      name = "tiles",
      firstgid = 1,
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../../../../tools/tiled/dont_starve/tiles.png",
      imagewidth = 512,
      imageheight = 384,
      properties = {},
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "BG_TILES",
      x = 0,
      y = 0,
      width = 40,
      height = 40,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 29, 0, 0, 0, 27, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0, 27, 0, 0, 0
      }
    },
    {
      type = "objectgroup",
      name = "FG_OBJECTS",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          name = "",
          type = "pillar_ruins",
          shape = "rectangle",
          x = 608,
          y = 608,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "pillar_ruins",
          shape = "rectangle",
          x = 32,
          y = 608,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "pillar_ruins",
          shape = "rectangle",
          x = 32,
          y = 32,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 576,
          y = 416,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = "1"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 576,
          y = 432,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".45"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 576,
          y = 448,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".45"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 112,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".3"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 128,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".3"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 144,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".3"
          }
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 64,
          y = 240,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 64,
          y = 256,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 64,
          y = 272,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 64,
          y = 288,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 160,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 176,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 192,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 208,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 576,
          y = 176,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = "1"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 576,
          y = 192,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".45"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 576,
          y = 208,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".45"
          }
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 144,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 128,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".3"
          }
        },
        {
          name = "",
          type = "wall_ruins",
          shape = "rectangle",
          x = 112,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.health.percent"] = ".3"
          }
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 160,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 480,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 512,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 528,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "brokenwall_ruins",
          shape = "rectangle",
          x = 496,
          y = 576,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "chessjunk1",
          shape = "rectangle",
          x = 256,
          y = 192,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "chessjunk2",
          shape = "rectangle",
          x = 160,
          y = 416,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "chessjunk3",
          shape = "rectangle",
          x = 352,
          y = 288,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "rook_nightmare",
          shape = "rectangle",
          x = 208,
          y = 304,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "rook_nightmare",
          shape = "rectangle",
          x = 480,
          y = 368,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "bishop_nightmare",
          shape = "rectangle",
          x = 432,
          y = 176,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "ruins_statue_head",
          shape = "rectangle",
          x = 128,
          y = 130,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "ruins_statue_head",
          shape = "rectangle",
          x = 511,
          y = 128,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "ruins_statue_head_nogem",
          shape = "rectangle",
          x = 510,
          y = 510,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "ruins_statue_head",
          shape = "rectangle",
          x = 129,
          y = 510,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "ruins_statue_mage",
          shape = "rectangle",
          x = 321,
          y = 320,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "pillar_ruins",
          shape = "rectangle",
          x = 610,
          y = 32,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "nightmarelight",
          shape = "rectangle",
          x = 256,
          y = 254,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "nightmarelight",
          shape = "rectangle",
          x = 384,
          y = 256,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "nightmarelight",
          shape = "rectangle",
          x = 385,
          y = 384,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "nightmarelight",
          shape = "rectangle",
          x = 257,
          y = 383,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
