class NightlyPlaidSyncJob < ApplicationJob
  queue_as :default

  def perform
    PlaidItem.find_each do |plaid_item|
      SyncTransactionsJob.perform_later(plaid_item.id)
    end
  end
end
