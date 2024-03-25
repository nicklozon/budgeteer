# frozen_string_literal: true

require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase
  test '#amount does not perform any conversion when exchange rate is not set' do
    credit_entry = build(:credit)

    assert_nil credit_entry.exchange_rate
    assert_in_delta(123.45, credit_entry.amount)
  end

  test '#amount performs conversion when exchange rate is set' do
    credit_entry = build(:credit, exchange_rate: 0.81004)

    assert_in_delta(100.00, credit_entry.amount)
  end

  test '#amount= does not perform any conversion when exchange rate is not set' do
    credit_entry = build(:credit)

    credit_entry.amount = 543.21

    assert_nil credit_entry.exchange_rate
    assert_in_delta(543.21, credit_entry.amount)
  end

  test '#amount= performs conversion when exchange rate is set' do
    credit_entry = build(:credit, exchange_rate: 0.81004)

    credit_entry.amount = 100

    assert_in_delta(12_345, credit_entry.amount_in_cents)
  end

  test '#save assigns next_entry for first transaction of after posted_date' do
    account = create(:asset_account)
    new_entry = build(:credit, account:, transackshun: create(:transackshun))
    existing_entry = create(:credit, account:, posted_date: Time.zone.today + 2.days,
                                     transackshun: create(:transackshun))

    new_entry.save!

    assert_equal new_entry.next_entry.id, existing_entry.id
  end

  test '#save does not assign next_entry anything if no older transactions exist' do
    account = create(:asset_account)
    new_entry = build(:credit, account:, transackshun: create(:transackshun))
    create(:credit, account:, transackshun: create(:transackshun))

    new_entry.save!

    assert_nil new_entry.next_entry
  end

  test '#save assigns previous_entry to that of next entry\'s' do
    account = create(:asset_account)
    new_entry = build(:credit, account:, transackshun: create(:transackshun))
    next_entry = create(:credit, account:, posted_date: Time.zone.today + 2.days, transackshun: create(:transackshun))
    previous_entry = create(:credit, account:, next_entry:, transackshun: create(:transackshun))

    new_entry.save!

    assert_equal new_entry.next_entry.id, next_entry.id
    assert_equal new_entry.previous_entry.id, previous_entry.id
  end

  test '#save assigns previous_entry for last transaction of previous day' do
    account = create(:asset_account)
    new_entry = build(:credit, account:, transackshun: create(:transackshun))
    next_entry = create(:credit, account:, posted_date: Time.zone.today + 2.days, transackshun: create(:transackshun))
    previous_entry = create(:credit, account:, transackshun: create(:transackshun))

    new_entry.save!

    assert_equal new_entry.next_entry.id, next_entry.id
    assert_equal new_entry.previous_entry.id, previous_entry.id
  end

  test '#save does not assign new next_entry if it exists' do
    account = create(:asset_account)
    next_entry = create(:credit, account:, transackshun: create(:transackshun))
    new_entry = build(:credit, account:, next_entry:, transackshun: create(:transackshun))
    create(:credit, account:, posted_date: Time.zone.today, transackshun: create(:transackshun))

    new_entry.save!

    assert_equal new_entry.next_entry.id, next_entry.id
  end

  test '#validate fails when next_entry date is before posted_date' do
    next_entry = build(:credit, posted_date: Time.zone.today - 1.day, transackshun: create(:transackshun))
    entry = build(:credit, next_entry:, transackshun: create(:transackshun))

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Posted date must be after proceding account entry', entry.errors.full_messages.first
  end

  test '#validate fails when previous_entry date is after posted_date' do
    previous_entry = build(:credit, posted_date: Time.zone.today + 1.day, transackshun: create(:transackshun))
    entry = build(:credit, previous_entry:, transackshun: create(:transackshun))

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Posted date must be before preceding account entry', entry.errors.full_messages.first
  end

  test '#save assigns order to 1 when no previous_entry' do
    entry = create(:credit, transackshun: create(:transackshun))

    assert_equal 1, entry.order
  end

  test '#save assigns order to 1 when previous_entry on another day' do
    entry = create(:credit, transackshun: create(:transackshun))
    create(:credit, next_entry: entry, posted_date: Time.zone.today - 1.day, transackshun: create(:transackshun))

    assert_equal 1, entry.order
  end

  test '#save assigns order previous_entry order plus 1' do
    entry = create(:credit, transackshun: create(:transackshun))

    assert_equal 1, entry.order

    create(:credit, next_entry: entry, transackshun: create(:transackshun))

    assert_equal 2, entry.order
  end

  test '#save increments next_entry order when on same day' do
    next_entry = create(:credit, transackshun: create(:transackshun))

    assert_equal 1, next_entry.order

    create(:credit, next_entry:, transackshun: create(:transackshun))

    assert_equal 2, next_entry.order
  end

  test '#save does not increment next_entry order when another day' do
    next_entry = create(:credit, transackshun: create(:transackshun))

    assert_equal 1, next_entry.order

    create(:credit, next_entry:, posted_date: Time.zone.today - 1.day, transackshun: create(:transackshun))

    assert_equal 1, next_entry.order
  end

  # Test order: 1,2,3 -> 1,2 (2 is deleted)
end
