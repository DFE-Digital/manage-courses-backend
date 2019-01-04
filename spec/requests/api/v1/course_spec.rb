require "rails_helper"

RSpec.describe "Courses API", type: :request do
  describe 'GET index' do
    before do
      provider = FactoryBot.create(:provider, provider_name: "ACME SCITT", provider_code: "2LD", site_count: 0, course_count: 0)
      site = FactoryBot.create(:site, code: "-", location_name: "Main Site", provider: provider)
      subject1 = FactoryBot.create(:subject, subject_code: "1", subject_name: "Secondary")
      subject2 = FactoryBot.create(:subject, subject_code: "2", subject_name: "Mathematics")

      course = FactoryBot.create(:course,
        course_code: "2HPF",
        start_date: Date.new(2019, 9, 1),
        name: "Religious Education",
        qualification: 1,
        sites: [site],
        subjects: [subject1, subject2],
        study_mode: "F",
        english: 3,
        maths: 9,
        profpost_flag: "Postgraduate",
        program_type: "SD",
        modular: "",
        provider: provider)

      course.site_statuses.first.update(
        vac_status: 'F',
        publish: 'Y',
        status: 'R',
        applications_accepted_from: "2018-10-09 00:00:00"
      )
    end

    it "returns http success" do
      get "/api/v1/courses", headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials("bat", "beta") }
      expect(response).to have_http_status(:success)
    end

    it "returns http unauthorised" do
      get "/api/v1/courses", headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials("foo", "bar") }
      expect(response).to have_http_status(:unauthorized)
    end

    it "JSON body response contains expected course attributes" do
      get "/api/v1/courses", headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials("bat", "beta") }

      json = JSON.parse(response.body)
      expect(json). to eq([
        {
          "course_code" => "2HPF",
          "start_month" => "2019-09-01T00:00:00Z",
          "name" => "Religious Education",
          "study_mode" => "F",
          "copy_form_required" => "Y",
          "profpost_flag" => "PG",
          "program_type" => "SD",
          "modular" => "",
          "english" => 3,
          "maths" => 9,
          "science" => nil,
          "qualification" => 1,
          "recruitment_cycle" => "2019",
          "campus_statuses" => [
            {
              "campus_code" => "-",
              "name" => "Main Site",
              "vac_status" => "F",
              "publish" => "Y",
              "status" => "R",
              "course_open_date" => "2018-10-09T00:00:00+00:00",
              "recruitment_cycle" => "2019"
            }
          ],
          "subjects" => [
            {
              "subject_code" => "1",
              "subject_name" => "Secondary"
            },
            {
              "subject_code" => "2",
              "subject_name" => "Mathematics"
            }
          ],
          "provider" => {
            "institution_code" => "2LD",
            "institution_name" => "ACME SCITT",
            "institution_type" => "Y",
            "accrediting_provider" => nil
          },
          "accrediting_provider" => nil
        }
      ])
    end
  end
end
