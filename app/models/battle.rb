class Battle < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :battle_states
end
