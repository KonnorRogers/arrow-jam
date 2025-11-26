require "vendor/sprite_kit/sprite_kit.rb"


module App
  FPS = 60
  DELTA_TIME = 1 / FPS

  SPRITE_PATH = "sprites/bow-1.png"
  SPRITES = {
    explosion: {
      source_x: 128,
      source_y: 192,
      source_h: 32,
      source_w: 32,
      path: SPRITE_PATH
    },
    target: {
      source_x: 64,
      source_y: 128,
      source_h: 16,
      source_w: 16,
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
      flip_horizontally: true
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

  class Powerup < ::SpriteKit::Sprite
    attr_accessor :speed, :type

    def initialize(powerup:, **kwargs)
      super(powerup: powerup, **kwargs)
      @type = :powerup
      @powerup = powerup
      @angle ||= 0
      set_sprite
    end

    def set_sprite
      sprite = SPRITES[@powerup][:box]
      sprite.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def update
      speed = @speed / FPS
      angle = @angle.to_radians
      dx = speed * Math.cos(angle)
      dy = speed * Math.sin(angle)
      @x -= dx
      @y -= dy
    end
  end

  class Enemy < ::SpriteKit::Sprite
    attr_accessor :speed, :type

    def initialize(**kwargs)
      super(**SPRITES[:goose], **kwargs)
      @type = :enemy
      @angle ||= 0
    end

    def update
      speed = @speed / FPS
      angle = @angle.to_radians
      dx = speed * Math.cos(angle)
      dy = speed * Math.sin(angle)
      @x -= dx
      @y -= dy
    end
  end

  class Player < ::SpriteKit::Sprite
    attr_accessor :speed, :arrow, :power

    def initialize(**kwargs)
      super(**SPRITES[:bow], **kwargs)

      @arrow_speed ||= 6
      @angle ||= 0

      reload
    end

    def reload
      random_arrow = ARROW_TYPES.values.sample
      # random_arrow = ARROW_TYPES[:drill]
      # random_arrow = ARROW_TYPES[:fire]
      @arrow = random_arrow.new(x: @x, y: @y, w: @w, h: @h, angle: @angle, speed: @arrow_speed)
    end

    def x=(val)
      @x = val
      @arrow.x = val
    end

    def y=(val)
      @y = val
      @arrow.y = val
    end

    def angle=(val)
      @angle = val
      @arrow.angle = val
    end

    def prefab
      [
        self,
        arrow
      ]
    end
  end

  class Arrow < ::SpriteKit::Sprite
    attr_accessor :gravity, :speed, :arrow_type, :type

    # We don't need to actually do `

    def initialize(**kwargs)
      super(**kwargs)
      @gravity = -300
      @type = :arrow
      @arrow_type ||= :plain
      set_sprite
    end

    def hit_box
      {
        **get_tip,
        w: 2,
        h: 2
      }
    end

    def shoot(power)
      @speed = @speed * power
      @vertical_velocity = calc_vertical_velocity
      @horizontal_velocity = calc_horizontal_velocity
    end

    def calc_horizontal_velocity
      @speed * Math.cos(@angle.to_radians)
    end

    def calc_vertical_velocity
      @speed * Math.sin(@angle.to_radians)
    end

    def current_speed
      Math.sqrt((horizontal_velocity * horizontal_velocity) + (vertical_velocity * vertical_velocity))
    end

    def get_tip
      angle = @angle.to_radians
      center_x = @x + (@w / 2)
      center_y = @y + (@h / 2) - 1

      # Distance from center to tip (front of arrow)
      tip_x_offset = @w / 2
      tip_y_offset = @h / 2

      # Calculate tip position from center using angle
      tip_x = center_x + Math.cos(angle) * tip_x_offset
      tip_y = center_y + Math.sin(angle) * tip_y_offset

      { x: tip_x, y: tip_y }
    end

    # def projected_endpoint
    #   angle_in_radians = @angle.to_radians
    #   gravity = @gravity

    #   vx = @speed * Math.cos(angle_in_radians)
    #   vy = @speed * Math.sin(angle_in_radians)

    #   # Time when arrow returns to start height
    #   # From equation: y = start_y + vy*t + 0.5*gravity*t²
    #   # When y = start_y: 0 = vy*t + 0.5*gravity*t²
    #   # Solve for t: t = -2*vy / gravity
    #   time_to_land = -2 * vy / gravity

    #   # Calculate final x position
    #   end_x = @x + vx * time_to_land
    #   end_y = @y # Returns to same height

    #   { x: end_x, y: end_y, time: time_to_land }
    # end

    def update
      # $outputs.debug << "#{@angle}"
      @x += @horizontal_velocity * DELTA_TIME

      # Update vertical velocity and position (gravity)
      @vertical_velocity += @gravity * DELTA_TIME
      @y += @vertical_velocity * DELTA_TIME

      # Update angle based on new velocities
      @angle = Math.atan2(@vertical_velocity, @horizontal_velocity).to_degrees
    end

    def set_sprite
      sprite = SPRITES[@arrow_type][:arrow]
      sprite.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end
  end

  class LightningArrow < Arrow
    def initialize(...)
      @arrow_type = :lightning
      super(...)
    end
  end

  class FireArrow < Arrow
    def initialize(...)
      @arrow_type = :fire
      super(...)
    end
  end

  class DrillArrow < Arrow
    def initialize(...)
      @arrow_type = :drill
      super(...)
      @speed = 8
      @gravity = -1
    end
  end

  class IceArrow < Arrow
    def initialize(...)
      @arrow_type = :ice
      super(...)
    end
  end

  ARROW_TYPES = {
    # plain: Arrow,
    drill: DrillArrow,
    fire: FireArrow,
    lightning: LightningArrow,
    ice: IceArrow
  }

  class Explosion < ::SpriteKit::Sprite
    attr_accessor :exploded_at, :frame_index

    def initialize(exploded_at:, **kwargs)
      super(**kwargs)
      @exploded_at = exploded_at
      @sprite = SPRITES[:explosion]
      @w = @sprite.source_w
      @h = @sprite.source_h
      set_sprite
    end

    def set_sprite
      @sprite.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def update(tick_count)
      @frame_index = Numeric.frame_index(
                          count: 6, # or frame_count: 6 (if both are provided frame_count will be used)
                          hold_for: 4,
                          repeat: false,
                          repeat_index: 0,
                          start_at: @exploded_at,
                          tick_count_override: tick_count
                     )

      $game.outputs << @frame_index.to_s
      if @frame_index == nil
        return
      end

      @h = @frame_index * @source_h
      @w = @frame_index * @source_w
      # @x = @x - @w
      # @h = @y - @h
    end
  end

  class PlayScene < SpriteKit::Scene
    MAX_TARGETS = 50
    MAX_POWERUPS = 8
    POWERUPS = [
      :ice,
      :lightning,
      :fire,
      :drill,
      :random
    ]
    MAX_TIME_IN_SECONDS = 20

    def initialize(...)
      super(...)
      setup
    end

    def setup
      @player = Player.new(
        **Layout.rect(row: Layout.row_count - 1, col: 0),
        w: 64,
        h: 64,
        speed: 6
      )

      @elapsed_time = 0
      # @mouse_start = nil
      # @mouse_end = nil
      @restart = false
      @tick_count = 0
      @enemies = generate_enemies
      # @powerups = generate_powerups
      @projectiles = {}
      @explosions = {}
      @pause_screen = PauseScreen.new
      @game_over_screen = GameOverScreen.new
    end

    def generate_powerups(powerups = [], max_powerups = MAX_POWERUPS)
      # sizes = [32, 32 * 2, 32 * 3]
      # size = 64
      size = 32
      speed = 300
      # elapsed_time = ((@elapsed_time || 1000) / 1000).to_i
      # angles = [15, 30, 45, 60]

      while powerups.length - 1 < max_powerups
        angle = rand(45)
        random_powerup = POWERUPS.sample


        powerups << Powerup.new(
          powerup: random_powerup,
          x: Grid.w - 200 + rand(100) + 50,
          y: 50,
          speed: speed,
          w: size,
          h: size,
          angle: 360 - angle,
        )
      end
      powerups
    end

    def generate_enemies(enemies = [], max_targets = MAX_TARGETS)
      sizes = [32, 32 * 2, 32 * 3]
      speeds = [150, 200, 250]
      elapsed_time = ((@elapsed_time || 1000) / 1000).to_i
      while enemies.length - 1 < ((max_targets + elapsed_time) * 2)
        rand_size = sizes.sample
        # rand_speed = (rand_size / (rand_size * 2)) ** 2
        rand_speed = speeds.sample

        # min angle of 8, max angle of 75
        angle = rand(67) + 8

        enemies << Enemy.new(
          x: Grid.w - 200 + rand(100) + 50,
          y: 50,
          speed: rand_speed,
          w: rand_size,
          h: rand_size,
          angle: 360 - angle,
        )
      end

      enemies.sort_by { |t| t.x + Grid.h + t.y }
      enemies
    end

    def tick(args)
      @outputs = args.outputs
      if @restart
        setup
      end

      if @paused || game_over?(@elapsed_time)
        @tick_start = nil
      elsif @tick_start
        @elapsed_time += ((Time.now - @tick_start) * 1000).to_i
        @tick_count += 1
      end

      @outputs.debug << sprintf("%0.02f", @elapsed_time / 1000).gsub(".", ":")
      @outputs.debug << @tick_count.to_s
      @tick_start = Time.now
      super(args)
    end

    def input
      if game_over?(@elapsed_time)
        if @mouse.click
          @restart = true
        end
        return
      end

      if @keyboard.key_down.escape || @keyboard.key_down.p
        @paused = !@paused
      end

      if @paused
        return
      end

      if @mouse.click
        @mouse_start = @mouse.dup
      end

      if @mouse.held
        @mouse_end = @mouse
      end

      if @mouse.up
        if @player.power && @player.power > 0
          @projectiles[@player.arrow.object_id] = @player.arrow
          @player.arrow.shoot(@player.power)
          @player.reload
        end
        @mouse_start = nil
        @mouse_end = nil
      end

      if @keyboard.down
        @player.y -= @player.speed
      elsif @keyboard.up
        @player.y += @player.speed
      # elsif @keyboard.key_down.down
      #   @player.y -= @player.speed
      # elsif @keyboard.key_down.up
      #   @player.y -= @player.speed
      end
    end

    def calc
      if @paused || game_over?(@elapsed_time)
        return
      end

      generate_enemies(@enemies)
      # generate_powerups(@powerups)

      if @mouse_start && @mouse_end
        # @outputs.debug << "Mouse Start: #{@mouse_start}"
        # @outputs.debug << "Mouse End: #{@mouse_end}"
        if @mouse_start.y == @mouse_end.y
          # @player.angle = 0
          @player.power = 0
        else
          angle = Geometry.angle_from(@mouse_start, @mouse_end).round

          x_ary = [@mouse_start.x, @mouse_end.x]
          y_ary = [@mouse_start.y, @mouse_end.y]
          x_diff = x_ary.max - x_ary.min
          y_diff = y_ary.max - y_ary.min

          power = [((x_diff + y_diff) / 2).round, 100].min

          # @outputs.debug << "X_DIFF: #{x_diff}, Y_DIFF: #{y_diff}"
          # @outputs.debug << "POWER: " + power.to_s

          @player.power = power
          # distance =
          @outputs.lines << {
            x: @mouse_start.x,
            x2: @mouse_end.x,
            y: @mouse_start.y,
            y2: @mouse_end.y,
            angle: angle,
            r: 255,
            b: 0,
            g: 0,
            a: 255,
          }
          @player.angle = angle
        end
      else
        # @player.angle = 0
      end

      enemies_and_powerups = @enemies
        # .concat(@powerups)

      Array.each(@projectiles.values) do |projectile|
        projectile.update

        # This is fine to do becaus ethe array doesn't get altered.
        hit_box = projectile.hit_box
        hit_enemy = Geometry.find_intersect_rect(hit_box, enemies_and_powerups)

        if hit_enemy
          if projectile.type == :arrow && projectile.arrow_type == :drill
            # Don't delete drill arrows.
          else
            @projectiles.delete(projectile.object_id)
          end

          if hit_enemy.type == :enemy
            @enemies.delete(hit_enemy)

            if projectile.arrow_type == :fire
              explosion = Explosion.new(
                x: hit_box.x,
                y: hit_box.y,
                anchor_x: 0.5,
                anchor_y: 0.5,
                exploded_at: @tick_count
              )
              @explosions[explosion.object_id] = explosion
            end
          # elsif hit_enemy.type == :powerup
          #   @powerups.delete(hit_enemy)
          end
        end

        if projectile.y < 0
          @projectiles.delete(projectile.object_id)
        end
      end

      enemies_to_delete = []

      Array.each(@explosions.values) do |explosion|
        explosion.update(@tick_count)
        Array.each(Geometry.find_all_intersect_rect(explosion, @enemies)) { |enemy| enemies_to_delete << enemy }
        if explosion.frame_index == nil
          @explosions.delete(explosion.object_id)
        end
      end

      Array.each(@enemies) do |spr|
        spr.update
        enemies_to_delete << spr if spr.x <= -50 || spr.y > Grid.h + 50
      end

      Array.each(enemies_to_delete) { |spr| @enemies.delete(spr) }

      # powerups_to_delete = []
      # Array.each(@powerups) do |spr|
      #   spr.update
      #   powerups_to_delete << spr if spr.x <= -50 || spr.y > Grid.h + 50
      # end
      # Array.each(powerups_to_delete) { |spr| @powerups.delete(spr) }
    end

    def render
      sprites = @player.prefab
        .concat(@enemies)
        # .concat(@powerups)
        .concat(@projectiles.values)
        .concat(@explosions.values)
      draw_buffer.primitives.concat(sprites)

      if @paused
        draw_buffer.primitives.concat(@pause_screen.prefab)
      elsif game_over?(@elapsed_time)
        draw_buffer.primitives.concat(@game_over_screen.prefab)
        # Game over.
      else
      end
    end

    def game_over?(time)
      (time / 1000) > MAX_TIME_IN_SECONDS
    end
  end

  class GameOverScreen < ::SpriteKit::Sprite
    attr_accessor :prefab

    def initialize(...)
      super(...)

      @container = {
        x: 0,
        y: 0,
        w: Grid.w,
        h: Grid.h,
        r: 0,
        b: 0,
        g: 0,
        a: (255 * 0.5),
        primitive_marker: :solid
      }

      @label_background = {
        x: Grid.w / 2,
        y: Grid.h / 2,
        primitive_marker: :solid,
        anchor_x: 0.5,
        anchor_y: 0.5,
        w: Grid.w / 2,
        h: Grid.h / 2,
        r: 50,
        g: 50,
        b: 50,
        a: 255
      }

      label_text_size = 88
      label = {
        x: Grid.w / 2,
        y: Grid.h / 2,
        primitive_marker: :label,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: label_text_size,
        r: 255,
        g: 255,
        b: 255,
        a: 255
      }

      @labels = [
        label.merge({
          text: "Game Over."
        }),
        label.merge({
          text: "Click anywhere to play again.",
          size_px: (label_text_size / 2),
          y: label.y - (label_text_size),
        })
      ]


      @prefab = [
        @container,
        @label_background,
      ].concat(@labels)
    end
  end

  class PauseScreen < ::SpriteKit::Sprite
    attr_accessor :prefab

    def initialize(...)
      super(...)

      @container = {
        x: 0,
        y: 0,
        w: Grid.w,
        h: Grid.h,
        r: 0,
        b: 0,
        g: 0,
        a: (255 * 0.5),
        primitive_marker: :solid
      }

      @label_background = {
        x: Grid.w / 2,
        y: Grid.h / 2,
        primitive_marker: :solid,
        anchor_x: 0.5,
        anchor_y: 0.5,
        w: Grid.w / 2,
        h: Grid.h / 2,
        r: 50,
        g: 50,
        b: 50,
        a: 255
      }

      @label = {
        text: "Paused",
        x: Grid.w / 2,
        y: Grid.h / 2,
        size_px: 88,
        primitive_marker: :label,
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        a: 255
      }

      @prefab = [
        @container,
        @label_background,
        @label
      ]
    end

  end


  class Game
    attr_accessor :outputs

    def initialize
      @scene_manager = SpriteKit::SceneManager.new(
        current_scene: :play_scene,
        scenes: {
          play_scene: PlayScene,
          spritesheet_scene: SpriteKit::Scenes::SpritesheetScene
        }
      )
    end

    def tick(args)
      @outputs = args.outputs
      @scene_manager.tick(args)

      if args.inputs.keyboard.key_down.close_square_brace
        scenes = @scene_manager.scenes.keys

        current_scene_index = scenes.find_index { |scene| scene == @scene_manager.current_scene }

        next_scene_index = current_scene_index + 1

        if next_scene_index > scenes.length - 1
          next_scene_index = 0
        end

        @scene_manager.next_scene = scenes[next_scene_index]
      end
    end
  end
end

def tick(args)
  $game ||= App::Game.new
  $game.tick(args)
  args.outputs.primitives.concat(GTK.framerate_diagnostics_primitives.map do |primitive|
    primitive.x = Grid.w - 500 + primitive.x
    primitive
  end)
end

def reset
  $game = nil
end

$gtk.reset
