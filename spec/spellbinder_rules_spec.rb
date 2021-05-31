require './lib/spellbinder_rules'

include SpellbinderRules

describe SpellbinderRules do
  describe '.calc_next_turn: ' do
    describe 'Surrendering' do
      initial_battle_states = [BattleState.new(player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'P',
                                                                        right_gesture: 'P')),
                               BattleState.new(player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'P',
                                                                        right_gesture: 'P'))]

      expected_battle_states = [BattleState.new(left_hand: 'P', right_hand: 'P', health: -1, player_name: 'first@example.com'),
                                BattleState.new(left_hand: 'P', right_hand: 'P', health: -1,
                                                player_name: 'second@example.com')]

      expected_log = [ColoredText.new('red', 'first@example.com surrenders.'),
                      ColoredText.new('red', 'second@example.com surrenders.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      it 'causes players to lose all health' do
        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing players' do
      it 'logs and damages them' do
        initial_battle_states = [BattleState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-')),
                                 BattleState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [BattleState.new(left_hand: '>', right_hand: '-', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'The spell "Cause Light Wounds"' do
      it 'damages the enemy player' do
        initial_battle_states = [BattleState.new(left_hand: 'WF',
                                                 right_hand: 'PP', player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'P', right_gesture: 'S')),
                                 BattleState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [BattleState.new(left_hand: 'WFP', right_hand: 'PPS', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: '--S', right_hand: '--W', health: 13,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green',
                                        'first@example.com casts Cause Light Wounds on second@example.com.'),
                        ColoredText.new('red', 'Light wounds appear on second@example.com\'s body for 2 damage.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'The spell "Shield"' do
      it 'protects the caster from stabs on the turn in which it is cast' do
        initial_battle_states = [BattleState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-')),
                                 BattleState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'P', right_gesture: '-'))]

        expected_battle_states = [BattleState.new(left_hand: '-->', right_hand: '---', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: '--P', right_hand: '---', health: 15,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green',
                                        'first@example.com stabs at second@example.com.'),
                        ColoredText.new('green', 'second@example.com casts Shield on themself.'),
                        ColoredText.new('light-blue', 'second@example.com is covered in a shimmering shield.'),
                        ColoredText.new('dark-blue',
                                        'first@example.com\'s dagger glances off of second@example.com\'s shield.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing yourself' do
      it 'actually uses yourself as the target' do
        initial_battle_states = [BattleState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-',
                                                                          left_target: 'first@example.com')),
                                 BattleState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [BattleState.new(left_hand: '>', right_hand: '-', health: 14, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: 'S', right_hand: 'W', health: 15,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at themself.'),
                        ColoredText.new('red', 'first@example.com stabs themself for 1 damage.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing a specific other warlock' do
      it 'should actually target that warlock' do
        initial_battle_states = [BattleState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-',
                                                                          left_target: 'second@example.com')),
                                 BattleState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [BattleState.new(left_hand: '>', right_hand: '-', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing with the right hand' do
      it 'should actually stab the opponent' do
        initial_battle_states = [BattleState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '-', right_gesture: '>')),
                                 BattleState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [BattleState.new(left_hand: '-', right_hand: '>', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing with the right hand' do
      it 'should not use the left hand\'s target' do
        initial_battle_states = [BattleState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '-', right_gesture: '>',
                                                                          left_target: 'first@example.com')),
                                 BattleState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [BattleState.new(left_hand: '-', right_hand: '>', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end
  end

  describe 'Casting "Cause Light Wounds" with the right hand' do
    it 'should still harm the opponent' do
      initial_battle_states = [BattleState.new(left_hand: '--',
                                               right_hand: 'WF', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'P')),
                               BattleState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

      expected_battle_states = [BattleState.new(left_hand: '---', right_hand: 'WFP', health: 15, player_name: 'first@example.com'),
                                BattleState.new(left_hand: '--S', right_hand: '--W', health: 13,
                                                player_name: 'second@example.com')]

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Cause Light Wounds on second@example.com.'),
                      ColoredText.new('red', 'Light wounds appear on second@example.com\'s body for 2 damage.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)
    end
  end

  describe 'Casting "Cause Light Wounds" at yourself' do
    it 'should harm yourself' do
      initial_battle_states = [BattleState.new(left_hand: '--',
                                               right_hand: 'WF', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'P', right_target: 'first@example.com')),
                               BattleState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

      expected_battle_states = [BattleState.new(left_hand: '---', right_hand: 'WFP', health: 13, player_name: 'first@example.com'),
                                BattleState.new(left_hand: '--S', right_hand: '--W', health: 15,
                                                player_name: 'second@example.com')]

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Cause Light Wounds on themself.'),
                      ColoredText.new('red', 'Light wounds appear on first@example.com\'s body for 2 damage.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)
    end
  end

  describe 'Casting "Amnesia"' do
    it 'should force the enemy warlock to repeat identically their gestures in the next turn' do
      initial_battle_states_1 = [BattleState.new(left_hand: '--',
                                                 right_hand: 'DP', player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'P')),
                                 BattleState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

      expected_battle_states_1 = [BattleState.new(left_hand: '---', right_hand: 'DPP', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: '--S', right_hand: '--W', health: 15,
                                                  player_name: 'second@example.com', amnesia: true)]

      expected_log_1 = [ColoredText.new('green',
                                        'first@example.com casts Amnesia on second@example.com.'),
                        ColoredText.new('yellow', 'second@example.com starts to look blank.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states_1)

      expect(result[:log]).to eq(expected_log_1)
      expect(result[:next_states]).to eq(expected_battle_states_1)

      initial_battle_states_2 = expected_battle_states_1.dup
      initial_battle_states_2[0].orders.left_gesture = '-'
      initial_battle_states_2[0].orders.right_gesture = '-'
      initial_battle_states_2[1].orders.left_gesture = '-'
      initial_battle_states_2[1].orders.right_gesture = '-'

      expected_battle_states_2 = [BattleState.new(left_hand: '----', right_hand: 'DPP-', health: 15, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: '--SS', right_hand: '--WW', health: 15,
                                                  player_name: 'second@example.com')]

      expected_log_2 = [ColoredText.new('yellow',
                                        'second@example.com forgets what he\'s doing, and makes the same gestures as last round!')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe ColoredText do
    it 'equals another ColoredText when its sub-values are equal' do
      colored_text1 = ColoredText.new('red', 'first@example.com surrenders.')
      colored_text2 = ColoredText.new('red', 'first@example.com surrenders.')

      expect(colored_text1).to eq(colored_text2)
    end
  end
end
