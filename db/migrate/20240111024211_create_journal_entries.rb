# frozen_string_literal: true

class CreateJournalEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :journal_entries do |t|
      t.string :description, null: false
      t.integer :transaction_type, null: false
      t.integer :amount_in_cents, null: false
      t.decimal :exchange_rate, precision: 18, scale: 8
      t.integer :balance, null: false
      t.date :posted_date, null: false
      t.date :cleared_date, null: false
      t.integer :order

      t.references :account, null: false, foreign_key: true
      t.references :matching_entry, foreign_key: { to_table: :journal_entries }, index: { unique: true }
      t.references :next_entry, foreign_key: { to_table: :journal_entries }

      t.index [:account_id, :posted_date, :order], unique: true

      t.timestamps
    end
  end
end
