module App
  FPS = 60
  DELTA_TIME = 1 / FPS

  PALLETTE = {
    red: { r: 255, b: 0, g: 0, a: 255 },
    black: { r: 0, b: 0, g: 0, a: 255 },
    white: { r: 255, b: 255, g: 255, a: 255 },
    green: { r: 0, b: 0, g: 128, a: 255 }
  }

  def self.rect_to_circle(rect)
    radius = Math.sqrt(rect.w ** 2 + rect.h ** 2) / 2
    x = rect.x + (rect.w / 2)
    y = rect.y + (rect.h / 2)
    return {x: x, y: y, radius: radius}
  end
end

require "vendor/sprite_kit/sprite_kit.rb"
require "app/sprites.rb"

module App
  class Enemy < ::SpriteKit::Sprite
    attr_accessor :speed, :type, :radius, :score, :hit_box

    def initialize(**kwargs)
      super(**SPRITES[:target], **kwargs)
      @type = :enemy
      @angle ||= 0

      @scale = @w / 32
    end

    def hit_box
      {
        x: @x,
        y: @y,
        w: @w,
        h: @h,
      }
    end

    def hit_box_for_circle
      offset_x = 7 * @scale + 2
      offset_y = 7 * @scale + 2
      diameter = (@w - (offset_x * 2))
      {
        x: @x + offset_x,
        y: @y + offset_y,
        w: diameter,
        h: diameter,
      }
    end

    def calc_score(player:, multiplier:)
      distance = Geometry.distance(player, self)
      ((@score + distance) * multiplier).round
    end

    # def hit_box
    #   @hit_box
    # end

    def update(mode)
      if mode == :endless
        speed = @speed / FPS
        angle = @angle.to_radians
        dx = speed * Math.cos(angle)
        dy = speed * Math.sin(angle)
        @x -= dx
        @y -= dy
      else
        # Determine a path like a normal person.
      end
    end
  end

  class Powerup < Enemy
    attr_accessor :powerup_type
    def initialize(powerup_type:, **kwargs)
      super(**SPRITES[powerup_type][:box], **kwargs)

      @powerup_type = powerup_type
      @type = :powerup
    end

    def hit_box
      hash = super()
      hash.x = hash.x + (1 * @scale)
      hash.w = hash.w - (1 * @scale)

      hash
    end
  end

  class Bow < ::SpriteKit::Sprite
    def initialize(**kwargs)
      super(**SPRITES[:bow], **kwargs)
    end
  end

  class Platform < ::SpriteKit::Sprite
    def initialize(**kwargs)
      super(**SPRITES[:platform], **kwargs)
    end
  end

  class Player < ::SpriteKit::Sprite
    attr_accessor :speed, :arrow, :power, :bow

    def initialize(**kwargs)
      super(**SPRITES[:player], **kwargs)

      @arrow_speed ||= 7
      @bow_angle ||= 0
      @power ||= 0

      @bow_offset = 48
      @bow = Bow.new(**kwargs, x: @x + @bow_offset, angle: @bow_angle)

      @platform_offset = -@h + (@h / 4)
      @platform = Platform.new(**kwargs, x: @x, y: @y + @platform_offset)

      reload
    end

    def reload(arrow = ARROW_TYPES[:plain])
      # arrow = ARROW_TYPES[:plain]
      # arrow = ARROW_TYPES.values.sample
      # arrow = ARROW_TYPES[:drill]
      # arrow = ARROW_TYPES[:fire]
      # arrow = ARROW_TYPES[:lightning]
      # arrow = ARROW_TYPES[:ice]
      @arrow = arrow.new(x: @x + @bow_offset, y: @y, w: @w, h: @h, angle: @bow_angle, speed: @arrow_speed)
    end

    def x=(val)
      @x = val
      @platform.x = val
      @arrow.x = @bow_offset + val
      @bow.x = @bow_offset + val
    end

    def y=(val)
      @y = val
      @arrow.y = val
      @bow.y = val
      @platform.y = val + @platform_offset
    end

    def bow_angle=(val)
      @bow_angle = val
      @arrow.angle = val
      @bow.angle = val
    end

    def prefab
      [
        @platform,
        @bow,
        @arrow,
        self,
      ]
    end
  end

  class Arrow < ::SpriteKit::Sprite
    attr_accessor :gravity, :speed, :arrow_type, :type

    # We don't need to actually do `

    def initialize(**kwargs)
      super(**kwargs)
      @gravity = -350
      @type = :arrow
      @arrow_type ||= :plain
      set_sprite
    end

    def hit_box
      tip = get_tip
      tip.merge({
        x: tip.x - 6,
        y: tip.y - 4,
        w: 8,
        h: 8,
      })
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

    def get_tip(w: @w, h: @h)
      angle = @angle.to_radians
      center_x = @x + (w / 2)
      center_y = @y + (h / 2) - 1

      # Distance from center to tip (front of arrow)
      tip_x_offset = w / 2
      tip_y_offset = h / 2

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

    def hit_box
      scale = (@w / 32)
      w = @w - (12 * scale)
      h = @h - (12 * scale)
      tip = get_tip()
      angle = @angle.to_radians
      shift_x = Math.cos(angle) * (w / 2)
      shift_y = Math.sin(angle) * (h / 2)
      tip.merge({
        x: tip.x - shift_x - (w / 2),
        y: tip.y - shift_y - (h / 2),
        w: w,
        h: h,
        anchor_x: 0.5,
        anchor_y: 0.5,
      })
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

    def hit_box
      w = 26
      h = 26
      tip = get_tip()
      angle = @angle.to_radians
      shift_x = Math.cos(angle) * (w / 2)
      shift_y = Math.sin(angle) * (h / 2)
      tip.merge({
        x: tip.x - shift_x - (w / 2),
        y: tip.y - shift_y - (h / 2),
        w: w,
        h: h,
      })
    end
  end

  class IceShard < Arrow
    attr_accessor :scale

    def initialize(**kwargs)
      @arrow_type = :ice_shard
      super(sprite: SPRITES[:ice_shard], **kwargs)
      @speed = 8
      @scale ||= 4
      @w = 6 * @scale
      @h = 5 * @scale
      @gravity = -1
      set_sprite
    end

    def set_sprite
      @sprite.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end
  end

  class IceArrow < Arrow
    def initialize(...)
      @arrow_type = :ice
      super(...)
    end

    def hit_box
      scale = (@w / 32)
      w = @w - (8 * scale)
      h = @h - (8 * scale)
      tip = get_tip()
      angle = @angle.to_radians
      shift_x = Math.cos(angle) * (w / 2)
      shift_y = Math.sin(angle) * (h / 2)
      tip.merge({
        x: tip.x - shift_x - (w / 2),
        y: tip.y - shift_y - (h / 2),
        w: w,
        h: h,
        anchor_x: 0.5,
        anchor_y: 0.5,
      })
    end

    # Dynamically calculates ice shards to send out.
    def shards(scale = 2)
      # 21x22, 4px from bottom, 6px from top and 10px from left.
      shard_circle = {
        x: @x + (10 * scale),
        y: @y + (4 * scale),
        w: 21 * scale,
        h: 22 * scale,
      }

      # Center of arrow is 11px.
      center_y = 11 * scale


      [
        # top-left (+2px from center)
        IceShard.new(x: shard_circle.x, y: shard_circle.y + center_y + (2 * scale), angle: -45, scale: scale),
        # bottom-left (-2px from center)
        IceShard.new(x: shard_circle.x, y: shard_circle.y + center_y - (2 * scale), angle: -135, scale: scale),

        # top-middle-left
        IceShard.new(x: shard_circle.x + (6 * scale), y: shard_circle.y + center_y + (5 * scale), angle: -45, scale: scale),
        # bottom-middle-left
        IceShard.new(x: shard_circle.x + (6 * scale), y: shard_circle.y, angle: -135, scale: scale),

        # top-middle-right
        IceShard.new(x: shard_circle.x + (13 * scale), y: shard_circle.y + center_y + (5 * scale), angle: 45, scale: scale),
        # bottom-middle-right
        IceShard.new(x: shard_circle.x + (13 * scale), y: shard_circle.y, angle: 135, scale: scale),

        # top-right
        IceShard.new(x: shard_circle.x + (17 * scale), y: shard_circle.y + center_y + (2 * scale), angle: 45, scale: scale),
        # bottom-right
        IceShard.new(x: shard_circle.x + (17 * scale), y: shard_circle.y + center_y - (2 * scale), angle: 135, scale: scale),
      ]
    end
  end

  ARROW_TYPES = {
    plain: Arrow,
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

      if @frame_index == nil
        return
      end

      @h = @frame_index * @source_h
      @w = @frame_index * @source_w
      # @x = @x - @w
      # @h = @y - @h
    end
  end

  class ChainLightning < ::SpriteKit::Sprite
    # attr_accessor :exploded_at, :frame_index
    attr_accessor :hit_box, :lightning_radius, :frame_index, :animation_start, :active

    def initialize(animation_start:, **kwargs)
      super(**kwargs)
      @animation_start ||= animation_start
      @sprite ||= SPRITES[:chain_lightning]
      @w ||= @sprite.source_w
      @h ||= @sprite.source_h
      @lightning_radius ||= 24 * Math::PI
      @anchor_x ||= 0.5
      @anchor_y ||= 0.5
      @active = true
      set_sprite
    end

    def set_sprite
      @sprite.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def active?
      @active == true
    end

    def update(tick_count)
      @frame_index = Numeric.frame_index(
                          count: 1, # or frame_count: 6 (if both are provided frame_count will be used)
                          hold_for: 16,
                          repeat: false,
                          repeat_index: 0,
                          start_at: @animation_start,
                          tick_count_override: tick_count
                     )

      return @frame_index
    end

    def hit_box_from_enemy(enemy)
      {
        x: enemy.x,
        y: enemy.y,
        w: enemy.w,
        h: enemy.h,
        radius: enemy.w + @lightning_radius,
        anchor_x: 0.5,
        anchor_y: 0.5,
      }
    end

    def jump_to(enemy, tick_count)
      # The sprites need to be adjusted 90degrees to make sure they point in the right direction from how the sprite was drawn
      angle = Geometry.angle_from(@hit_box, enemy)
      distance = Geometry.distance(@hit_box, enemy)

      hit_box = hit_box_from_enemy(enemy)

      return ChainLightning.new(
        w: distance + (@hit_box.w / 2),
        h: distance + (@hit_box.h / 2),
        x: @hit_box.x + (@hit_box.w / 2),
        y: @hit_box.y + (@hit_box.h / 2),
        animation_start: tick_count,
        angle: angle,
        hit_box: hit_box
      )
    end

  end

  class FloatingText < SpriteKit::Sprite
    attr_label
    attr_accessor :primitive_marker,
                  :text,
                  :r,
                  :g,
                  :b,
                  :a

    def initialize(tick_count:, **kwargs)
      super(**kwargs)
      @tick_count = tick_count
      @primitive_marker = :label

    end

    def update(tick_count)
      @max_y ||= @y + 60
      perc = Easing.smooth_stop(
                        start_at: @tick_count,
                        end_at: @tick_count + 20,
                        tick_count: tick_count,
                        power: 5
                     )

      alpha_fade = Easing.smooth_stop(
                      start_at: @tick_count + 20,
                      end_at: @tick_count + 60,
                      tick_count: tick_count,
                      power: 5
                    )


      @y = @y.lerp(@max_y, perc)
      @a = @a.lerp(0, alpha_fade)         # alpha -> 0 fade

      if tick_count > @tick_count + 60
        return nil
      end

      # @y += @frame_index
      return true
    end
  end

  class ScoreBoard < SpriteKit::Sprite
    attr_accessor :prefab
    attr_reader :score

    def initialize(score:, **kwargs)
      super(**kwargs)
      @score = score

      @label = {
        x: @x,
        y: @y,
        anchor_x: 0.5,
        anchor_y: 0.5,
        **PALLETTE.white,
        primitive_marker: :label,
        text: @score
      }

      @background = {
        **PALLETTE.black,
        x: @x,
        y: @y,
        w: 300,
        h: 50,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: :solid
      }

      @prefab = [
        @background,
        @label
      ]
    end

    def score=(val)
      @score = val
      @label.text = val
    end
  end

  class PlayScene < SpriteKit::Scene
    MODES = {
      normal: :normal,
      endless: :endless
    }
    POWERUPS = [
      :ice,
      :lightning,
      :fire,
      :drill,
      # :random
    ]
    MAX_TIME_IN_SECONDS = 20

    def initialize(...)
      super(...)
      setup
    end

    def setup
      @player = Player.new(
        x: 25,
        # y: Grid.h / 2 - 32,
        y: 50,
        w: 64,
        h: 64,
        speed: 6
      )

      @scoreboard_size = 150
      @offset_x = 200
      @offset_y = 50


      @elapsed_time = 0
      # @mouse_start = nil
      # @mouse_end = nil
      @restart = false
      @tick_count = 0
      @max_targets = 3
      @max_powerups = 1
      @projectiles = {}
      @explosions = {}
      @chain_lightnings = {}
      @pause_screen = PauseScreen.new
      @game_over_screen = GameOverScreen.new
      @mode = MODES[:normal]
      @powerbar = PowerBar.new

      @multiplier = 1
      @score = 0
      @debug = false
      @scoreboard = ScoreBoard.new(score: @score, x: Grid.w / 2, y: Grid.h - 50)

      @floating_text_labels = {}
      @palette = App::PALLETTE
      @collideables = []
      @powerups = []
      @enemies = []
      generate_enemies
      generate_powerups
    end

    def generate_powerups(max_powerups = @max_powerups)
      # sizes = [32, 32 * 2, 32 * 3]
      size = 48
      score = 1_000
      # size = 32
      speed = 300
      elapsed_time = ((@elapsed_time || 1000) / 1000).to_i
      # angles = [15, 30, 45, 60]

      while @powerups.length - 1 < (max_powerups + (elapsed_time / 5).round)
        random_powerup = POWERUPS.sample
        powerup = Powerup.new(
          powerup_type: random_powerup,
          x: @offset_x + rand(Grid.w - @offset_x - size),
          y: @offset_y + rand(Grid.h - @scoreboard_size - @offset_y - size),
          w: size,
          h: size,
          score: (score.idiv(size) ** 2) * 2
          # angle: 360 - angle,
        )

        next if Geometry.find_intersect_rect(powerup, @collideables)

        @collideables << powerup
        @powerups << powerup
      end
    end

    def generate_enemies(max_targets = nil)
      if !max_targets
        max_targets = @max_targets
      end
      score = 1_000
      sizes = [32, 32 * 2, 32 * 3]
      # sizes = [32 * 6]

      # sizes = [128]
      speeds = [150, 200, 250]
      elapsed_time = ((@elapsed_time || 1000) / 1000).to_i
      while @enemies.length - 1 < ((max_targets + (elapsed_time / 5).round))
      # while enemies.length < max_targets
        rand_size = sizes.sample
        # rand_speed = (rand_size / (rand_size * 2)) ** 2
        rand_speed = speeds.sample

        # min angle of 8, max angle of 75
        # angle = rand(67) + 8

        enemy = Enemy.new(
          x: @offset_x + rand(Grid.w - @offset_x - rand_size),
          y: @offset_y + rand(Grid.h - @scoreboard_size - @offset_y - rand_size),
          w: rand_size,
          h: rand_size,
          speed: rand_speed,
          score: (score.idiv(rand_size) ** 2) * 2
          # angle: 360 - angle,
        )

        next if Geometry.find_intersect_rect(enemy, @collideables)

        @collideables << enemy
        @enemies << enemy
      end
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

      @outputs.debug << sprintf("%0.02f", @elapsed_time / 1000) #.gsub(".", ":")
      @outputs.debug << @tick_count.to_s
      @outputs.debug << "SCORE: #{@score}"
      @outputs.debug << "MULTIPLIER: #{@multiplier}"
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

      if @keyboard.key_down.period
        @debug = !@debug
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
        if @player.power && @player.power > 1
          @projectiles[@player.arrow.object_id] = @player.arrow
          @player.arrow.shoot(@player.power)
          @player.reload
        end
        @mouse_start = nil
        @mouse_end = nil
      end

      y_max = Grid.h - @player.h - 25
      y_min = 50
      if @keyboard.down
        @player.y = (@player.y - @player.speed).clamp(y_min, y_max)
      elsif @keyboard.up
        @player.y = (@player.y + @player.speed).clamp(y_min, y_max)
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

      generate_enemies
      generate_powerups

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
          @player.bow_angle = angle
        end
      else
        # @player.angle = 0
      end

      Array.each(@projectiles.values) do |projectile|
        projectile.update

        # This is fine to do becaus ethe array doesn't get altered.
        # hit_box = projectile.hit_box
        # hit_enemy = Geometry.find_intersect_rect(hit_box, @enemies)


        circle_hit_box = App.rect_to_circle(projectile.hit_box)
        hit_enemies = @collideables.select do |enemy|
          return false if !enemy

          if enemy.type == :powerup
            Geometry.intersect_rect?(projectile.hit_box, enemy.hit_box)
          else
            Geometry.intersect_circle?(circle_hit_box, App.rect_to_circle(enemy.hit_box_for_circle))
          end
        end.sort_by(&:x).sort_by(&:y)
        hit_enemy = hit_enemies[0]


        if hit_enemy
          score = hit_enemy.calc_score(player: @player, multiplier: @multiplier)
          @score += score
          @scoreboard.score = @score
          floating_text = FloatingText.new(
            **@palette.green,
            text: "+#{score}",
            x: hit_enemy.x,
            y: hit_enemy.y,
            tick_count: @tick_count
          )

          @floating_text_labels[floating_text.object_id] = floating_text
          @multiplier *= 2

          if @multiplier > 64
            @multiplier = 64
          end


          if projectile.type == :arrow && (projectile.arrow_type == :drill || projectile.arrow_type == :ice_shard)
            # Don't delete drill arrows.
          else
            @projectiles.delete(projectile.object_id)
          end

          if hit_enemy #.type == :enemy
            if hit_enemy.type == :powerup
              powerup = @powerups.delete(hit_enemy)
              @player.reload(ARROW_TYPES[powerup.powerup_type]) if powerup

            elsif hit_enemy.type == :enemy
              @enemies.delete(hit_enemy)
            end

            @collideables.delete(hit_enemy)

            if projectile.arrow_type == :fire
              explosion = Explosion.new(
                x: circle_hit_box.x,
                y: circle_hit_box.y,
                anchor_x: 0.5,
                anchor_y: 0.5,
                exploded_at: @tick_count
              )
              @explosions[explosion.object_id] = explosion
            end

            if projectile.arrow_type == :lightning
              chain_lightning = ChainLightning.new(animation_start: @tick_count)
              chain_lightning.hit_box = chain_lightning.hit_box_from_enemy(hit_enemy)
              @chain_lightnings[chain_lightning.object_id] = chain_lightning
            end

            if projectile.arrow_type == :ice
              # 45 90 135 180
              # There's 8 projectiles attached to the ice arrow. They all need to fly off in an angle relative to the head of the arrow.
              Array.each(projectile.shards) do |shard|
                # shard.angle = 45
                shard.shoot(100)
                # shard.hit_box = self
                @projectiles[shard.object_id] = shard
              end
            end
          # elsif hit_enemy.type == :powerup
          #   @powerups.delete(hit_enemy)
          end
        end

        if projectile.y < -50
          @projectiles.delete(projectile.object_id)

          if projectile.type == :arrow && projectile.arrow_type != :ice_shard
            @multiplier = 1
          end
        end
      end

      collideables_to_delete = []

      Array.each(@explosions.values) do |explosion|
        explosion.update(@tick_count)
        Array.each(Geometry.find_all_intersect_rect(explosion, @collideables)) { |enemy| collideables_to_delete << enemy }
        if explosion.frame_index == nil
          @explosions.delete(explosion.object_id)
        end
      end

      Array.each(@chain_lightnings.values) do |chain_lightning|
        frame_index = chain_lightning.update(@tick_count)

        if frame_index == nil
          @chain_lightnings.delete(chain_lightning.object_id)
        end

        if !chain_lightning.active?
          next
        end

        collideable = @collideables.find do |collideable|
          anchored_collideable = collideable.dup.tap do |spr|
            spr.anchor_x = 0.5
            spr.anchor_y = 0.5
            spr.radius = 0
          end
          Geometry.intersect_circle?(chain_lightning.hit_box, anchored_collideable)
        end
        # enemy = Geometry.find_intersect_rect(chain_lightning.hit_box, @enemies)

        if collideable
          collideables_to_delete << collideable
          new_chain_lightning = chain_lightning.jump_to(collideable, @tick_count)
          @chain_lightnings[new_chain_lightning.object_id] = new_chain_lightning
        end

        chain_lightning.active = false
      end

      update_enemies(collideables_to_delete)

      Array.each(@floating_text_labels.values) do |label|
        if label.update(@tick_count) == nil
          @floating_text_labels.delete(label.object_id)
        end
      end
    end

    def update_enemies(collideables_to_delete)
      Array.each(@enemies) do |spr|
        spr.update(@mode)

        # if @mode == MODES.endless
        #   collideables_to_delete << spr if spr.x <= -50 || spr.y > Grid.h + 50
        # end
      end

      Array.each(collideables_to_delete) do |spr|
        @collideables.delete(spr)
      end
    end

    def render
      sprites = @player.prefab
        .concat(@collideables)
        .concat(@projectiles.values)
        .concat(@explosions.values)
        .concat(@chain_lightnings.values)
        .concat(@floating_text_labels.values)
        .concat(@scoreboard.prefab)

      if @player.power > 0
        @powerbar.power = @player.power
        @powerbar.angle = @player.bow.angle
        @powerbar.update(@mouse_start)
        sprites.concat(@powerbar.prefab)
      else

      end

      if @debug
        sprites
          .concat(@collideables.map do |collideable|

            if collideable.type == :enemy
              hit_box = collideable.hit_box_for_circle
              # no idea why any of this math works :shrug:
              w = hit_box.w * 1.5
              h = hit_box.h * 1.5
              hit_box.merge({
                x: hit_box.x - (w / 6),
                y: hit_box.y - (h / 6),
                w: w,
                h: h,
                **SPRITES[:debug_circle]
              })
            else
              hit_box = collideable.hit_box
              SpriteKit::Primitives.borders(hit_box, color: @palette.red).values
            end
          end.flatten)
          .concat(@projectiles.values.map { |projectile| SpriteKit::Primitives.borders(projectile.hit_box, color: @palette.red).values }.flatten)
          .concat(@collideables.map { |collideable|
            { primitive_marker: :label, text: collideable.calc_score(player: @player, multiplier: @multiplier), x: collideable.x + (collideable.w / 2), anchor_x: 0.5, y: collideable.y + collideable.h + 20 }
          })
      end
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

  class PowerBar < ::SpriteKit::Sprite
    attr_accessor :power, :angle, :prefab

    def initialize(power: 0, **kwargs)
      super(**kwargs)

      @power = power
      @angle = 0

      update(nil)
    end

    def update(mouse)
      if mouse == nil
        return @prefab = []
      end

      @x = mouse.x
      @y = mouse.y
      bar_h = 160
      y = @y - (bar_h / 2)

      @bar = {
        x: @x,
        y: y,
        w: 24,
        h: bar_h,
        path: :solid,
        **PALLETTE.green,
      }

      size_px = 24
      @power_label = {
        x: @x + @bar.w,
        y: y + size_px,
        text: "#{@power}",
        size_px: size_px,
        primitive_marker: :label,
        **PALLETTE.black,
      }

      @angle_label = @power_label.merge({
        y: @power_label.y + @power_label.size_px + 10,
        text: "#{@angle}°"
      })

      @prefab = [
        @bar,
        @power_label,
        @angle_label,
      ]
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

  class SpritesheetScene < ::SpriteKit::Scenes::SpritesheetScene
    def initialize(...)
      super(...)
      @state.tile_selection = {
        w: 32, h: 32,
        row_gap: 0, column_gap: 0,
        offset_x: 0, offset_y: 0,
      }
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
          # title_scene: TitleScene,
          play_scene: PlayScene,
          spritesheet_scene: SpritesheetScene
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
