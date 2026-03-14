require 'rails_helper'

RSpec.describe Planning::RecommendationGenerator do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }
  let(:date) { Date.new(2026, 3, 1) }

  let(:anthropic_client) { instance_double(Anthropic::Client) }
  let(:messages_api) { instance_double(Anthropic::Resources::Messages, create: claude_response) }
  let(:recommendation_text) { "1. Cut back on dining out.\n2. Review your subscriptions." }
  let(:text_block) { double("text_block", type: :text, text: recommendation_text) }
  let(:claude_response) { double("claude_response", content: [ text_block ]) }

  subject(:service) { described_class.new(user: user, date: date) }

  before do
    stub_const("ENV", ENV.to_h.merge("ANTHROPIC_API_KEY" => "test-key"))
    allow(Anthropic::Client).to receive(:new).and_return(anthropic_client)
    allow(anthropic_client).to receive(:messages).and_return(messages_api)

    # Seed some transactions so analytics services return data
    create(:transaction, user: user, account: account,
      category_primary: "FOOD_AND_DRINK", amount: 200.00,
      merchant_name: "Chipotle", posted_date: date, pending: false)
  end

  describe "#call" do
    it "calls the Claude API with the analytics summary" do
      expect(messages_api).to receive(:create).with(
        hash_including(
          model: :"claude-opus-4-6",
          max_tokens: 1024
        )
      ).and_return(claude_response)

      service.call
    end

    it "stores a Recommendation record" do
      expect { service.call }.to change(Recommendation, :count).by(1)
    end

    it "stores the recommendation content from Claude" do
      service.call
      rec = Recommendation.last
      expect(rec.content).to eq(recommendation_text)
    end

    it "sets the month to the beginning of the month" do
      service.call
      expect(Recommendation.last.month).to eq(Date.new(2026, 3, 1))
    end

    it "sets generated_at" do
      service.call
      expect(Recommendation.last.generated_at).to be_present
    end

    it "includes the user in the prompt" do
      expect(messages_api).to receive(:create) do |args|
        user_message = args[:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include("March 2026")
        claude_response
      end

      service.call
    end

    it "includes spending data in the prompt" do
      expect(messages_api).to receive(:create) do |args|
        user_message = args[:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include("FOOD_AND_DRINK")
        claude_response
      end

      service.call
    end
  end
end
