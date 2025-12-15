# dr-high_score v0.0.2
# MIT Licensed
# Copyright (c) 2025 Marc Heiligers
# See https://github.com/marcheiligers/dr-high_score

module HighScore
  # NOTE: This is obfuscation. At best, the only thing it does is ensure your key isn't in plain text in your repo.
  module BadCrypto
    extend self

    SOURCE = 'abcdef0123456789'
    DEST = 'plsdonthackme!?$' # okspaceladyluvyoubyebye

    def decrypt(str)
      str.tr(DEST, SOURCE)
    end

    def encrypt(str)
      str.tr(SOURCE, DEST)
    end
  end
end

module HighScore
  class PurpleToken
    include BadCrypto # see below

    BASE_URI = 'https://purpletoken.com/update/v2/'
    TICKS_BETWEEN_REFRESHES = 60 * 60 * 5 # 5 minutes

    attr_reader :scores, :position

    def initialize(key, scores = [])
      @key = decrypt(key)

      scores ||= []
      @scores = scores + Array.new(20 - scores.length) { { name: '---', score: 0 } }
      @queue = []
      @ticks = 0
      @fetch_scores_in_flight = false

      puts "The PurpleToken high score API is provided for free by the kind person at Zimnox (https://www.zimnox.com/). " \
           "Please don't abuse this kindness. The gamekey is the key for this game. You could use this to post any score " \
           "you like, but where's the fun in that?"

      fetch_scores # initial fetch
    end

    def fetch_scores
      return if @fetch_scores_in_flight # prevent multiple requests to fetch scores

      @ticks = 0
      @fetch_scores_in_flight = true

      @queue << Request.new('get_score/index.php', { gamekey: @key, format: :json }) do |response|
        @fetch_scores_in_flight = false
        return unless response[:http_response_code] == 200

        data = $gtk.parse_json(response[:response_data]) || {}
        @scores = data['scores']&.map { |score| { name: score['player'], score: score['score'] } } || []
        @scores += Array.new(20 - scores.length) { { name: '---', score: 0 } }
      end
    end

    def save_score(player, score)
      @position = @scores.index { |s| s.score < score }
      if @position
        @scores.insert(@position, { name: player, score: score })
        @scores = @scores[0..19]
      else
        return 20
      end

      @queue << Request.new('submit_score/index.php', { gamekey: @key, player: player, score: score }) do |response|
        return unless response[:http_response_code] == 200

        fetch_scores
      end

      @position
    end

    def high_score?(score, top = 20)
      @scores[top - 1].score < score
    end

    def tick
      @queue.each(&:tick)
      @queue.reject!(&:done?)

      @ticks += 1
      fetch_scores if @ticks > TICKS_BETWEEN_REFRESHES
    end

    private

    class Request
      TICKS_BETWEEN_RETRIES = 60 # 1 second * 2 ** retries
      MAX_RETRIES = 8

      def initialize(path, params = {}, &callback)
        @url = "#{BASE_URI}#{path}?#{params.map { |k, v| "#{k}=#{v}" }.join('&')}"
        @callback = callback

        @ticks = 0
        @retries = 0

        send_request
      end

      def tick
        @ticks += 1

        case @state
        when :busy
          check_request
        when :error
          send_request if @ticks > (2 ** @retries) * TICKS_BETWEEN_RETRIES # exponential backoff
        end
      end

      def check_request
        if complete?
          if success_code?
            @state = :success
            @callback.call(@response)
          else
            @state = :error
            @retries += 1
            @callback.call(@response) if @retries > MAX_RETRIES
          end
        end
      end

      def send_request
        @state = :busy
        @response = $gtk.http_get @url
      end

      def done?
        @state == :success || @retries > MAX_RETRIES
      end

      def complete?
        @response && @response[:complete]
      end

      def success?
        complete? && success_code?
      end

      def success_code?
        code = @response[:http_response_code]
        code >= 200 && code < 300
      end
    end
  end
end

