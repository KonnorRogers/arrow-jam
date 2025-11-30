module App
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
end
