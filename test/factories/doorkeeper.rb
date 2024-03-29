FactoryBot.define do
  factory :access_grant, class: "Doorkeeper::AccessGrant" do
    sequence(:resource_owner_id) { |n| n }
    application
    redirect_uri { "https://app.com/callback" }
    expires_in { 100 }
  end

  factory :access_token, class: "Doorkeeper::AccessToken" do
    sequence(:resource_owner_id) { |n| n }
    application
    expires_in { 2.hours }

    factory :clientless_access_token do
      application { nil }
    end
  end

  factory :application, class: "OauthApplication" do
    sequence(:name) { |n| "Application #{n}" }
    redirect_uri { "https://app.com/callback" }
  end
end
