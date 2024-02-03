# frozen_string_literal: true

FactoryBot.define do
  sequence :account_id

  factory :account, class: 'Account' do
    id { generate(:account_id) }
    title { 'Chequing Account' }
    currency { 'USD' }

    trait :asset do
      type { 'asset' } # TODO: need to identify all account types
    end

    trait :liability do
      type { 'liability' } # TODO: need to identify all account types
    end

    factory :asset_account, traits: [:asset]
    factory :liability_account, traits: [:liability]
  end
end
