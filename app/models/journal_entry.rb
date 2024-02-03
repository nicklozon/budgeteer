# frozen_string_literal: true

class JournalEntry < ApplicationRecord
  belongs_to :account
  belongs_to :matching_entry, class_name: 'JournalEntry'
  has_one :next_entry, class_name: 'JournalEntry', dependent: :destroy
  has_one :previous_entry, class_name: 'JournalEntry', foreign_key: :next_entry_id,
                           inverse_of: :next_entry, dependent: :destroy

  enum transaction_type: {
    credit: 1,
    debit: -1
  }

  validates :amount_in_cents, numericality: { greater_than: 0 }
  validate :validate_entry_integrity

  before_create :assign_next_entry

  def amount
    Money.from_cents(
      amount_in_cents * JournalEntry.transaction_types[transaction_type],
      account.currency
    ).to_f
  end

  def amount=(value)
    self.amount_in_cents = Money.from_amount(
      value,
      account.currency
    ).cents
  end

  def matching_entry=(entry)
    if entry.matching_entry && entry.matching_entry != self
      raise StandardError, "Invalid Matching Journal Entry: #{entry.id} already has a matching entry"
    end

    super(entry)
    entry.matching_entry = self unless entry.matching_entry
  end

  private

  def validate_entry_integrity
    return unless matching_entry

    if amount_in_cents != matching_entry.amount_in_cents
      # TODO: wait, what if accounts are different currencies?
      #   Should all amounts be in the native currency and then an exchange rate applied at the entry level?
      errors.add(:amount, 'must equal matching entry')
    end

    if transaction_type == matching_entry.transaction_type
      errors.add(:transaction_type, 'must differ from matching entry')
    end

    if account == matching_entry.account
      errors.add(:account, 'must differ from matching entry')
    end
  end

  def assign_next_entry
    # next_entry = JournalEntry
    #  .where(account: account)
    #  .and
    # find next tx
    #  - acct
    #  - posted_date > date OR
    #  - (posted_date == date AND order > order)
    #  - order by posted_date - order # needs index?
    #  - limit 1
    # .first

    # TODO: Start a DB transaction?

    self.previous_entry = next_entry.previous_entry
    self.next_entry = next_entry
  end
end
