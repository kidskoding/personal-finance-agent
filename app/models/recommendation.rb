class Recommendation < ApplicationRecord
  belongs_to :user

  validates :month, presence: true
  validates :content, presence: true
  validates :generated_at, presence: true
end
