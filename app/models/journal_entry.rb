# frozen_string_literal: true

# TODO: changing transaction order is a destroy and create, put in a command

##
# Represents one side of a double-entry transaction, which are doubly-associated to one another
#
# DB schema and model validations ensure the double-entry transactions are accurate and fault-tolerant
class JournalEntry < ApplicationRecord
  default_scope { order(order: :asc) }

  belongs_to :account
  belongs_to :matching_entry, class_name: 'JournalEntry', autosave: true, validate: false
  belongs_to :next_entry, class_name: 'JournalEntry', optional: true, autosave: true
  has_one :previous_entry, class_name: 'JournalEntry', foreign_key: :next_entry_id,
                           inverse_of: :next_entry, dependent: :destroy

  enum transaction_type: {
    credit: 1,
    debit: -1
  }

  validates :posted_date, presence: true
  validates :amount_in_cents, numericality: { greater_than: 0 }
  validate :validate_entry_integrity
  validate :validate_posted_date

  before_create :assign_associated_entries
  # TODO: prevent mutation to next_entry
  # TODO: before destroy to associate previous/next entries

  ##
  # Retrieves amount in currency of the account
  def amount
    exchange_rate = self.exchange_rate || 1

    Money.from_cents(
      amount_in_cents * JournalEntry.transaction_types[transaction_type] * exchange_rate,
      account.currency
    ).to_f
  end

  ##
  # Assigns amount in currency of the account
  def amount=(value)
    exchange_rate = self.exchange_rate || 1

    self.amount_in_cents = Money.from_amount(
      value,
      account.currency
    ).cents / exchange_rate
  end

  ##
  # Associates two journal entries together
  def matching_entry=(entry)
    if entry.matching_entry && entry.matching_entry != self
      raise StandardError, "Invalid Matching Journal Entry: #{entry.id} already has a matching entry"
    end

    super(entry)
    entry.matching_entry = self unless entry.matching_entry
  end

  def assign_order_number
    # [1,2] -> [1,x,2] -> [1,2,3]
    # [1,2][1] -> [1,2][x,1] -> [1,2][1,2]
    # if previous_entry.posted_date == posted_date
    #  - previous_entry.order + 1
    # else
    #  - 1
    # if next_entry.posted_date == posted_date
    #  - next_entry.assign_order_number # n+1
  end

  private

  def validate_entry_integrity
    return unless matching_entry

    if amount_in_cents != matching_entry.amount_in_cents
      errors.add(:amount, 'must equal matching entry')
    end

    if transaction_type == matching_entry.transaction_type
      errors.add(:transaction_type, 'must differ from matching entry')
    end

    if account == matching_entry.account
      errors.add(:account, 'must differ from matching entry')
    end
  end

  # TODO: needs testing
  def validate_posted_date
    return unless next_entry

    if posted_date > next_entry.posted_date
      errors.add(:posted_date, 'must be after proceding account entry')
    end

    return unless next_entry.previous_entry

    if posted_date < next_entry.previous_entry&.posted_date
      errors.add(:posted_date, 'must be before preceding account entry')
    end
  end

  def assign_associated_entries
    return if next_entry

    next_next_entry = account.journal_entries.where('posted_date > ?', posted_date).first

    self.previous_entry = next_next_entry&.previous_entry ||
                          account.journal_entries.where('posted_date <= ?', posted_date).last

    self.next_entry = next_next_entry
  end
end
