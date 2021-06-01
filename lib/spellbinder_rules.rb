module SpellbinderRules
  SPELL_NAMES = { surrender: 'Surrender', stab: 'Stab', cause_light_wounds: 'Cause Light Wounds',
                  amnesia: 'Amnesia', shield: 'Shield', charm_person: 'Charm Person' }.freeze

  class BattleState
    attr_accessor :left_hand, :right_hand, :health, :player_name, :orders, :amnesia, :charming_target

    alias amnesia? amnesia

    def initialize(left_hand: '', right_hand: '', health: 15, player_name: '', orders: PlayerOrders.new,
                   amnesia: false, charming_target: '')
      @left_hand = left_hand
      @right_hand = right_hand
      @health = health
      @player_name = player_name
      @orders = orders
      @amnesia = amnesia
      @charming_target = charming_target
    end

    def ==(other)
      left_hand == other.left_hand && right_hand == other.right_hand && health == other.health \
                                   && orders == other.orders \
                                   && player_name == other.player_name \
                                   && amnesia? == other.amnesia? \
                                   && charming_target == other.charming_target
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

  class PlayerOrders
    attr_accessor :left_gesture, :left_spell, :left_target, :right_gesture, :right_spell, :right_target,
                  :override_gesture

    def initialize(left_gesture: '', left_spell: '', left_target: '', right_gesture: '', right_spell: '', right_target: '', override_gesture: nil)
      @left_gesture = left_gesture
      @left_spell = left_spell
      @left_target = left_target
      @right_gesture = right_gesture
      @right_spell = right_spell
      @right_target = right_target
      @override_gesture = override_gesture
    end

    def ==(other)
      left_gesture == other.left_gesture &&
        left_spell == other.left_spell &&
        left_target == other.left_target &&
        right_gesture == other.right_gesture &&
        right_spell == other.right_spell &&
        right_target == other.right_target &&
        override_gesture == other.override_gesture
    end
  end

  class OverrideGesture
    attr_accessor :target_name, :gesture, :left_hand

    alias left_hand? left_hand

    def initialize(target_name, gesture, left_hand)
      @target_name = target_name
      @gesture = gesture
      @left_hand = left_hand
    end
  end

  class SingleHandSpellInfo
    attr_accessor :gestures, :symbol, :default_target

    def initialize(gestures, symbol, default_target)
      @gestures = gestures
      @symbol = symbol
      @default_target = default_target
    end

    RECORDS = [SingleHandSpellInfo.new('>', :stab, :default_other),
               SingleHandSpellInfo.new('WFP', :cause_light_wounds, :default_other),
               SingleHandSpellInfo.new('DPP', :amnesia, :default_other),
               SingleHandSpellInfo.new('P', :shield, :default_self),
               SingleHandSpellInfo.new('PSDF', :charm_person, :default_other)]
  end

  def self.calc_next_turn(battle_states)
    log = []
    next_states = battle_states.map do |battle_state|
      underlying_state = battle_state.dup
      underlying_state.left_hand += battle_state.orders.left_gesture
      underlying_state.right_hand += battle_state.orders.right_gesture

      mid_state = MidBattleState.new(underlying_state)
    end

    # Handle enchantment effects which mess with gestures
    next_states.each do |mid_state|
      if mid_state.battle_state.amnesia?
        new_left_gesture = mid_state.battle_state.left_hand[-2]
        new_right_gesture = mid_state.battle_state.right_hand[-2]

        mid_state.battle_state.left_hand[-1] = new_left_gesture
        mid_state.battle_state.right_hand[-1] = new_right_gesture

        mid_state.battle_state.orders.left_gesture = new_left_gesture
        mid_state.battle_state.orders.right_gesture = new_right_gesture

        mid_state.battle_state.amnesia = false

        log.push(ColoredText.new('yellow',
                                 "#{mid_state.battle_state.player_name} forgets what he's doing, and makes the same gestures as last round!"))
      elsif !mid_state.battle_state.orders.override_gesture.nil?
        override_gesture = mid_state.battle_state.orders.override_gesture
        hand_name = override_gesture.left_hand? ? 'left' : 'right'

        target = find_state_by_name(next_states, override_gesture.target_name)
        if override_gesture.left_hand?
          target.battle_state.orders.left_gesture = override_gesture.gesture
          target.battle_state.left_hand[-1] = override_gesture.gesture
        else
          target.battle_state.orders.right_gesture = override_gesture.gesture
          target.battle_state.right_hand[-1] = override_gesture.gesture
        end

        mid_state.battle_state.charming_target = ''

        log.push(ColoredText.new('yellow',
                                 "#{override_gesture.target_name} is charmed into making the wrong gesture with his #{hand_name} hand."))
      end
    end

    # Determine which spells are being cast and at whom
    spells_to_cast = next_states.map do |mid_state|
      if both_hands_end_with?(mid_state.battle_state, 'P')
        SpellOrder.new(:surrender, mid_state, find_other_warlock(mid_state, next_states))
      else
        left_spell_order = parse_unihand_gesture(mid_state, next_states, use_left: true)
        right_spell_order = parse_unihand_gesture(mid_state, next_states, use_left: false)
        [left_spell_order, right_spell_order]
      end
    end.flatten.reject { |spell_order| spell_order.nil? }

    # Print that these spells are being cast.
    spells_to_cast.each do |spell_order|
      mid_state = spell_order.caster
      target = spell_order.target

      case spell_order.spell
      when :surrender
        # Nothing happens here
      when :stab
        log.push(ColoredText.new('green',
                                 "#{mid_state.battle_state.player_name} stabs at #{display_target(mid_state,
                                                                                                  target)}."))
      else
        log.push(ColoredText.new('green',
                                 "#{mid_state.battle_state.player_name} casts #{SPELL_NAMES[spell_order.spell]} on #{display_target(mid_state,
                                                                                                                                    target)}."))
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
      target = spell_order.target

      case spell_order.spell
      when :surrender
        mid_state.battle_state.health = -1

        log.push(ColoredText.new('red', "#{mid_state.battle_state.player_name} surrenders."))
      when :stab
        if target.shielded?
          log.push(ColoredText.new('dark-blue',
                                   "#{mid_state.battle_state.player_name}'s dagger glances off of #{display_target(
                                     mid_state, target
                                   )}'s shield."))
        else
          target.battle_state.health -= 1

          log.push(ColoredText.new('red',
                                   "#{mid_state.battle_state.player_name} stabs #{display_target(mid_state,
                                                                                                 target)} for 1 damage."))
        end
      when :cause_light_wounds
        target.battle_state.health -= 2

        log.push(ColoredText.new('red',
                                 "Light wounds appear on #{target.battle_state.player_name}'s body for 2 damage."))
      when :amnesia
        target.battle_state.amnesia = true

        log.push(ColoredText.new('yellow', "#{target.battle_state.player_name} starts to look blank."))
      when :charm_person
        mid_state.battle_state.charming_target = target.battle_state.player_name

        log.push(ColoredText.new('yellow',
                                 "#{target.battle_state.player_name} looks intrigued by #{mid_state.battle_state.player_name}."))
      end
    end

    next_states.each do |mid_state|
      mid_state.battle_state.orders = PlayerOrders.new
    end

    {
      log: log,
      next_states: next_states.map { |mid_state| mid_state.battle_state }
    }
  end

  def self.parse_unihand_gesture(mid_state, next_states, use_left: true)
    hand = use_left ? mid_state.battle_state.left_hand : mid_state.battle_state.right_hand
    target_name = use_left ? mid_state.battle_state.orders.left_target : mid_state.battle_state.orders.right_target
    use_default_target = target_name.nil? || target_name.empty?

    spells = SingleHandSpellInfo::RECORDS.map do |info|
      next unless hand.end_with?(info.gestures)

      case info.default_target
      when :default_other
        SpellOrder.new(info.symbol, mid_state,
                       use_default_target ? find_other_warlock(mid_state, next_states) : find_state_by_name(next_states, target_name))
      when :default_self
        SpellOrder.new(info.symbol, mid_state,
                       use_default_target ? mid_state : find_state_by_name(next_states, target_name))
      end
    end.reject { |spell_order| spell_order.nil? }

    spells.empty? ? nil : spells.first
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

  def self.find_state_by_name(next_states, target_name)
    next_states.find { |m_state| m_state.battle_state.player_name == target_name }
  end
end
