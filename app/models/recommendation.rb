class Recommendation < ApplicationRecord
  belongs_to :user

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :content, presence: true
  validates :generated_at, presence: true
end
