# frozen_string_literal: true

FactoryBot.define do
  factory :transackshun, class: 'Transackshun' do
    description { 'Jaffa Cake Emporium' }

    factory :valid_transackshun do
      after(:build) do |transackshun, _context|
        transackshun.journal_entries = [build(:credit), build(:debit)]
      end
    end
  end
end
