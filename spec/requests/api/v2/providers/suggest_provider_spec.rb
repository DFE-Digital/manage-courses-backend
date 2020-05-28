require "rails_helper"

describe "GET /suggest" do
  let(:jsonapi_renderer) { JSONAPI::Serializable::Renderer.new }
  let(:organisation) { create(:organisation) }
  let(:next_recruitment_cycle) { find_or_create(:recruitment_cycle, :next) }
  let(:user) { create :user, organisations: [organisation] }
  let(:payload) { { email: user.email } }
  let(:token) { build_jwt :apiv2, payload: payload }
  let(:credentials) do
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end
  let(:provider) { create(:provider, provider_name: "PROVIDER 1", organisations: [organisation]) }
  let(:provider2)  { create(:provider, provider_name: "PROVIDER 2", organisations: [organisation]) }

  context "current recruitment cycle" do
    before do
      provider
      provider2
    end

    it "searches for a particular provider" do
      get "/api/v2/providers/suggest?query=#{provider.provider_name}",
          headers: { "HTTP_AUTHORIZATION" => credentials }

      expect(JSON.parse(response.body)["data"]).
          to match_array([
                             {
                                 "id" => provider.id.to_s,
                                 "type" => "provider",
                                 "attributes" => {
                                     "provider_code" => provider.provider_code,
                                     "provider_name" => provider.provider_name,
                                 },
                             },
                         ])
    end

    it "searches for a partial provider" do
      get "/api/v2/providers/suggest?query=#{provider2.provider_name[0..3]}",
          headers: { "HTTP_AUTHORIZATION" => credentials }

      expect(JSON.parse(response.body)["data"]).
          to match_array([
                             {
                                 "id" => provider.id.to_s,
                                 "type" => "provider",
                                 "attributes" => {
                                     "provider_code" => provider.provider_code,
                                     "provider_name" => provider.provider_name,
                                 },
                             },
                             {
                                 "id" => provider2.id.to_s,
                                 "type" => "provider",
                                 "attributes" => {
                                     "provider_code" => provider2.provider_code,
                                     "provider_name" => provider2.provider_name,
                                 },
                             },
                         ])
    end
  end

  context "next recruitment cycle" do
    it "searches for a provider" do
      next_recruitment_cycle = find_or_create(:recruitment_cycle, :next)
      provider = create(:provider, organisations: [organisation], recruitment_cycle: next_recruitment_cycle)

      get "/api/v2/providers/suggest?query=#{provider.provider_name}",
          headers: { "HTTP_AUTHORIZATION" => credentials }

      expect(JSON.parse(response.body)["data"]).to match_array([])
    end
  end

  it "limits responses to a maximum of 5 items" do
    11.times do
      create(:provider, provider_name: "provider X", organisations: [organisation], recruitment_cycle: next_recruitment_cycle)
    end

    get "/api/v2/recruitment_cycles/#{next_recruitment_cycle.year}/providers/suggest?query=provider",
        headers: { "HTTP_AUTHORIZATION" => credentials }

    expect(JSON.parse(response.body)["data"].length).to eq(5)
  end

  it "returns bad request if query is empty" do
    get "/api/v2/providers/suggest",
        headers: { "HTTP_AUTHORIZATION" => credentials }

    expect(response.status).to eq(400)
  end

  it "returns bad request if query is too short" do
    provider

    get "/api/v2/providers/suggest?query=#{provider.provider_name[0, 1]}",
        headers: { "HTTP_AUTHORIZATION" => credentials }

    expect(response.status).to eq(400)
  end

  it "returns bad request if start of query is not alphanumeric" do
    get "/api/v2/providers/suggest?query=%22%22%22%22",
        headers: { "HTTP_AUTHORIZATION" => credentials }

    expect(response.status).to eq(400)
  end
end
