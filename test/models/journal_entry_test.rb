# frozen_string_literal: true

require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase
  test 'entry validation fails when no matching entry' do
    entry = build(:credit)
    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Matching entry must exist', entry.errors.full_messages.first
  end

  test 'entry validation fails when matching entry has same type' do
    entry = build(:credit, matching_entry: build(:credit))
    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Transaction type must differ from matching entry', entry.errors.full_messages.first
  end

  test 'entry validation fails when matching entry has differing amount' do
    entry = build(:valid_credit)
    entry.matching_entry.amount = entry.amount + 0.01
    entry.validate

    assert_equal 1, entry.errors.count
    assert_equal 'Amount must equal matching entry', entry.errors.full_messages.first
  end

  test 'entry validation fails when matching entry has same account' do
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
end
