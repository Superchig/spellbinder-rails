module SpellbinderRules
  class BattleState
    attr_accessor :left_hand, :right_hand, :health, :player_name, :orders_left_gesture, :orders_left_spell, :orders_left_target,
                  :orders_right_gesture, :orders_right_spell, :orders_right_target, :amnesia

    alias amnesia? amnesia

    def initialize(left_hand: '', right_hand: '', health: 15, player_name: '', orders_left_gesture: '',
                   orders_left_spell: '', orders_left_target: '', orders_right_gesture: '', orders_right_spell: '', orders_right_target: '')
      @left_hand = left_hand
      @right_hand = right_hand
      @health = health
      @player_name = player_name
      @orders_left_gesture = orders_left_gesture
      @orders_left_spell = orders_left_spell
      @orders_left_target = orders_left_target
      @orders_right_gesture = orders_right_gesture
      @orders_right_spell = orders_right_spell
      @orders_right_target = orders_right_target
      @amnesia = false
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

  # Holds temporary data for the middle of battle, which won't need to be stored
  # afterwards
  class MidBattleState
    attr_accessor :battle_state, :shielded
    alias shielded? shielded

    def initialize(battle_state)
      @battle_state = battle_state
      @shielded = false
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

  class SpellOrder
    attr_reader :spell, :caster, :target

    def initialize(spell, caster, target = nil)
      @spell = spell
      @caster = caster
      @target = target
    end
  end

  def self.calc_next_turn(battle_states)
    log = []
    next_states = battle_states.map do |battle_state|
      underlying_state = battle_state.dup
      underlying_state.left_hand += battle_state.orders_left_gesture
      underlying_state.right_hand += battle_state.orders_right_gesture

      mid_state = MidBattleState.new(underlying_state)
    end

    # Determine which spells are being cast and at whom
    spells_to_cast = next_states.map do |mid_state|
      orders_left_target = mid_state.battle_state.orders_left_target
      orders_right_target = mid_state.battle_state.orders_right_target

      if both_hands_end_with?(mid_state.battle_state, 'P')
        SpellOrder.new(:surrender, mid_state, find_other_warlock(mid_state, next_states))
      elsif either_hand_ends_with?(mid_state.battle_state, '>')
        if orders_left_target.nil? || orders_left_target.empty?
          SpellOrder.new(:stab, mid_state, find_other_warlock(mid_state, next_states))
        else
          SpellOrder.new(:stab, mid_state, next_states.find do |m_state|
                                             m_state.battle_state.player_name == mid_state.battle_state.player_name
                                           end)
        end
      elsif either_hand_ends_with?(mid_state.battle_state, 'WFP')
        SpellOrder.new(:cause_light_wounds, mid_state, find_other_warlock(mid_state, next_states))
      elsif either_hand_ends_with?(mid_state.battle_state, 'P')
        SpellOrder.new(:shield, mid_state, mid_state)
      end
    end.reject { |spell_order| spell_order.nil? }

    # Print that these spells are being cast.
    spells_to_cast.each do |spell_order|
      mid_state = spell_order.caster
      target = spell_order.target

      case spell_order.spell
      when :surrender
        # Nothing happens here
      when :stab
        log.push(ColoredText.new('green',
                                 "#{mid_state.battle_state.player_name} stabs at #{display_target(mid_state, target)}."))
      when :cause_light_wounds
        log.push(ColoredText.new('green',
                                 "#{mid_state.battle_state.player_name} casts Cause Light Wounds on #{display_target(mid_state, target)}."))
      when :shield
        log.push(ColoredText.new('green', "#{mid_state.battle_state.player_name} casts Shield on #{display_target(mid_state, target)}."))
      end
    end

    # Evaluate shield spell first
    spells_to_cast.each do |spell_order|
      mid_state = spell_order.caster

      case spell_order.spell
      when :shield
        target = spell_order.target

        target.shielded = true

        log.push(ColoredText.new('light-blue',
                                 "#{mid_state.battle_state.player_name} is covered in a shimmering shield."))
      end
    end

    spells_to_cast.each do |spell_order|
      mid_state = spell_order.caster

      case spell_order.spell
      when :surrender
        mid_state.battle_state.health = -1

        log.push(ColoredText.new('red', "#{mid_state.battle_state.player_name} surrenders."))
      when :stab
        target = spell_order.target

        if target.shielded?
          log.push(ColoredText.new('dark-blue',
                                   "#{mid_state.battle_state.player_name}'s dagger glances off of #{display_target(mid_state, target)}'s shield."))
        else
          target.battle_state.health -= 1

          log.push(ColoredText.new('red',
                                   "#{mid_state.battle_state.player_name} stabs #{display_target(mid_state, target)} for 1 damage."))
        end
      when :cause_light_wounds
        target = spell_order.target
        target.battle_state.health -= 2

        log.push(ColoredText.new('red',
                                 "Light wounds appear on #{display_target(mid_state, target)}'s body for 2 damage."))
      end
    end

    next_states.each do |mid_state|
      mid_state.battle_state.orders_left_gesture = ''
      mid_state.battle_state.orders_left_spell = ''
      mid_state.battle_state.orders_left_target = ''
      mid_state.battle_state.orders_right_gesture = ''
      mid_state.battle_state.orders_right_spell = ''
      mid_state.battle_state.orders_right_target = ''
    end

    {
      log: log,
      next_states: next_states.map { |mid_state| mid_state.battle_state }
    }
  end

  def self.both_hands_end_with?(current_state, str)
    current_state.left_hand.end_with?(str) && current_state.right_hand.end_with?(str)
  end

  def self.either_hand_ends_with?(current_state, str)
    current_state.left_hand.end_with?(str) || current_state.right_hand.end_with?(str)
  end

  # MidBattleState -> MidBattleState
  def self.find_other_warlock(current_state, available_states)
    available_states.find { |state| state != current_state }
  end

  def self.display_target(current_state, target_state)
    current_name = current_state.battle_state.player_name
    target_name = target_state.battle_state.player_name

    current_name == target_name ? 'themself' : target_name
  end
end
