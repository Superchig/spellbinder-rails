class Battle < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :battle_states

  before_destroy do |battle|
    battle.battle_states.each do |battle_state|
      battle_state.destroy
    end
  end

  # This is kind of ugly, but it works for now.
  SPELL_NAMES = ['', 'Amnesia', 'Anti-spell', 'Blindness', 'Blindness', 'Cause Heavy Wounds', 'Cause Light Wounds',
                 'Charm Monster', 'Charm Person', 'Clap of Lightning', 'Confusion/Maladroitness', 'Counter Spell',
                 'Cure Heavy Wounds', 'Cure Light Wounds', 'Delay Effect', 'Disease', 'Dispel Magic', 'Fear (No CFDS)',
                 'Finger of Death', 'Fire Storm', 'Fireball', 'Haste', 'Ice Storm', 'Invisibility', 'Lightning Bolt',
                 'Magic Mirror', 'Magic Missile', 'Paralysis', 'Permanency', 'Poison', 'Protection', 'Remove Enchantment',
                 'Resist Cold', 'Resist Heat', 'Shield', 'Summon Fire Elemental', 'Summon Giant', 'Summon Goblin',
                 'Summon Ice Elemental', 'Summon Ogre', 'Summon Troll', 'Surrender', 'Time Stop'].freeze
end
