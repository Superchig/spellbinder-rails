require './lib/spellbinder_rules'

include SpellbinderRules

describe SpellbinderRules do
  describe '.calc_next_turn:' do
    describe 'Surrendering' do
      initial_battle_states = [PlayerState.new(player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'P',
                                                                        right_gesture: 'P')),
                               PlayerState.new(player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'P',
                                                                        right_gesture: 'P'))]

      expected_battle_states = [PlayerState.new(left_hand: 'P', right_hand: 'P', health: -1, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: 'P', right_hand: 'P', health: -1,
                                                player_name: 'second@example.com')]

      expected_log = [ColoredText.new('red', 'first@example.com surrenders.'),
                      ColoredText.new('red', 'second@example.com surrenders.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      it 'causes players to lose all health' do
        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing players' do
      it 'logs and damages them' do
        initial_battle_states = [PlayerState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-')),
                                 PlayerState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [PlayerState.new(left_hand: '>', right_hand: '-', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:log]).to eq(expected_log)
        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'The spell "Cause Light Wounds"' do
      it 'damages the enemy player' do
        initial_battle_states = [PlayerState.new(left_hand: 'WF',
                                                 right_hand: 'PP', player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'P', right_gesture: 'S')),
                                 PlayerState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [PlayerState.new(left_hand: 'WFP', right_hand: 'PPS', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--S', right_hand: '--W', health: 13,
                                                  player_name: 'second@example.com')]

        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

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
        initial_battle_states = [PlayerState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-')),
                                 PlayerState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'P', right_gesture: '-'))]

        expected_battle_states = [PlayerState.new(left_hand: '-->', right_hand: '---', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--P', right_hand: '---', health: 15,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green',
                                        'first@example.com stabs at second@example.com.'),
                        ColoredText.new('green', 'second@example.com casts Shield on themself.'),
                        ColoredText.new('light-blue', 'second@example.com is covered in a shimmering shield.'),
                        ColoredText.new('dark-blue',
                                        'first@example.com\'s dagger glances off of second@example.com\'s shield.')]

        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing yourself' do
      it 'actually uses yourself as the target' do
        initial_battle_states = [PlayerState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-',
                                                                          left_target: 'first@example.com')),
                                 PlayerState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [PlayerState.new(left_hand: '>', right_hand: '-', health: 14, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: 'S', right_hand: 'W', health: 15,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at themself.'),
                        ColoredText.new('red', 'first@example.com stabs themself for 1 damage.')]

        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing a specific other warlock' do
      it 'should actually target that warlock' do
        initial_battle_states = [PlayerState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '>', right_gesture: '-',
                                                                          left_target: 'second@example.com')),
                                 PlayerState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [PlayerState.new(left_hand: '>', right_hand: '-', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing with the right hand' do
      it 'should actually stab the opponent' do
        initial_battle_states = [PlayerState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '-', right_gesture: '>')),
                                 PlayerState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [PlayerState.new(left_hand: '-', right_hand: '>', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end

    describe 'Stabbing with the right hand' do
      it 'should not use the left hand\'s target' do
        initial_battle_states = [PlayerState.new(player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '-', right_gesture: '>',
                                                                          left_target: 'first@example.com')),
                                 PlayerState.new(player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

        expected_battle_states = [PlayerState.new(left_hand: '-', right_hand: '>', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: 'S', right_hand: 'W', health: 14,
                                                  player_name: 'second@example.com')]

        expected_log = [ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
                        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')]

        SpellbinderRules.copy_init_views(initial_battle_states)
        SpellbinderRules.copy_init_views(expected_battle_states)

        result = SpellbinderRules.calc_next_turn(initial_battle_states)

        expect(result[:next_states]).to eq(expected_battle_states)
      end
    end
  end

  describe 'Casting "Cause Light Wounds" with the right hand' do
    it 'should still harm the opponent' do
      initial_battle_states = [PlayerState.new(left_hand: '--',
                                               right_hand: 'WF', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'P')),
                               PlayerState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

      expected_battle_states = [PlayerState.new(left_hand: '---', right_hand: 'WFP', health: 15, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: '--S', right_hand: '--W', health: 13,
                                                player_name: 'second@example.com')]

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Cause Light Wounds on second@example.com.'),
                      ColoredText.new('red', 'Light wounds appear on second@example.com\'s body for 2 damage.')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:next_states]).to eq(expected_battle_states)
    end
  end

  describe 'Casting "Cause Light Wounds" at yourself' do
    it 'should harm yourself' do
      initial_battle_states = [PlayerState.new(left_hand: '--',
                                               right_hand: 'WF', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'P', right_target: 'first@example.com')),
                               PlayerState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

      expected_battle_states = [PlayerState.new(left_hand: '---', right_hand: 'WFP', health: 13, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: '--S', right_hand: '--W', health: 15,
                                                player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

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
      initial_battle_states_1 = [PlayerState.new(left_hand: '--',
                                                 right_hand: 'DP', player_name: 'first@example.com',
                                                 orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'P')),
                                 PlayerState.new(left_hand: '--',
                                                 right_hand: '--', player_name: 'second@example.com',
                                                 orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

      expected_battle_states_1 = [PlayerState.new(left_hand: '---', right_hand: 'DPP', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--S', right_hand: '--W', health: 15,
                                                  player_name: 'second@example.com', amnesia: true)]

      SpellbinderRules.copy_init_views(initial_battle_states_1)
      SpellbinderRules.copy_init_views(expected_battle_states_1)

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

      expected_battle_states_2 = [PlayerState.new(left_hand: '----', right_hand: 'DPP-', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--SS', right_hand: '--WW', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('yellow',
                                        'second@example.com forgets what he\'s doing, and makes the same gestures as last round!')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe 'A warlock casting "Charm Person"' do
    it 'can override the gesture for another player' do
      initial_battle_states = [PlayerState.new(left_hand: '---',
                                               right_hand: 'PSD', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'F')),
                               PlayerState.new(left_hand: '---',
                                               right_hand: '---', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'W'))]

      expected_battle_states = [PlayerState.new(left_hand: '----', right_hand: 'PSDF', health: 15, player_name: 'first@example.com',
                                                charming_target: 'second@example.com'),
                                PlayerState.new(left_hand: '---S', right_hand: '---W', health: 15,
                                                player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Charm Person on second@example.com.'),
                      ColoredText.new('yellow',
                                      'second@example.com looks intrigued by first@example.com.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders.left_gesture = '-'
      initial_battle_states_2[0].orders.right_gesture = '-'
      initial_battle_states_2[1].orders.left_gesture = 'S'
      initial_battle_states_2[1].orders.right_gesture = 'W'
      initial_battle_states_2[0].orders.override_gesture = OverrideGesture.new('second@example.com', '-', false)

      expected_battle_states_2 = [PlayerState.new(left_hand: '-----', right_hand: 'PSDF-', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '---SS', right_hand: '---W-', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('yellow',
                                        'second@example.com is charmed into making the wrong gesture with his right hand.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe 'Casting "Paralysis"' do
    it 'locks a warlock\'s hand in place' do
      initial_battle_states = [PlayerState.new(left_hand: 'FF',
                                               right_hand: '--', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'F', right_gesture: '-')),
                               PlayerState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'D', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'FFF', right_hand: '---', health: 15, player_name: 'first@example.com',
                                                paralyzing_target: 'second@example.com'),
                                PlayerState.new(left_hand: '--D', right_hand: '---', health: 15,
                                                player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Paralysis on second@example.com.'),
                      ColoredText.new('yellow',
                                      'second@example.com\'s hands start to stiffen.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders.left_gesture = '-'
      initial_battle_states_2[0].orders.right_gesture = '-'
      initial_battle_states_2[0].orders.paralyze_target_hand = :left
      initial_battle_states_2[1].orders.left_gesture = 'F'
      initial_battle_states_2[1].orders.right_gesture = '-'

      expected_battle_states_2 = [PlayerState.new(left_hand: 'FFF-', right_hand: '----', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--DD', right_hand: '----', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('yellow',
                                        'second@example.com\'s left hand is paralyzed.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe 'Casting "Paralysis" on a hand with "S"' do
    it 'transforms the "S" into a "D"' do
      initial_battle_states = [PlayerState.new(left_hand: 'FF',
                                               right_hand: '--', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'F', right_gesture: '-')),
                               PlayerState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'S', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'FFF', right_hand: '---', health: 15, player_name: 'first@example.com',
                                                paralyzing_target: 'second@example.com'),
                                PlayerState.new(left_hand: '--S', right_hand: '---', health: 15,
                                                player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Paralysis on second@example.com.'),
                      ColoredText.new('yellow',
                                      'second@example.com\'s hands start to stiffen.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders.left_gesture = '-'
      initial_battle_states_2[0].orders.right_gesture = '-'
      initial_battle_states_2[0].orders.paralyze_target_hand = :left
      initial_battle_states_2[1].orders.left_gesture = 'F'
      initial_battle_states_2[1].orders.right_gesture = '-'

      expected_battle_states_2 = [PlayerState.new(left_hand: 'FFF-', right_hand: '----', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--SD', right_hand: '----', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('yellow',
                                        'second@example.com\'s left hand is paralyzed.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe 'Casting "Confusion"' do
    it 'changes one of the target\'s hands into a random gesture' do
      allow(SpellbinderRules).to receive(:random_gesture) { 'S' }
      allow(SpellbinderRules).to receive(:random_hand) { :right }

      initial_battle_states = [PlayerState.new(left_hand: 'DS',
                                               right_hand: '--', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'F', right_gesture: '-')),
                               PlayerState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'W', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'DSF', right_hand: '---', health: 15, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: '--W', right_hand: '---', health: 15,
                                                player_name: 'second@example.com', confused: true)]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Confusion on second@example.com.'),
                      ColoredText.new('yellow',
                                      'second@example.com looks confused.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders.left_gesture = '-'
      initial_battle_states_2[0].orders.right_gesture = '-'
      initial_battle_states_2[1].orders.left_gesture = '-'
      initial_battle_states_2[1].orders.right_gesture = '-'

      expected_battle_states_2 = [PlayerState.new(left_hand: 'DSF-', right_hand: '----', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--W-', right_hand: '---S', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('yellow',
                                        'second@example.com, in their confusion, makes the wrong gesture with their right hand.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe 'Casting "Fear"' do
    it 'prevents the target from performing a C, D, F, or S gesture' do
      initial_battle_states = [PlayerState.new(left_hand: 'SW',
                                               right_hand: '--', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'D', right_gesture: '-')),
                               PlayerState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'W', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'SWD', right_hand: '---', health: 15, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: '--W', right_hand: '---', health: 15,
                                                player_name: 'second@example.com', scared: true)]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Fear on second@example.com.'),
                      ColoredText.new('yellow',
                                      'second@example.com looks scared.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders.left_gesture = '-'
      initial_battle_states_2[0].orders.right_gesture = '-'
      initial_battle_states_2[1].orders.left_gesture = 'D'
      initial_battle_states_2[1].orders.right_gesture = 'F'

      expected_battle_states_2 = [PlayerState.new(left_hand: 'SWD-', right_hand: '----', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--W-', right_hand: '----', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('yellow',
                                        'second@example.com, out of fear, fails to make a C, D, F, or S.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe 'Casting "Anti Spell"' do
    it 'prevents the target from using gestures made on or before the turn' do
      initial_battle_states = [PlayerState.new(left_hand: 'SPF',
                                               right_hand: '---', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'P', right_gesture: '-')),
                               PlayerState.new(left_hand: '---',
                                               right_hand: '--W', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'F'))]

      expected_battle_states = [PlayerState.new(left_hand: 'SPFP', right_hand: '----', health: 15, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: '----', right_hand: '--WF', health: 15,
                                                player_name: 'second@example.com', last_turn_anti_spelled: 3)]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Anti Spell on second@example.com.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders.left_gesture = '-'
      initial_battle_states_2[0].orders.right_gesture = '-'
      initial_battle_states_2[1].orders.left_gesture = '-'
      initial_battle_states_2[1].orders.right_gesture = 'P'

      expected_battle_states_2 = [PlayerState.new(left_hand: 'SPFP-', right_hand: '-----', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '-----', right_hand: '--WFP', health: 15,
                                                  player_name: 'second@example.com', last_turn_anti_spelled: 3)]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('green',
                                        'second@example.com casts Shield on themself.'),
                        ColoredText.new('light-blue',
                                        'second@example.com is covered in a shimmering shield.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe 'Casting "Protection"' do
    it 'protects the caster for this turn and the following two as if using a Shield spell.' do
      initial_battle_states = [PlayerState.new(left_hand: 'WW',
                                               right_hand: '--', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'P', right_gesture: '-')),
                               PlayerState.new(left_hand: '--',
                                               right_hand: '--', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: '>'))]

      expected_battle_states = [PlayerState.new(left_hand: 'WWP', right_hand: '---', health: 15, player_name: 'first@example.com',
                                                remaining_protection_turns: 2),
                                PlayerState.new(left_hand: '---', right_hand: '-->', health: 15,
                                                player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Protection on themself.'),
                      ColoredText.new('green',
                                      'second@example.com stabs at first@example.com.'),
                      ColoredText.new('light-blue',
                                      'first@example.com is covered in a thick shimmering shield.'),
                      ColoredText.new('dark-blue',
                                      'second@example.com\'s dagger glances off of first@example.com\'s shield.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')
      initial_battle_states_2[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '>')

      expected_battle_states_2 = [PlayerState.new(left_hand: 'WWP-', right_hand: '----', health: 15, player_name: 'first@example.com', remaining_protection_turns: 1),
                                  PlayerState.new(left_hand: '----', right_hand: '-->>', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('green',
                                        'second@example.com stabs at first@example.com.'),
                        ColoredText.new('light-blue',
                                        'first@example.com is covered in a shimmering shield.'),
                        ColoredText.new('dark-blue',
                                        'second@example.com\'s dagger glances off of first@example.com\'s shield.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)

      initial_battle_states_3 = expected_battle_states_2.dup
      initial_battle_states_3[0].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')
      initial_battle_states_3[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '>')

      expected_battle_states_3 = [PlayerState.new(left_hand: 'WWP--', right_hand: '-----', health: 15, player_name: 'first@example.com', remaining_protection_turns: 0),
                                  PlayerState.new(left_hand: '-----', right_hand: '-->>>', health: 15,
                                                  player_name: 'second@example.com')]

      expected_log_3 = [ColoredText.new('green',
                                        'second@example.com stabs at first@example.com.'),
                        ColoredText.new('light-blue',
                                        'first@example.com is covered in a shimmering shield.'),
                        ColoredText.new('dark-blue',
                                        'second@example.com\'s dagger glances off of first@example.com\'s shield.')]

      result_3 = SpellbinderRules.calc_next_turn(initial_battle_states_3)

      SpellbinderRules.copy_init_views(initial_battle_states_3)
      SpellbinderRules.copy_init_views(expected_battle_states_3)

      expect(result_3[:log]).to eq(expected_log_3)
      expect(result_3[:next_states]).to eq(expected_battle_states_3)

      initial_battle_states_4 = expected_battle_states_3.dup
      initial_battle_states_4[0].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')
      initial_battle_states_4[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '>')

      expected_battle_states_4 = [PlayerState.new(left_hand: 'WWP---', right_hand: '------', health: 14, player_name: 'first@example.com', remaining_protection_turns: 0),
                                  PlayerState.new(left_hand: '------', right_hand: '-->>>>', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_4)
      SpellbinderRules.copy_init_views(expected_battle_states_4)

      expected_log_4 = [ColoredText.new('green',
                                        'second@example.com stabs at first@example.com.'),
                        ColoredText.new('red',
                                        'second@example.com stabs first@example.com for 1 damage.')]

      result_4 = SpellbinderRules.calc_next_turn(initial_battle_states_4)

      expect(result_4[:log]).to eq(expected_log_4)
      expect(result_4[:next_states]).to eq(expected_battle_states_4)
    end
  end

  describe 'Casting "Disease"' do
    it 'kills the target warlock at the end of the 6th turn following the one in which it was cast' do
      initial_battle_states = [PlayerState.new(left_hand: 'DSFFF',
                                               right_hand: '-----', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'C', right_gesture: 'C')),
                               PlayerState.new(left_hand: '-----',
                                               right_hand: '-----', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'DSFFFC', right_hand: '-----C', health: 15, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: '------', right_hand: '------', health: 15,
                                                player_name: 'second@example.com', remaining_disease_turns: 6)]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Disease on second@example.com.'),
                      ColoredText.new('red',
                                      'second@example.com starts to look sick.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      repetitive_orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders = repetitive_orders
      initial_battle_states_2[1].orders = repetitive_orders

      expected_battle_states_2 = [PlayerState.new(left_hand: 'DSFFFC-', right_hand: '-----C-', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '-------', right_hand: '-------', health: 15,
                                                  player_name: 'second@example.com', remaining_disease_turns: 5)]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [ColoredText.new('red',
                                        'second@example.com is a bit nauseous.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states]).to eq(expected_battle_states_2)

      changing_state = expected_battle_states_2.dup
      resulting_log = []
      3.upto(7) do |n|
        changing_state[0].orders = repetitive_orders
        changing_state[1].orders = repetitive_orders

        result_n = SpellbinderRules.calc_next_turn(changing_state)

        changing_state = result_n[:next_states]
        resulting_log = result_n[:log]

        expect(result_n[:next_states][1].remaining_disease_turns).to eq(7 - n)
      end

      expected_battle_states_final = [PlayerState.new(left_hand: 'DSFFFC------', right_hand: '-----C------', health: 15, player_name: 'first@example.com'),
                                      PlayerState.new(left_hand: '------------', right_hand: '------------',
                                                      health: -1, player_name: 'second@example.com', remaining_disease_turns: 0)]
      SpellbinderRules.copy_init_views(expected_battle_states_final)

      expected_log_final = [ColoredText.new('red', 'second@example.com is on the verge of death.'),
                            ColoredText.new('red', 'second@example.com keels over and dies of illness.')]

      expect(resulting_log).to eq(expected_log_final)
      expect(changing_state).to eq(expected_battle_states_final)
    end
  end

  describe 'Casting "Blindness"' do
    it 'prevents the target warlock from seeing the other warlock\'s gestures or targeting them for the next 3 turns' do
      initial_battle_states = [PlayerState.new(left_hand: 'DWFF',
                                               right_hand: '----', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'D', right_gesture: 'D')),
                               PlayerState.new(left_hand: '----',
                                               right_hand: '----', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'DWFFD', right_hand: '----D', health: 15, player_name: 'first@example.com'),
                                PlayerState.new(left_hand: '-----', right_hand: '-----', health: 15,
                                                player_name: 'second@example.com', remaining_blindness_turns: 3)]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Blindness on second@example.com.'),
                      ColoredText.new('yellow',
                                      'second@example.com\'s sight begins to dim.')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states][0]).to eq(expected_battle_states[0])
      expect(result[:next_states][1]).to eq(expected_battle_states[1])
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')
      initial_battle_states_2[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '>')

      SpellbinderRules.copy_init_views(initial_battle_states_2)

      expected_battle_states_2 = [PlayerState.new(left_hand: 'DWFFD-', right_hand: '----D-', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '------', right_hand: '----->', health: 15,
                                                  player_name: 'second@example.com', remaining_blindness_turns: 2)]
      expected_battle_states_2[0].other_view_left_hand = expected_battle_states[1].left_hand
      expected_battle_states_2[0].other_view_right_hand = expected_battle_states[1].right_hand
      expected_battle_states_2[1].other_view_left_hand = 'DWFFD?'
      expected_battle_states_2[1].other_view_right_hand = '----D?'

      expected_log_2 = [ColoredText.new('green',
                                        'second@example.com stabs at first@example.com, but misses due to blindness.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states][0]).to eq(expected_battle_states_2[0])
      expect(result_2[:next_states][1]).to eq(expected_battle_states_2[1])
      expect(result_2[:next_states]).to eq(expected_battle_states_2)

      changing_state = expected_battle_states_2.dup
      resulting_log = ''
      3.upto(4) do |n|
        changing_state[0].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')
        changing_state[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')

        result_n = SpellbinderRules.calc_next_turn(changing_state)

        resulting_log = result_n[:log]

        expect(result_n[:next_states][1].left_hand).to eq(changing_state[1].left_hand + '-')
        expect(result_n[:next_states][1].remaining_blindness_turns).to eq(4 - n)

        changing_state = result_n[:next_states]
      end

      expected_battle_states_final = [PlayerState.new(left_hand: 'DWFFD---', right_hand: '----D---', health: 15, player_name: 'first@example.com'),
                                      PlayerState.new(left_hand: '--------', right_hand: '----->--', health: 15,
                                                      player_name: 'second@example.com')]
      expected_battle_states_final[0].other_view_left_hand = expected_battle_states_final[1].left_hand
      expected_battle_states_final[0].other_view_right_hand = expected_battle_states_final[1].right_hand
      expected_battle_states_final[1].other_view_left_hand = 'DWFFD???'
      expected_battle_states_final[1].other_view_right_hand = '----D???'

      expected_log_final = [ColoredText.new('dark-blue', "second@example.com's eyes begin working again.")]

      expect(resulting_log).to eq(expected_log_final)
      expect(changing_state[0]).to eq(expected_battle_states_final[0])
      expect(changing_state[1]).to eq(expected_battle_states_final[1])
    end
  end

  describe 'Casting "Invisibility"' do
    it 'prevents the other warlock from seeing or targeting the caster' do
      initial_battle_states = [PlayerState.new(left_hand: 'PPW',
                                               right_hand: '--W', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'S', right_gesture: 'S')),
                               PlayerState.new(left_hand: '---',
                                               right_hand: '---', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'PPWS', right_hand: '--WS', health: 15,
                                                player_name: 'first@example.com', remaining_invis_turns: 3),
                                PlayerState.new(left_hand: '----', right_hand: '----', health: 15,
                                                player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Invisibility on themself.'),
                      ColoredText.new('white',
                                      'There is a flash, and first@example.com disappears!')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')
      initial_battle_states_2[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '>')

      SpellbinderRules.copy_init_views(initial_battle_states_2)

      expected_battle_states_2 = [PlayerState.new(left_hand: 'PPWS-', right_hand: '--WS-', health: 15,
                                                  player_name: 'first@example.com', remaining_invis_turns: 2),
                                  PlayerState.new(left_hand: '-----', right_hand: '---->', health: 15,
                                                  player_name: 'second@example.com')]
      expected_battle_states_2[0].other_view_left_hand = expected_battle_states[1].left_hand
      expected_battle_states_2[0].other_view_right_hand = expected_battle_states[1].right_hand
      expected_battle_states_2[1].other_view_left_hand = 'PPWS?'
      expected_battle_states_2[1].other_view_right_hand = '--WS?'

      expected_log_2 = [ColoredText.new('green',
                                        'second@example.com stabs at first@example.com, but misses due to invisibility.')]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states][0]).to eq(expected_battle_states_2[0])
      expect(result_2[:next_states][1]).to eq(expected_battle_states_2[1])
      expect(result_2[:next_states]).to eq(expected_battle_states_2)

      changing_state = expected_battle_states_2.dup
      resulting_log = []
      3.upto(4) do |n|
        changing_state[0].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')
        changing_state[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: '-')

        result_n = SpellbinderRules.calc_next_turn(changing_state)

        resulting_log = result_n[:log]

        expect(result_n[:next_states][1].left_hand).to eq(changing_state[1].left_hand + '-')

        expect(result_n[:next_states][0].remaining_invis_turns).to eq(4 - n)

        changing_state = result_n[:next_states]
      end

      expected_battle_states_final = [PlayerState.new(left_hand: 'PPWS---', right_hand: '--WS---', health: 15, player_name: 'first@example.com'),
                                      PlayerState.new(left_hand: '-------', right_hand: '---->--', health: 15,
                                                      player_name: 'second@example.com')]
      expected_battle_states_final[0].other_view_left_hand = expected_battle_states_final[1].left_hand
      expected_battle_states_final[0].other_view_right_hand = expected_battle_states_final[1].right_hand
      expected_battle_states_final[1].other_view_left_hand = 'PPWS???'
      expected_battle_states_final[1].other_view_right_hand = '--WS???'

      expected_log_final = [ColoredText.new('white', 'first@example.com fades back into visibility.')]

      expect(resulting_log).to eq(expected_log_final)
      expect(changing_state[0]).to eq(expected_battle_states_final[0])
      expect(changing_state[1]).to eq(expected_battle_states_final[1])
    end
  end

  describe 'Casting "Haste"' do
    it 'in effect slows down the other warlock\'s turns' do
      initial_battle_states = [PlayerState.new(left_hand: 'PWPWW',
                                               right_hand: '-----', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'C', right_gesture: 'C')),
                               PlayerState.new(left_hand: '-----',
                                               right_hand: '----W', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: '-', right_gesture: 'F'))]

      expected_battle_states = [PlayerState.new(left_hand: 'PWPWWC', right_hand: '-----C', health: 15,
                                                player_name: 'first@example.com', remaining_haste_turns: 3),
                                PlayerState.new(left_hand: '------', right_hand: '----WF', health: 15,
                                                player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Haste on themself.'),
                      ColoredText.new('light-blue',
                                      'first@example.com speeds up!')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders = PlayerOrders.new(left_gesture: 'P', right_gesture: 'W')
      initial_battle_states_2[0].haste_orders = PlayerOrders.new(left_gesture: 'S', right_gesture: 'P')
      initial_battle_states_2[1].orders = PlayerOrders.new(left_gesture: '-', right_gesture: 'P')

      expected_battle_states_2 = [PlayerState.new(left_hand: 'PWPWWCPS', right_hand: '-----CWP', health: 13, player_name: 'first@example.com', remaining_haste_turns: 2),
                                  PlayerState.new(left_hand: '------- ', right_hand: '----WFP ', health: 15,
                                                  player_name: 'second@example.com')]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      SpellbinderRules.copy_init_views(expected_battle_states_2)

      expected_log_2 = [
        ColoredText.new('green', 'first@example.com casts Shield on themself.'),
        ColoredText.new('yellow', 'first@example.com is hastened, so he sneaks in an extra set of gestures.'),
        ColoredText.new('green', 'first@example.com casts Shield on themself.'), # Second Shield is cast intentionally
        ColoredText.new('green',
                        'second@example.com casts Cause Light Wounds on first@example.com.'),
        ColoredText.new('light-blue', 'first@example.com is covered in a shimmering shield.'),
        ColoredText.new('red', 'Light wounds appear on first@example.com\'s body for 2 damage.')
      ]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:next_states][0]).to eq(expected_battle_states_2[0])
      expect(result_2[:next_states][1]).to eq(expected_battle_states_2[1])
      expect(result_2[:next_states]).to eq(expected_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
    end
  end

  describe 'Casting "Time Stop"' do
    it ' gives the caster an immediate extra turn, in which protections and enchantments temporarily don\'t work.' do
      initial_battle_states = [PlayerState.new(left_hand: 'SPPF',
                                               right_hand: '----', player_name: 'first@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'D', right_gesture: '-')),
                               PlayerState.new(left_hand: '--WW',
                                               right_hand: '----', player_name: 'second@example.com',
                                               orders: PlayerOrders.new(left_gesture: 'P', right_gesture: '-'))]

      expected_battle_states = [PlayerState.new(left_hand: 'SPPFD', right_hand: '-----', health: 15,
                                                player_name: 'first@example.com', remaining_time_stop_turns: 1),
                                PlayerState.new(left_hand: '--WWP', right_hand: '-----', health: 15,
                                                player_name: 'second@example.com', remaining_protection_turns: 2)]

      SpellbinderRules.copy_init_views(initial_battle_states)
      SpellbinderRules.copy_init_views(expected_battle_states)

      expected_log = [ColoredText.new('green',
                                      'first@example.com casts Time Stop on themself.'),
                      ColoredText.new('green', 'second@example.com casts Protection on themself.'),
                      ColoredText.new('light-blue', 'second@example.com is covered in a thick shimmering shield.'),
                      ColoredText.new('light-blue',
                                      'first@example.com flickers out of time!')]

      result = SpellbinderRules.calc_next_turn(initial_battle_states)

      expect(result[:log]).to eq(expected_log)
      expect(result[:next_states][0]).to eq(expected_battle_states[0])
      expect(result[:next_states][1]).to eq(expected_battle_states[1])
      expect(result[:next_states]).to eq(expected_battle_states)

      initial_battle_states_2 = expected_battle_states.dup
      initial_battle_states_2[0].orders = PlayerOrders.new(left_gesture: '>', right_gesture: '-')
      initial_battle_states_2[1].orders = nil

      expected_battle_states_2 = [PlayerState.new(left_hand: 'SPPFD>', right_hand: '------', health: 15, player_name: 'first@example.com'),
                                  PlayerState.new(left_hand: '--WWP ', right_hand: '----- ', health: 14,
                                                  player_name: 'second@example.com', remaining_protection_turns: 2)]

      SpellbinderRules.copy_init_views(initial_battle_states_2)
      expected_battle_states_2[0].other_view_left_hand = expected_battle_states_2[1].left_hand
      expected_battle_states_2[0].other_view_right_hand = expected_battle_states_2[1].right_hand
      expected_battle_states_2[1].other_view_left_hand = 'SPPFD?'
      expected_battle_states_2[1].other_view_right_hand = '-----?'

      expected_log_2 = [
        ColoredText.new('green', 'first@example.com stabs at second@example.com.'),
        ColoredText.new('red', 'first@example.com stabs second@example.com for 1 damage.')
      ]

      result_2 = SpellbinderRules.calc_next_turn(initial_battle_states_2)

      expect(result_2[:log]).to eq(expected_log_2)
      expect(result_2[:next_states][0]).to eq(expected_battle_states_2[0])
      expect(result_2[:next_states][1]).to eq(expected_battle_states_2[1])
      expect(result_2[:next_states]).to eq(expected_battle_states_2)
    end
  end

  describe '.random_gesture' do
    it 'can be mocked (stubbed?) correctly' do
      allow(SpellbinderRules).to receive(:random_gesture) { 'P' }

      expect(SpellbinderRules.random_gesture).to eql('P')
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
