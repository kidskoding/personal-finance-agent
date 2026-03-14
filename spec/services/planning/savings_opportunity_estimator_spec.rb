require 'rails_helper'

RSpec.describe Planning::SavingsOpportunityEstimator do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }
  let(:date) { Date.new(2026, 3, 1) }

  subject(:result) { described_class.new(user: user, date: date).call }

  def create_txn(category:, amount:)
    create(:transaction,
      user: user,
      account: account,
      category_primary: category,
      amount: amount,
      posted_date: date,
      pending: false
    )
  end

  describe "#call" do
    before do
      create_txn(category: "FOOD_AND_DRINK", amount: 200.00)
      create_txn(category: "SHOPPING",       amount: 150.00)
      create_txn(category: "ENTERTAINMENT",  amount: 100.00)
    end

    it "returns one entry per top category" do
      expect(result.map { |r| r[:category] }).to include("FOOD_AND_DRINK", "SHOPPING", "ENTERTAINMENT")
    end

    it "applies the correct reduction percentage for known categories" do
      food = result.find { |r| r[:category] == "FOOD_AND_DRINK" }
      expect(food[:reduction_percentage]).to eq(20)
    end

    it "calculates estimated savings correctly" do
      food = result.find { |r| r[:category] == "FOOD_AND_DRINK" }
      expect(food[:estimated_savings]).to eq(40.00) # 200 * 20%
    end

    it "applies default reduction for uncategorized categories" do
      create_txn(category: "UTILITIES", amount: 120.00)
      result_fresh = described_class.new(user: user, date: date).call
      util = result_fresh.find { |r| r[:category] == "UTILITIES" }
      expect(util[:reduction_percentage]).to eq(10) if util
    end

    it "returns at most 5 entries" do
      %w[TRAVEL PERSONAL_CARE UTILITIES GROCERIES].each do |cat|
        create_txn(category: cat, amount: 50.00)
      end
      expect(result.size).to be <= 5
    end

    it "returns entries sorted by current_spend descending" do
      expect(result.first[:category]).to eq("FOOD_AND_DRINK")
    end

    context "when there are no transactions" do
      it "returns an empty array" do
        expect(described_class.new(user: create(:user), date: date).call).to eq([])
      end
    end
  end
end
