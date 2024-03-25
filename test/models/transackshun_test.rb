# frozen_string_literal: true

require 'test_helper'

class TransackshunTest < ActiveSupport::TestCase
  # Move to transaction tests - sum all amounts (in like currency) should equal 0
  test '#validate fails when matching entry has differing amount' do
    transackshun = build(:valid_transackshun)
    transackshun.journal_entries.first.amount_in_cents += 1

    transackshun.validate

    assert_equal 1, transackshun.errors.count
    assert_equal 'Journal entries are not balanced', transackshun.errors.full_messages.first
  end

  # Should an account be allowed a journal entry of each transaction type?
  test '#validate fails when account has multiple journal entries' do
    account = build(:asset_account)
    transackshun = build(
      :transackshun,
      journal_entries: [
        build(:credit, account:, amount_in_cents: 50),
        build(:credit, account:, amount_in_cents: 50),
        build(:debit, amount_in_cents: 100)
      ]
    )

    transackshun.validate

    assert_equal 1, transackshun.errors.count
    assert_equal 'Journal entries must have unique accounts', transackshun.errors.full_messages.first
  end

  test '#destroy disassociates journal_entry from previous_entry' do
    account = build(:asset_account)
    previous_entry = create(:credit, account:, transackshun: create(:transackshun))
    transackshun = create(:transackshun)
    create(:credit, account:, transackshun:)
    next_entry = create(:credit, account:, transackshun: create(:transackshun))

    transackshun.reload

    assert_difference 'JournalEntry.count', -1 do
      transackshun.destroy!
    end

    previous_entry.reload

    assert_equal previous_entry.next_entry.id, next_entry.id
  end
end
