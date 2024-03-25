# frozen_string_literal: true

# TODO: changing transaction order is a destroy and create, put in a command

##
# Represents one side of a double-entry transaction, which are doubly-associated to one another
#
# DB schema and model validations ensure the double-entry transactions are accurate and fault-tolerant
class JournalEntry < ApplicationRecord
  default_scope { order(order: :asc) }

  before_create :assign_associated_entries
  before_create :assign_order_number
  before_destroy :unassign_associated_entries

  belongs_to :account
  belongs_to :transackshun
  belongs_to :next_entry, class_name: 'JournalEntry', optional: true, autosave: true, validate: false
  has_one :previous_entry, class_name: 'JournalEntry', autosave: true, validate: false, foreign_key: :next_entry_id,
                           inverse_of: :next_entry, dependent: :restrict_with_error

  enum transaction_type: {
    credit: 1,
    debit: -1
  }

  validates :posted_date, presence: true
  validates :amount_in_cents, numericality: { greater_than: 0 }
  validate :validate_posted_date

  # TODO: set balance on create/update

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

    amount
  end

  ##
  # Assigns an order value identifying the sequence of account transactions for the posted_date
  def assign_order_number(next_previous_entry = nil)
    # ActiveRecord does not associate inversed relationships before save because it requires the foreign key
    #   So we manually pass the previous_entry
    next_previous_entry ||= previous_entry

    self.order =
      if next_previous_entry&.posted_date == posted_date
        next_previous_entry.order + 1
      else
        1
      end

    next_entry&.assign_order_number(self) # This is an n+1 problem
  end

  private

  def validate_posted_date
    if next_entry && posted_date > next_entry.posted_date
      errors.add(:posted_date, 'must be after proceding account entry')
    end

    if previous_entry && posted_date < previous_entry.posted_date
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

  def unassign_associated_entries
    previous_entry&.update(next_entry:)
    reload
    # TODO: test this
    assign_order_number
    true
  end
end
