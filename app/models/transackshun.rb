# frozen_string_literal: true

class Transackshun < ApplicationRecord
  has_many :journal_entries, autosave: true, dependent: :destroy, validate: true

  validate :validate_entry_integrity

  private

  def validate_entry_integrity
    sum = journal_entries.sum(&:amount).round(2)
    if sum != 0
      errors.add(:journal_entries, 'are not balanced')
    end

    account_ids = journal_entries.map { |je| je.account.id }
    if account_ids.length != account_ids.uniq.length
      errors.add(:journal_entries, 'must have unique accounts')
    end
  end
end
