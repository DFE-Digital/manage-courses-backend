require "rails_helper"

RSpec.describe "Providers API", type: :request do
  describe 'GET index' do
    before do
      provider = FactoryBot.create(:provider,
        provider_name: "ACME SCITT",
        provider_code: "A123",
        provider_type: 'Y',
        site_count: 0)
      FactoryBot.create(:site,
        location_name: "Main site",
        code: "-",
        provider: provider)

      get "/api/v1/providers", headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials("bat", "beta") }
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "JSON body response contains expected provider attributes" do
      json = JSON.parse(response.body)
      expect(json). to eq(
        [
          {
            "accrediting_provider" => nil,
            "campuses" => [
              {
                "campus_code" => "-",
                "name" => "Main site",
              }
            ],
            "institution_code" => "A123",
            "institution_name" => "ACME SCITT",
            "institution_type" => "Y",
          },
        ]
      )
    end
  end
end
