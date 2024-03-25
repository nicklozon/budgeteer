# frozen_string_literal: true

FactoryBot.define do
  sequence :journal_entry_id

  factory :journal_entry, class: 'JournalEntry' do
    amount_in_cents { 12_345 }
    balance { 123.45 } # TODO: should be in cents
    posted_date { Time.zone.today }
    cleared_date { Time.zone.today }

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

    factory :credit, traits: [:credit]
    factory :debit, traits: [:debit]
  end
end
