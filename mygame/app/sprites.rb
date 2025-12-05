module App
  SPRITE_PATH = "sprites/bow-1.png"
  SPRITES = {
    debug_circle: {
      path: "sprites/debug-circle.png",
      scale_quality_enum: 2,
      source_x: 0,
      source_y: 0,
      source_h: 2000,
      source_w: 2000
    },
    platform: {
      source_x: 192,
      source_y: 224,
      source_h: 32,
      source_w: 32,
      path: SPRITE_PATH
    },
    explosion: {
      source_x: 128,
      source_y: 192,
      source_h: 32,
      source_w: 32,
      path: SPRITE_PATH
    },
    chain_lightning: {
      source_x: 32,
      source_y: 192,
      source_h: 32,
      source_w: 32,
      path: SPRITE_PATH
    },
    ice_shard: {
      source_x: 160,
      source_y: 186,
      source_h: 6,
      source_w: 5,
      path: SPRITE_PATH
    },
    target: {
      source_x: 160,
      source_y: 224,
      source_h: 32,
      source_w: 32,
      path: SPRITE_PATH
    },
    bow: {
      source_x: 17,
      source_y: 128,
      source_h: 16,
      source_w: 17,
      path: SPRITE_PATH,
    },
    player: {
      source_x: 48,
      source_y: 144,
      source_h: 16,
      source_w: 16,
      path: SPRITE_PATH,
      # flip_horizontally: true
    },
    goose: {
      source_x: 128,
      source_y: 96,
      source_h: 32,
      source_w: 32,
      path: SPRITE_PATH,
      flip_horizontally: true,
    },
    ice: {
      box: {
        source_x: 64,
        source_y: 208,
        source_h: 16,
        source_w: 16,
        path: SPRITE_PATH
      },
      arrow: {
        source_x: 96,
        source_y: 160,
        source_h: 32,
        source_w: 32,
        path: SPRITE_PATH
      }
    },
    fire: {
      box: {
        source_x: 80,
        source_y: 192,
        source_h: 16,
        source_w: 16,
        path: SPRITE_PATH
      },
      arrow: {
        source_x: 128,
        source_y: 160,
        source_h: 32,
        source_w: 32,
        path: SPRITE_PATH
      },
    },
    plain: {
      arrow: {
        source_x: 0,
        source_y: 160,
        source_h: 32,
        source_w: 32,
        primitive_marker: :sprite,
        path: SPRITE_PATH
      },
    },
    lightning: {
      box: {
        source_x: 80,
        source_y: 208,
        source_h: 16,
        source_w: 16,
        path: SPRITE_PATH
      },
      arrow: {
        source_x: 32,
        source_y: 160,
        source_h: 32,
        source_w: 32,
        path: SPRITE_PATH
      },
    },
    drill: {
      box: {
        source_x: 64,
        source_y: 192,
        source_h: 16,
        source_w: 16,
        path: SPRITE_PATH
      },
      arrow: {
        source_x: 64,
        source_y: 160,
        source_h: 32,
        source_w: 32,
        path: SPRITE_PATH
      }
    },
    random: {
      box: {
        source_x: 96,
        source_y: 192,
        source_h: 16,
        source_w: 16,
        path: SPRITE_PATH
      }
    },
  }
end
