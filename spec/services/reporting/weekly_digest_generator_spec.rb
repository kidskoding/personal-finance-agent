require 'rails_helper'

RSpec.describe Reporting::WeeklyDigestGenerator do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }
  let(:week_start) { Date.new(2026, 3, 9) } # Monday

  let(:anthropic_client) { instance_double(Anthropic::Client) }
  let(:messages_api) { instance_double(Anthropic::Resources::Messages, create: claude_response) }
  let(:digest_text) { "Great week! You spent $150 total..." }
  let(:text_block) { double("text_block", type: :text, text: digest_text) }
  let(:claude_response) { double("response", content: [ text_block ]) }

  subject(:result) { described_class.new(user: user, week_start: week_start).call }

  before do
    stub_const("ENV", ENV.to_h.merge("ANTHROPIC_API_KEY" => "test-key"))
    allow(Anthropic::Client).to receive(:new).and_return(anthropic_client)
    allow(anthropic_client).to receive(:messages).and_return(messages_api)
  end

  describe "#call" do
    before do
      create(:transaction, user: user, account: account,
        category_primary: "FOOD_AND_DRINK", merchant_name: "Chipotle",
        amount: 50.00, posted_date: Date.new(2026, 3, 10), pending: false)
      create(:transaction, user: user, account: account,
        category_primary: "SHOPPING", merchant_name: "Amazon",
        amount: 100.00, posted_date: Date.new(2026, 3, 11), pending: false)
    end

    it "calls Claude and returns digest text" do
      expect(result).to eq(digest_text)
    end

    it "sends a prompt including the week date range" do
      expect(messages_api).to receive(:create) do |args|
        user_message = args[:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include("Mar 09")
        claude_response
      end
      result
    end

    it "includes total spend in the prompt" do
      expect(messages_api).to receive(:create) do |args|
        user_message = args[:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include("150.0")
        claude_response
      end
      result
    end

    it "excludes pending transactions" do
      create(:transaction, user: user, account: account,
        category_primary: "TRAVEL", amount: 500.00,
        posted_date: Date.new(2026, 3, 10), pending: true)
      expect(messages_api).to receive(:create) do |args|
        user_message = args[:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).not_to include("500.0")
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
  end
end
