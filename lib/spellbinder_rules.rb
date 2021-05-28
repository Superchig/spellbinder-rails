module SpellbinderRules
  class BattleState
    attr_accessor :left_hand, :right_hand, :health, :orders_left_gesture, :orders_left_spell, :orders_left_target,
                  :orders_right_gesture, :orders_right_spell, :orders_right_target, :player_name

    def initialize(left_hand: '', right_hand: '', health: 15, orders_left_gesture: '',
                   orders_left_spell: '', orders_left_target: '', orders_right_gesture: '', orders_right_spell: '', orders_right_target: '', player_name: -1)
      @left_hand = left_hand
      @right_hand = right_hand
      @health = health
      @orders_left_gesture = orders_left_gesture
      @orders_left_spell = orders_left_spell
      @orders_left_target = orders_left_target
      @orders_right_gesture = orders_right_gesture
      @orders_right_spell = orders_right_spell
      @orders_right_target = orders_right_target
      @player_name = player_name
    end

    def ==(other)
      left_hand == other.left_hand && right_hand == other.right_hand && health == other.health \
                                   && orders_left_gesture == other.orders_left_gesture \
                                   && orders_left_spell == other.orders_left_spell \
                                   && orders_left_target = other.orders_left_target \
                                   && orders_right_gesture == other.orders_right_gesture \
                                   && orders_right_spell == other.orders_right_spell \
                                   && orders_right_target == other.orders_right_target \
                                   && player_name == other.player_name
    end
  end

  class ColoredText
    attr_reader :color, :text

    def initialize(color, text)
      @color = color
      @text = text
    end

    def ==(other)
      color == other.color && text == other.text
    end
  end

  def self.calc_next_turn(battle_states)
    log = []
    next_states = battle_states.map do |battle_state|
      BattleState.new(left_hand: battle_state.left_hand + battle_state.orders_left_gesture,
                      right_hand: battle_state.right_hand + battle_state.orders_right_gesture,
                      health: battle_state.health, player_name: battle_state.player_name)
    end

    next_states.each do |next_state|
      if next_state.left_hand.end_with?('P') && next_state.left_hand.end_with?('P')
        next_state.health = -1

        log.push(ColoredText.new('red', "#{next_state.player_name} surrenders."))
      elsif next_state.left_hand.end_with?('>') || next_state.right_hand.end_with?('>')
        target = next_states.find { |state| state != next_state }
        target.health -= 1;

        log.push(ColoredText.new('red', "#{next_state.player_name} stabs #{target.player_name}, dealing 1 damage."))
      end
    end

    { log: log, next_states: next_states }
  end
end
