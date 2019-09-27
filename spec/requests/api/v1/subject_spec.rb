require "rails_helper"

describe "Subjecs API", type: :request do
  describe "GET index" do
    before do
      find_or_create(:subject, :modern_languages)
      find_or_create(:subject, :english)
      find_or_create(:subject, :french)
      find_or_create(:subject, :primary)
      find_or_create(:subject, :further_education)
      find_or_create(:subject, :humanities)
    end

    it "returns http success" do
      get "/api/v1/2019/subjects", headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Token.encode_credentials("bats") }
      expect(response).to have_http_status(:success)
    end

    it "returns http unauthorized" do
      get "/api/v1/2019/subjects", headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Token.encode_credentials("foo") }
      expect(response).to have_http_status(:unauthorized)
    end

    it "JSON body response contains expected provider attributes" do
      get "/api/v1/2019/subjects", headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Token.encode_credentials("bats") }

      json = JSON.parse(response.body)
      expect(json).to eq([
          {
            "subject_name" => "English",
            "subject_code" => "E",
          },
          {
            "subject_name" => "French",
            "subject_code" => "F1",
          },
          {
            "subject_name" => "Primary",
            "subject_code" => "00",
          },
          {
            "subject_name" => "Further education",
            "subject_code" => "41",
          },
        ])
    end
  end
end
