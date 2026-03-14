FactoryBot.define do
  factory :recommendation do
    association :user
    month { Date.today.beginning_of_month }
    content { "Consider reducing spending on dining out." }
    generated_at { Time.current }
    raw_response_json { {} }
  end
end
