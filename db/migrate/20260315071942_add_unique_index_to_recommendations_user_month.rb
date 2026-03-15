class AddUniqueIndexToRecommendationsUserMonth < ActiveRecord::Migration[8.1]
  def change
    add_index :recommendations, [:user_id, :month], unique: true
  end
end
