# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :title, null: false
      t.string :type, null: false
      t.string :currency, null: false

      t.timestamps
    end
  end
end
