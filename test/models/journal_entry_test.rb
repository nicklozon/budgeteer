# frozen_string_literal: true

require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase
  test '#validate fails when no matching entry' do
    entry = build(:credit)

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Matching entry must exist', entry.errors.full_messages.first
  end

  test '#validate fails when matching entry has same type' do
    entry = build(:credit, matching_entry: build(:credit))

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Transaction type must differ from matching entry', entry.errors.full_messages.first
  end

  test '#validate fails when matching entry has differing amount' do
    entry = build(:valid_credit)
    entry.matching_entry.amount = entry.amount + 0.01

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Amount must equal matching entry', entry.errors.full_messages.first
  end

  test '#validate fails when matching entry has same account' do
    account = build(:asset_account)
    entry = build(:credit, account:, matching_entry: build(:debit, account:))

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Account must differ from matching entry', entry.errors.full_messages.first
  end

  test '#matching_entry= creates circular association' do
    credit_entry = build(:credit)
    debit_entry = build(:debit)

    credit_entry.matching_entry = debit_entry

    assert_equal credit_entry.matching_entry, debit_entry
    assert_equal credit_entry, debit_entry.matching_entry
  end

  test '#matching_entry= raises error when assign entry already has a entry' do
    credit_entry = build(:credit)
    debit_entry = build(:debit, matching_entry: build(:credit))

    assert_raises StandardError do
      credit_entry.matching_entry = debit_entry
    end
  end

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
    new_entry = build(:credit, account:, matching_entry: build(:debit))
    existing_entry = create(:credit, account:, posted_date: Time.zone.today + 2.days, matching_entry: build(:debit))

    new_entry.save!

    assert_equal new_entry.next_entry.id, existing_entry.id
  end

  test '#save does not assign next_entry anything if no older transactions exist' do
    account = create(:asset_account)
    new_entry = build(:credit, account:, matching_entry: build(:debit))
    create(:credit, account:, matching_entry: build(:debit))

    new_entry.save!

    assert_nil new_entry.next_entry
  end

  test '#save assigns previous_entry to that of next entry\'s' do
    account = create(:asset_account)
    new_entry = build(:credit, account:, matching_entry: build(:debit))
    next_entry = create(:credit, account:, posted_date: Time.zone.today + 2.days, matching_entry: build(:debit))
    previous_entry = create(:credit, account:, next_entry:, matching_entry: build(:debit))

    new_entry.save!

    assert_equal new_entry.next_entry.id, next_entry.id
    assert_equal new_entry.previous_entry.id, previous_entry.id
  end

  test '#save assigns previous_entry for last transaction of previous day' do
    account = create(:asset_account)
    new_entry = build(:credit, account:, matching_entry: build(:debit))
    next_entry = create(:credit, account:, posted_date: Time.zone.today + 2.days, matching_entry: build(:debit))
    previous_entry = create(:credit, account:, matching_entry: build(:debit))

    new_entry.save!

    assert_equal new_entry.next_entry.id, next_entry.id
    assert_equal new_entry.previous_entry.id, previous_entry.id
  end

  test '#save does not assign new next_entry if it exists' do
    account = create(:asset_account)
    next_entry = create(:credit, account:, matching_entry: build(:debit))
    new_entry = build(:credit, account:, next_entry:, matching_entry: build(:debit))
    create(:credit, account:, posted_date: Time.zone.today, matching_entry: build(:debit))

    new_entry.save!

    assert_equal new_entry.next_entry.id, next_entry.id
  end

  test '#validate fails when next_entry date is before posted_date' do
    next_entry = build(:credit, posted_date: Time.zone.today - 1.day, matching_entry: build(:debit))
    entry = build(:credit, next_entry:, matching_entry: build(:debit))

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Posted date must be after proceding account entry', entry.errors.full_messages.first
  end

  test '#validate fails when previous_entry date is after posted_date' do
    previous_entry = build(:credit, posted_date: Time.zone.today + 1.day, matching_entry: build(:debit))
    entry = build(:credit, previous_entry:, matching_entry: build(:debit))

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Posted date must be before preceding account entry', entry.errors.full_messages.first
  end

  test '#validate fails when next_entry is updated' do
    next_entry = create(:credit, matching_entry: build(:debit))
    next_next_entry = create(:credit, matching_entry: build(:debit))
    entry = create(:credit, next_entry:, matching_entry: build(:debit))
    entry.next_entry = next_next_entry

    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Next entry cannot be changed', entry.errors.full_messages.first
  end

  test '#save assigns order to 1 when no previous_entry' do
  end

  test '#save assigns order to 1 when previous_entry on another day' do
  end

  test '#save assigns order previous_entry order plus 1' do
  end

  test '#save increments next_entry order when on same day' do
  end

  test '#save does not increment next_entry order when another day' do
  end
end
