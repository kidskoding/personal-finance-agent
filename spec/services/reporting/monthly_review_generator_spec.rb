require 'rails_helper'

RSpec.describe Reporting::MonthlyReviewGenerator do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }
  let(:date) { Date.new(2026, 3, 1) }

  let(:anthropic_client) { instance_double(Anthropic::Client) }
  let(:messages_api) { instance_double(Anthropic::Resources::Messages, create: claude_response) }
  let(:review_text) { "March was a solid month. Here are your highlights..." }
  let(:text_block) { double("text_block", type: :text, text: review_text) }
  let(:claude_response) { double("response", content: [ text_block ]) }

  subject(:result) { described_class.new(user: user, date: date).call }

  before do
    stub_const("ENV", ENV.to_h.merge("ANTHROPIC_API_KEY" => "test-key"))
    allow(Anthropic::Client).to receive(:new).and_return(anthropic_client)
    allow(anthropic_client).to receive(:messages).and_return(messages_api)

    create(:transaction, user: user, account: account,
      category_primary: "FOOD_AND_DRINK", amount: 300.00,
      merchant_name: "Chipotle", posted_date: date, pending: false)
  end

  describe "#call" do
    it "calls Claude and returns review text" do
      expect(result).to eq(review_text)
    end

    it "includes the month in the prompt" do
      expect(messages_api).to receive(:create) do |args|
        user_message = args[:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include("March 2026")
        claude_response
      end
      result
    end

    it "includes category breakdown in the prompt" do
      expect(messages_api).to receive(:create) do |args|
        user_message = args[:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include("FOOD_AND_DRINK")
        claude_response
      end
      result
    end

    it "uses claude-opus-4-6" do
      expect(messages_api).to receive(:create).with(
        hash_including(model: :"claude-opus-4-6")
      ).and_return(claude_response)
      result
    end

    context "when prior recommendations exist" do
      before do
        create(:recommendation, user: user,
          month: date.beginning_of_month,
          content: "Cut back on dining.",
          generated_at: 1.day.ago)
      end

      it "includes prior recommendations in the prompt" do
        expect(messages_api).to receive(:create) do |args|
          user_message = args[:messages].find { |m| m[:role] == "user" }
          expect(user_message[:content]).to include("Cut back on dining.")
          claude_response
        end
        result
      end
    end
  end
end
