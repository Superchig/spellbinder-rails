require './lib/spellbinder_rules'

include SpellbinderRules

describe SpellbinderRules do
  describe '.calc_next_turn: ' do
    describe 'Surrendering' do
      initial_battle_states = [BattleState.new(orders_left_gesture: 'P',
                                               orders_right_gesture: 'P', player_name: 'first@example.com'),
                               BattleState.new(orders_left_gesture: 'P',
                                               orders_right_gesture: 'P', player_name: 'second@example.com')]

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
        initial_battle_states = [BattleState.new(orders_left_gesture: '>',
                                                 orders_right_gesture: '-', player_name: 'first@example.com'),
                                 BattleState.new(orders_left_gesture: 'S',
                                                 orders_right_gesture: 'W', player_name: 'second@example.com')]

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
        initial_battle_states = [BattleState.new(left_hand: 'WF', orders_left_gesture: 'P',
                                                 right_hand: 'PP', orders_right_gesture: 'S', player_name: 'first@example.com'),
                                 BattleState.new(left_hand: '--', orders_left_gesture: 'S',
                                                 right_hand: '--', orders_right_gesture: 'W', player_name: 'second@example.com')]

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
        initial_battle_states = [BattleState.new(left_hand: '--', orders_left_gesture: '>',
                                                 right_hand: '--', orders_right_gesture: '-', player_name: 'first@example.com'),
                                 BattleState.new(left_hand: '--', orders_left_gesture: 'P',
                                                 right_hand: '--', orders_right_gesture: '-', player_name: 'second@example.com')]

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
        initial_battle_states = [BattleState.new(orders_left_gesture: '>',
                                                 orders_right_gesture: '-', player_name: 'first@example.com',
                                                 orders_left_target: 'first@example.com'),
                                 BattleState.new(orders_left_gesture: 'S',
                                                 orders_right_gesture: 'W', player_name: 'second@example.com')]

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
        initial_battle_states = [BattleState.new(orders_left_gesture: '>',
                                                 orders_right_gesture: '-', player_name: 'first@example.com',
                                                 orders_left_target: 'second@example.com'),
                                 BattleState.new(orders_left_gesture: 'S',
                                                 orders_right_gesture: 'W', player_name: 'second@example.com')]

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
        initial_battle_states = [BattleState.new(orders_left_gesture: '-',
                                                 orders_right_gesture: '>', player_name: 'first@example.com'),
                                 BattleState.new(orders_left_gesture: 'S',
                                                 orders_right_gesture: 'W', player_name: 'second@example.com')]

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
        initial_battle_states = [BattleState.new(orders_left_gesture: 'P',
                                                 orders_right_gesture: '>', player_name: 'first@example.com',
                                                 orders_left_target: 'first@example.com'),
                                 BattleState.new(orders_left_gesture: 'S',
                                                 orders_right_gesture: 'W', player_name: 'second@example.com')]

        expected_battle_states = [BattleState.new(left_hand: 'P', right_hand: '>', health: 14, player_name: 'first@example.com'),
                                  BattleState.new(left_hand: 'S', right_hand: 'W', health: 15,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
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
