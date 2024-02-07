# frozen_string_literal: true

##
# Represents one side of a double-entry transaction, which are doubly-associated to one another
#
# DB schema and model validations ensure the double-entry transactions are accurate and fault-tolerant
class JournalEntry < ApplicationRecord
  default_scope { order(order: :asc) }

  belongs_to :account
  belongs_to :matching_entry, class_name: 'JournalEntry', autosave: true, validate: false
  belongs_to :next_entry, class_name: 'JournalEntry', optional: true, autosave: true, dependent: :destroy
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
    # TODO: test that assignment occurs if not specified
    # TODO: test that next_entry
    self.next_entry ||= account
                        .journal_entries
                        .where('posted_date > ?', posted_date)
                        .first

    self.previous_entry = next_entry&.previous_entry || account
                          .journal_entries
                          .where('posted_date <= ?', posted_date)
                          .last
  end

  # TODO: This should be done only if next_entry is changed?
  #   - maybe we move this to a command
  def assign_order_number
    # TODO: set order number
    #   previous_entry.order + 1
    # TODO: set next_entry order number
    #   order + 1
    #   This will create an n+1 and violate the unique index
    #     - we can fetch account entries ordered by order: :desc and process in batches until next_entry is hit

    # TODO: can we raise an error if we're not in a transaction?
    #  - could stuff the transaction in a CurrentAttributes record...
  end
end
