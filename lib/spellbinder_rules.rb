module SpellbinderRules
  PARALYZE_GESTURE_CONVERSIONS = { 'C' => 'F', 'S' => 'D', 'W' => 'P',
                                   'F' => 'F', 'D' => 'D', 'P' => 'P',
                                   '>' => '>', '-' => '-' }

  FEAR_GESTURE_CONVERSIONS = { 'C' => '-', 'D' => '-', 'F' => '-', 'S' => '-',
                               'W' => 'W', 'P' => 'P', '>' => '>', '-' => '-' }

  class PlayerState
    attr_accessor :left_hand, :right_hand, :health, :player_name, :orders, :haste_orders, :other_view_left_hand, :other_view_right_hand,
                  :amnesia, :confused, :charming_target, :paralyzing_target, :scared, :last_turn_anti_spelled,
                  :remaining_protection_turns, :remaining_disease_turns, :remaining_blindness_turns, :remaining_invis_turns,
                  :remaining_haste_turns

    alias amnesia? amnesia
    alias confused? confused
    alias scared? scared

    def initialize(left_hand: '', right_hand: '', health: 15, player_name: '', orders: PlayerOrders.new,
                   haste_orders: nil, other_view_left_hand: '', other_view_right_hand: '',
                   amnesia: false, confused: false, charming_target: '', paralyzing_target: '', scared: false,
                   last_turn_anti_spelled: -1, remaining_protection_turns: 0, remaining_disease_turns: -1, remaining_blindness_turns: 0,
                   remaining_invis_turns: 0, remaining_haste_turns: 0)
      @left_hand = left_hand
      @right_hand = right_hand
      @health = health
      @player_name = player_name
      @orders = orders
      @haste_orders = haste_orders
      @other_view_left_hand = other_view_left_hand
      @other_view_right_hand = other_view_right_hand
      @amnesia = amnesia
      @confused = confused
      @charming_target = charming_target
      @paralyzing_target = paralyzing_target
      @scared = scared
      @last_turn_anti_spelled = last_turn_anti_spelled
      @remaining_protection_turns = remaining_protection_turns
      @remaining_disease_turns = remaining_disease_turns
      @remaining_blindness_turns = remaining_blindness_turns
      @remaining_invis_turns = remaining_invis_turns
      @remaining_haste_turns = remaining_haste_turns
    end

    def ==(other)
      left_hand == other.left_hand && right_hand == other.right_hand && health == other.health \
                                   && player_name == other.player_name \
                                   && orders == other.orders \
                                   && haste_orders == other.haste_orders \
                                   && other_view_left_hand == other.other_view_left_hand \
                                   && other_view_right_hand == other.other_view_right_hand \
                                   && amnesia? == other.amnesia? \
                                   && charming_target == other.charming_target \
                                   && paralyzing_target == other.paralyzing_target \
                                   && scared? == other.scared? \
                                   && last_turn_anti_spelled == other.last_turn_anti_spelled \
                                   && remaining_protection_turns == other.remaining_protection_turns \
                                   && remaining_disease_turns == other.remaining_disease_turns \
                                   && remaining_blindness_turns == other.remaining_blindness_turns \
                                   && remaining_invis_turns == other.remaining_invis_turns \
                                   && remaining_haste_turns == other.remaining_haste_turns
    end
  end

  # Holds temporary data for the middle of battle, which won't need to be stored
  # afterwards
  class MidPlayerState
    attr_accessor :player_state, :shielded, :stopped_being_blind, :stopped_being_invisible
    alias shielded? shielded
    alias stopped_being_blind? stopped_being_blind
    alias stopped_being_invisible? stopped_being_invisible

    def initialize(player_state)
      @player_state = player_state
      @shielded = false
      @stopped_being_blind = false
      @stopped_being_invisible = false
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
                  :override_gesture, :paralyze_target_hand

    def initialize(left_gesture: '', left_spell: '', left_target: '', right_gesture: '', right_spell: '', right_target: '', override_gesture: nil, paralyze_target_hand: :neither)
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
        override_gesture == other.override_gesture &&
        paralyze_target_hand == other.paralyze_target_hand
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

  class DoubleHandSpellInfo
    attr_accessor :single_hand_gestures, :double_hands_gestures, :symbol, :default_target

    def initialize(single_hand_gestures, double_hands_gestures, symbol, default_target)
      @single_hand_gestures = single_hand_gestures
      @double_hands_gestures = double_hands_gestures
      @symbol = symbol
      @default_target = default_target
    end

    RECORDS = [
      DoubleHandSpellInfo.new('DSFFF', 'C', :disease, :default_other),
      DoubleHandSpellInfo.new('DWFF', 'D', :blindness, :default_other),
      DoubleHandSpellInfo.new('DFWF', 'D', :blindness, :default_other), # Is Blindness just like spell above
      DoubleHandSpellInfo.new('PP', 'WS', :invisibility, :default_self),
      DoubleHandSpellInfo.new('PWPWW', 'C', :haste, :default_self)
    ]
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
               SingleHandSpellInfo.new('SPFP', :anti_spell, :default_other),
               SingleHandSpellInfo.new('WWP', :protection, :default_self),
               SingleHandSpellInfo.new('P', :shield, :default_self),
               SingleHandSpellInfo.new('PSDF', :charm_person, :default_other),
               SingleHandSpellInfo.new('FFF', :paralysis, :default_other),
               SingleHandSpellInfo.new('DSF', :confusion, :default_other),
               SingleHandSpellInfo.new('SWD', :fear, :default_other)]
  end

  def self.calc_next_turn(player_states)
    log = []
    next_states = player_states.map do |player_state|
      underlying_state = player_state.dup
      underlying_state.left_hand += player_state.orders.left_gesture
      underlying_state.right_hand += player_state.orders.right_gesture

      mid_state = MidPlayerState.new(underlying_state)
    end
    unhastened_mid_states = []
    spells_to_cast = []

    # Handle enchantment effects which mess with gestures/change other enchantment
    # effect state
    next_states.each do |mid_state|
      if mid_state.player_state.amnesia?
        new_left_gesture = mid_state.player_state.left_hand[-2]
        new_right_gesture = mid_state.player_state.right_hand[-2]

        mid_state.player_state.left_hand[-1] = new_left_gesture
        mid_state.player_state.right_hand[-1] = new_right_gesture

        mid_state.player_state.orders.left_gesture = new_left_gesture
        mid_state.player_state.orders.right_gesture = new_right_gesture

        mid_state.player_state.amnesia = false

        log.push(ColoredText.new('yellow',
                                 "#{mid_state.player_state.player_name} forgets what he's doing, and makes the same gestures as last round!"))
      end

      if mid_state.player_state.confused?
        if random_hand == :left
          gesture = random_gesture
          mid_state.player_state.left_hand[-1] = gesture
          mid_state.player_state.orders.left_gesture = gesture

          log.push(ColoredText.new('yellow',
                                   "#{mid_state.player_state.player_name}, in their confusion, makes the wrong gesture with their left hand."))
        else
          gesture = random_gesture
          mid_state.player_state.right_hand[-1] = gesture
          mid_state.player_state.orders.right_gesture = gesture

          log.push(ColoredText.new('yellow',
                                   "#{mid_state.player_state.player_name}, in their confusion, makes the wrong gesture with their right hand."))
        end
      end

      unless mid_state.player_state.orders.override_gesture.nil?
        override_gesture = mid_state.player_state.orders.override_gesture
        hand_name = override_gesture.left_hand? ? 'left' : 'right'

        target = find_state_by_name(next_states, override_gesture.target_name)
        if override_gesture.left_hand?
          target.player_state.orders.left_gesture = override_gesture.gesture
          target.player_state.left_hand[-1] = override_gesture.gesture
        else
          target.player_state.orders.right_gesture = override_gesture.gesture
          target.player_state.right_hand[-1] = override_gesture.gesture
        end

        mid_state.player_state.charming_target = ''

        log.push(ColoredText.new('yellow',
                                 "#{override_gesture.target_name} is charmed into making the wrong gesture with his #{hand_name} hand."))
      end

      case mid_state.player_state.orders.paralyze_target_hand
      when :left
        target = find_state_by_name(next_states, mid_state.player_state.paralyzing_target)
        paralyze_gesture = PARALYZE_GESTURE_CONVERSIONS[target.player_state.left_hand[-2]]
        target.player_state.left_hand[-1] = paralyze_gesture
        target.player_state.orders.left_gesture = paralyze_gesture

        mid_state.player_state.paralyzing_target = ''

        log.push(ColoredText.new('yellow', "#{target.player_state.player_name}'s left hand is paralyzed."))
      when :right
        target = find_state_by_name(next_states, mid_state.player_state.paralyzing_target)
        paralyze_gesture = PARALYZE_GESTURE_CONVERSIONS[target.player_state.right_hand[-2]]
        target.player_state.right_hand[-1] = paralyze_gesture
        target.player_state.orders.right_gesture = paralyze_gesture

        mid_state.player_state.paralyzing_target = ''

        log.push(ColoredText.new('yellow', "#{target.player_state.player_name}'s right hand is paralyzed."))
      end

      if mid_state.player_state.scared?
        mid_state.player_state.orders.left_gesture = FEAR_GESTURE_CONVERSIONS[mid_state.player_state.orders.left_gesture]
        mid_state.player_state.left_hand[-1] = mid_state.player_state.orders.left_gesture

        mid_state.player_state.orders.right_gesture = FEAR_GESTURE_CONVERSIONS[mid_state.player_state.orders.right_gesture]
        mid_state.player_state.right_hand[-1] = mid_state.player_state.orders.right_gesture

        mid_state.player_state.scared = false

        log.push(ColoredText.new('yellow',
                                 "#{mid_state.player_state.player_name}, out of fear, fails to make a C, D, F, or S."))
      end

      if mid_state.player_state.remaining_protection_turns > 0
        mid_state.shielded = true
        mid_state.player_state.remaining_protection_turns -= 1
      end

      # -1 is the "no disease" value
      next unless mid_state.player_state.remaining_disease_turns > -1

      mid_state.player_state.remaining_disease_turns -= 1

      case mid_state.player_state.remaining_disease_turns
      when 5
        log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} is a bit nauseous."))
      when 4
        log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} is looking pale.."))
      when 3
        log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} is having difficulty breathing.."))
      when 2
        log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} is sweating feverishly."))
      when 1
        log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} staggers weakly."))
      when 0
        log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} is on the verge of death."))
      end
    end

    # Update views of other hands
    add_most_recent_hand_views(next_states)

    # Determine which spells are being cast and at whom, adding their relevant messages
    # to the log
    next_states.each do |mid_state|
      parse_spells_for(mid_state, log, next_states, spells_to_cast)

      # Handle the effects of haste
      if mid_state.player_state.remaining_haste_turns <= 0
        unhastened_mid_states.push(mid_state)
      else
        if mid_state.player_state.haste_orders.nil?
          raise ArgumentError,
                "#{mid_state.player_state.player_name}'s haste orders are nil, but he has #{mid_state.player_state.remaining_haste_turns} remaining haste turns."
        end

        log.push(ColoredText.new('yellow',
                                 "#{mid_state.player_state.player_name} is hastened, so he sneaks in an extra set of gestures."))

        mid_state.player_state.left_hand.concat(mid_state.player_state.haste_orders.left_gesture)
        mid_state.player_state.right_hand.concat(mid_state.player_state.haste_orders.right_gesture)

        mid_state.player_state.remaining_haste_turns -= 1

        parse_spells_for(mid_state, log, next_states, spells_to_cast)
      end
    end

    if unhastened_mid_states.size != next_states.size
      unhastened_mid_states.each do |mid_state|
        mid_state.player_state.left_hand.concat(' ')
        mid_state.player_state.right_hand.concat(' ')
      end

      add_most_recent_hand_views(next_states)
    end

    spells_to_cast.reject! { |sp| misses_from_blindness?(sp) || misses_from_invisibility?(sp) }

    # Evaluate shield spells first
    spells_to_cast.each do |spell_order|
      mid_state = spell_order.caster

      case spell_order.spell
      when :shield
        target = spell_order.target

        target.shielded = true
      when :protection
        target = spell_order.target

        target.shielded = true

        target.player_state.remaining_protection_turns = 2
      end
    end

    # Log shield display as necessary
    next_states.each do |mid_state|
      if mid_state.shielded? && mid_state.player_state.remaining_protection_turns == 2
        log.push(ColoredText.new('light-blue',
                                 "#{mid_state.player_state.player_name} is covered in a thick shimmering shield."))
      elsif mid_state.shielded?
        log.push(ColoredText.new('light-blue',
                                 "#{mid_state.player_state.player_name} is covered in a shimmering shield."))
      end
    end

    spells_to_cast.each do |spell_order|
      mid_state = spell_order.caster
      target = spell_order.target

      case spell_order.spell
      when :surrender
        mid_state.player_state.health = -1

        log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} surrenders."))
      when :stab
        if target.shielded?
          log.push(ColoredText.new('dark-blue',
                                   "#{mid_state.player_state.player_name}'s dagger glances off of #{display_target(
                                     mid_state, target
                                   )}'s shield."))
        else
          target.player_state.health -= 1

          log.push(ColoredText.new('red',
                                   "#{mid_state.player_state.player_name} stabs #{display_target(mid_state,
                                                                                                 target)} for 1 damage."))
        end
      when :cause_light_wounds
        target.player_state.health -= 2

        log.push(ColoredText.new('red',
                                 "Light wounds appear on #{target.player_state.player_name}'s body for 2 damage."))
      when :amnesia
        target.player_state.amnesia = true

        log.push(ColoredText.new('yellow', "#{target.player_state.player_name} starts to look blank."))
      when :charm_person
        mid_state.player_state.charming_target = target.player_state.player_name

        log.push(ColoredText.new('yellow',
                                 "#{target.player_state.player_name} looks intrigued by #{mid_state.player_state.player_name}."))
      when :paralysis
        mid_state.player_state.paralyzing_target = target.player_state.player_name

        log.push(ColoredText.new('yellow',
                                 "#{target.player_state.player_name}'s hands start to stiffen."))
      when :confusion
        target.player_state.confused = true

        log.push(ColoredText.new('yellow', "#{target.player_state.player_name} looks confused."))
      when :fear
        target.player_state.scared = true

        log.push(ColoredText.new('yellow', "#{target.player_state.player_name} looks scared."))
      when :anti_spell
        target.player_state.last_turn_anti_spelled = target.player_state.left_hand.size - 1
      when :disease
        target.player_state.remaining_disease_turns = 6

        log.push(ColoredText.new('red', "#{target.player_state.player_name} starts to look sick."))
      when :blindness
        target.player_state.remaining_blindness_turns = 3

        log.push(ColoredText.new('yellow', "#{target.player_state.player_name}'s sight begins to dim."))
      when :invisibility
        target.player_state.remaining_invis_turns = 3

        log.push(ColoredText.new('white', "There is a flash, and #{target.player_state.player_name} disappears!"))
      when :haste
        target.player_state.remaining_haste_turns = 3

        log.push(ColoredText.new('light-blue', "#{target.player_state.player_name} speeds up!"))
      end
    end

    next_states.each do |mid_state|
      if mid_state.stopped_being_blind?
        log.push(ColoredText.new('dark-blue', "#{mid_state.player_state.player_name}'s eyes begin working again."))
      end

      if mid_state.stopped_being_invisible?
        log.push(ColoredText.new('white', "#{mid_state.player_state.player_name} fades back into visibility."))
      end
    end

    next_states.each do |mid_state|
      next unless mid_state.player_state.remaining_disease_turns == 0

      log.push(ColoredText.new('red', "#{mid_state.player_state.player_name} keels over and dies of illness."))

      mid_state.player_state.health = -1
    end

    next_states.each do |mid_state|
      mid_state.player_state.orders = PlayerOrders.new
      mid_state.player_state.haste_orders = nil
    end

    {
      log: log,
      next_states: next_states.map { |mid_state| mid_state.player_state }
    }
  end

  def self.parse_unihand_gesture(mid_state, next_states, use_left: true)
    hand = viable_gestures(mid_state.player_state, left_hand: use_left)
    target_name = use_left ? mid_state.player_state.orders.left_target : mid_state.player_state.orders.right_target
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
    left_hand = viable_gestures(current_state, left_hand: true)
    right_hand = viable_gestures(current_state, left_hand: false)
    left_hand.end_with?(str) && right_hand.end_with?(str)
  end

  # MidPlayerState -> MidPlayerState
  def self.find_other_warlock(current_state, available_states)
    available_states.find { |state| state != current_state }
  end

  def self.display_target(current_state, target_state)
    current_name = current_state.player_state.player_name
    target_name = target_state.player_state.player_name

    current_name == target_name ? 'themself' : target_name
  end

  def self.find_state_by_name(next_states, target_name)
    next_states.find { |m_state| m_state.player_state.player_name == target_name }
  end

  def self.random_gesture
    ['C', 'S', 'W', 'F', 'D', 'P', '>', '-'].sample
  end

  def self.random_hand
    %i[left right].sample
  end

  # :cause_light_wounds => "Cause Light Wounds"
  def self.find_spell_name(symbol)
    symbol.to_s.split('_').map(&:capitalize).join(' ')
  end

  def self.viable_gestures(player_state, left_hand: true)
    hand = left_hand ? player_state.left_hand : player_state.right_hand
    hand[player_state.last_turn_anti_spelled + 1..hand.size].gsub(' ', '')
  end

  def self.double_ends_with?(player_state, single_ending, double_ending)
    left_hand = viable_gestures(player_state, left_hand: true)
    right_hand = viable_gestures(player_state, left_hand: false)
    left_hand.end_with?(double_ending) && right_hand.end_with?(double_ending) \
      && (left_hand[0..left_hand.size - 1 - double_ending.size].end_with?(single_ending) || right_hand[0..right_hand.size - 1 - double_ending.size].end_with?(single_ending))
  end

  # Useful in testing: this helps you quickly build initial PlayerState hand views
  def self.copy_init_views(player_states)
    player_states[0].other_view_left_hand = player_states[1].left_hand
    player_states[0].other_view_right_hand = player_states[1].right_hand
    player_states[1].other_view_left_hand = player_states[0].left_hand
    player_states[1].other_view_right_hand = player_states[0].right_hand
  end

  def self.misses_from_blindness?(spell_order)
    spell_order.caster.player_state.remaining_blindness_turns > 0 && spell_order.target != spell_order.caster
  end

  def self.misses_from_invisibility?(spell_order)
    spell_order.target.player_state.remaining_invis_turns > 0 && spell_order.target != spell_order.caster
  end

  # TODO(Chris): Finish this refactor method
  def self.parse_double_hand_spells(mid_state, next_states)
    viable_left_hand = viable_gestures(mid_state.player_state, left_hand: true)
    viable_right_hand = viable_gestures(mid_state.player_state, left_hand: false)

    DoubleHandSpellInfo::RECORDS.each do |info|
      single_size = info.single_hand_gestures.size
      double_size = info.double_hands_gestures.size

      next if single_size + double_size > viable_left_hand.size

      sub_left_hand = viable_left_hand[viable_left_hand.size - (single_size + double_size), single_size]
      sub_right_hand = viable_right_hand[viable_right_hand.size - (single_size + double_size), single_size]

      next unless (sub_left_hand.end_with?(info.single_hand_gestures) || sub_right_hand.end_with?(info.single_hand_gestures)) &&
                  viable_left_hand.end_with?(info.double_hands_gestures) && viable_right_hand.end_with?(info.double_hands_gestures)

      case info.default_target
      when :default_other
        return SpellOrder.new(info.symbol, mid_state, find_other_warlock(mid_state, next_states))
      when :default_self
        return SpellOrder.new(info.symbol, mid_state, mid_state)
      end
    end

    nil
  end

  def self.parse_spells_for(mid_state, log, next_states, spells_to_cast)
    if both_hands_end_with?(mid_state.player_state, 'P')
      spells_to_cast.push(SpellOrder.new(:surrender, mid_state, find_other_warlock(mid_state, next_states)))
      log_casting(log, spells_to_cast[-1])
    elsif (spell_order = parse_double_hand_spells(mid_state, next_states))
      spells_to_cast.push(spell_order)
      log_casting(log, spells_to_cast[-1])
    else
      left_spell_order = parse_unihand_gesture(mid_state, next_states, use_left: true)
      right_spell_order = parse_unihand_gesture(mid_state, next_states, use_left: false)

      unless left_spell_order.nil?
        spells_to_cast.push(left_spell_order)
        log_casting(log, spells_to_cast[-1])
      end

      unless right_spell_order.nil?
        spells_to_cast.push(right_spell_order)
        log_casting(log, spells_to_cast[-1])
      end
    end
  end

  def self.add_most_recent_hand_views(next_states)
    [[0, 1], [1, 0]].each do |pair|
      mid_state = next_states[pair[0]]
      other_state = next_states[pair[1]]

      if mid_state.player_state.remaining_blindness_turns > 0
        mid_state.player_state.other_view_left_hand << '?'
        mid_state.player_state.other_view_right_hand << '?'

        mid_state.player_state.remaining_blindness_turns -= 1

        mid_state.stopped_being_blind = true if mid_state.player_state.remaining_blindness_turns <= 0
      elsif other_state.player_state.remaining_invis_turns > 0
        mid_state.player_state.other_view_left_hand << '?'
        mid_state.player_state.other_view_right_hand << '?'

        other_state.player_state.remaining_invis_turns -= 1

        other_state.stopped_being_invisible = true if other_state.player_state.remaining_invis_turns <= 0
      else
        mid_state.player_state.other_view_left_hand << other_state.player_state.left_hand[-1]
        mid_state.player_state.other_view_right_hand << other_state.player_state.right_hand[-1]
      end
    end
  end

  def self.log_casting(log, spell_order)
    mid_state = spell_order.caster
    target = spell_order.target

    cast_output = case spell_order.spell
                  when :surrender
                  # Nothing happens here
                  when :stab
                    ColoredText.new('green',
                                    "#{mid_state.player_state.player_name} stabs at #{display_target(mid_state,
                                                                                                     target)}")
                  else
                    ColoredText.new('green',
                                    "#{mid_state.player_state.player_name} casts #{find_spell_name(spell_order.spell)} on #{display_target(mid_state,
                                                                                                                                           target)}")
                  end

    return if cast_output.nil?

    cast_output.text << if misses_from_blindness?(spell_order)
                          ', but misses due to blindness.'
                        elsif misses_from_invisibility?(spell_order)
                          ', but misses due to invisibility.'
                        else
                          '.'
                        end

    log.push(cast_output)
  end
end
