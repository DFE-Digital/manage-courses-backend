require "rails_helper"

describe 'PATCH /providers/:provider_code/courses/:course_code' do
  let(:jsonapi_renderer) { JSONAPI::Serializable::Renderer.new }

  def perform_request(updated_start_date)
    jsonapi_data = jsonapi_renderer.render(
      course,
      class: {
        Course: API::V2::SerializableCourse
      }
    )

    jsonapi_data[:data][:attributes] = updated_start_date

    patch "/api/v2/providers/#{course.provider.provider_code}" \
            "/courses/#{course.course_code}",
          headers: { 'HTTP_AUTHORIZATION' => credentials },
          params: {
            _jsonapi: jsonapi_data
          }
  end
  let(:organisation)      { create :organisation }
  let(:provider)          { create :provider, organisations: [organisation] }
  let(:user)              { create :user, organisations: [organisation] }
  let(:payload)           { { email: user.email } }
  let(:token)             { build_jwt :apiv2, payload: payload }

  let(:course)            {
    create :course,
           provider: provider,
           start_date: 10.days.from_now.utc.iso8601
  }

  let(:credentials) do
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end

  let(:permitted_params) do
    %i[updated_start_date]
  end

  before do
    Timecop.freeze
    perform_request(updated_start_date)
  end

  after do
    Timecop.return
  end

  context "course has an updated start_date" do
    let(:updated_start_date) { { start_date: Time.now.utc.iso8601 } }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "updates start_date attribute to the correct value" do
      expect(course.reload.start_date).to eq(updated_start_date[:start_date])
    end
  end

  context "course has the same start_date" do
    context "with values passed into the params" do
      let(:updated_start_date) { { start_date: 10.days.from_now.utc.iso8601 } }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "does not change qualification attribute" do
        expect(course.reload.start_date).to eq(updated_start_date[:start_date])
      end
    end
  end

  context "with no values passed into the params" do
    let(:updated_start_date) { {} }
    let!(:start_date) { course.start_date }

    before do
      perform_request(updated_start_date)
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "does not change start_date attribute" do
      expect(course.reload.start_date).to eq(start_date)
    end
  end
end
