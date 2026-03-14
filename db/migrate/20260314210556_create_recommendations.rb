class CreateRecommendations < ActiveRecord::Migration[8.1]
  def change
    create_table :recommendations do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month, null: false
      t.text :content, null: false
      t.jsonb :raw_response_json
      t.datetime :generated_at, null: false

      t.timestamps
    end
  end
end
