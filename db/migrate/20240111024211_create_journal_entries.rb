# frozen_string_literal: true

class CreateJournalEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :transackshuns do |t|
      t.string :description, null: false

      t.timestamps
    end

    create_table :journal_entries do |t|
      t.integer :transaction_type, null: false
      t.integer :amount_in_cents, null: false
      t.decimal :exchange_rate, precision: 18, scale: 8
      t.integer :balance, null: false
      t.date :posted_date, null: false
      t.date :cleared_date, null: false
      t.integer :order

      t.references :transackshun, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :next_entry, foreign_key: { to_table: :journal_entries }

      t.index [:account_id, :order]
      t.index [:account_id, :posted_date, :order]
      t.index [:posted_date]

      t.timestamps
    end
  end
end
