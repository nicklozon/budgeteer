# frozen_string_literal: true

FactoryBot.define do
  sequence :journal_entry_id

  factory :journal_entry, class: 'JournalEntry' do
    amount_in_cents { 12_345 }
    balance { 123.45 } # TODO: should be in cents
    description { 'Jaffa Cakes Co.' }
    posted_date { DateTime.now }
    cleared_date { DateTime.now }

    trait :id do
      id { generate(:journal_entry_id) }
    end

    trait :credit do
      transaction_type { 1 }
      account { association :asset_account }
    end

    trait :debit do
      transaction_type { -1 }
      account { association :liability_account }
    end

    trait :valid do
      after(:build) do |journal_entry, _context|
        unless journal_entry.matching_entry
          journal_entry.matching_entry = build(
            :valid_debit,
            transaction_type: JournalEntry.transaction_types[journal_entry.transaction_type] * -1,
            matching_entry: journal_entry
          )
        end
      end
    end

    factory :credit, traits: [:credit]
    factory :debit, traits: [:debit]
    factory :valid_credit, traits: [:valid, :credit]
    factory :valid_debit, traits: [:valid, :debit]
  end
end
