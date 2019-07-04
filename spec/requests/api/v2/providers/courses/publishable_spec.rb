require 'rails_helper'

describe 'Publishable API v2', type: :request do
  let(:user)         { create(:user) }
  let(:organisation) { create(:organisation, users: [user]) }
  let(:provider)     { create :provider, organisations: [organisation] }
  let(:payload)      { { email: user.email } }
  let(:token)        { build_jwt :apiv2, payload: payload }
  let(:credentials) do
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end

  describe 'POST publishable' do
    let(:course) { findable_open_course }
    let(:publishable_path) do
      "/api/v2/providers/#{provider.provider_code}" +
        "/courses/#{course.course_code}/publishable"
    end

    let(:enrichment) { build(:course_enrichment, :initial_draft) }
    let(:site_status) { build(:site_status, :new) }
    let(:course) {
      create(:course,
             provider: provider,
             site_statuses: [site_status],
             enrichments: [enrichment])
    }

    subject do
      post publishable_path,
           headers: { 'HTTP_AUTHORIZATION' => credentials },
           params: {
             _jsonapi: {
               data: {
                 attributes: {},
                 type: "course"
               }
             }
           }
      response
    end

    context 'when unauthenticated' do
      let(:payload) { { email: 'foo@bar' } }

      it { should have_http_status(:unauthorized) }
    end

    context 'when user has not accepted terms' do
      let(:user)         { create(:user, accept_terms_date_utc: nil) }
      let(:organisation) { create(:organisation, users: [user]) }

      it { should have_http_status(:forbidden) }
    end

    context 'when unauthorised' do
      let(:unauthorised_user) { create(:user) }
      let(:payload)           { { email: unauthorised_user.email } }

      it "raises an error" do
        expect { subject }.to raise_error Pundit::NotAuthorizedError
      end
    end

    context 'when course and provider is not related' do
      let(:course) { create(:course) }

      it { should have_http_status(:not_found) }
    end

    context 'unpublished course with draft enrichment' do\
      let(:enrichment) { build(:course_enrichment, :initial_draft) }
      let(:site_status) { build(:site_status, :new) }
      let!(:course) {
        create(:course,
               provider: provider,
               site_statuses: [site_status],
               enrichments: [enrichment],
               age: 17.days.ago)
      }

      it 'returns ok' do
        expect(subject).to have_http_status(:success)
      end
    end

    describe 'failed validation' do
      let(:json_data) { JSON.parse(subject.body)['errors'] }

      context 'no enrichments' do
        let(:course) { create(:course, provider: provider) }
        it { should have_http_status(:unprocessable_entity) }
        it 'has validation errors' do
          expect(json_data.count).to eq 1
          expect(response.body).to include('Invalid enrichment')
          expect(response.body).to include("Complete your course information before publishing")
        end
      end

      context 'fee type based course' do
        let(:course) { create(:course, :fee_type_based, provider: provider, enrichments: [invalid_enrichment]) }

        context 'invalid enrichment with invalid content lack_presence fields' do
          let(:invalid_enrichment) { create(:course_enrichment, :without_content) }

          it { should have_http_status(:unprocessable_entity) }

          it 'has validation error details' do
            expect(json_data.count).to eq 5
            expect(json_data[0]["detail"]).to eq("Enter details about this course")
            expect(json_data[1]["detail"]).to eq("Enter details about school placements")
            expect(json_data[2]["detail"]).to eq("Enter a course length")
            expect(json_data[3]["detail"]).to eq("Give details about the fee for UK and EU students")
            expect(json_data[4]["detail"]).to eq("Enter details about the qualifications needed")
          end

          it 'has validation error pointers' do
            expect(json_data[0]["source"]["pointer"]).to eq("/data/attributes/about_course")
            expect(json_data[1]["source"]["pointer"]).to eq("/data/attributes/how_school_placements_work")
            expect(json_data[2]["source"]["pointer"]).to eq("/data/attributes/course_length")
            expect(json_data[3]["source"]["pointer"]).to eq("/data/attributes/fee_uk_eu")
            expect(json_data[4]["source"]["pointer"]).to eq("/data/attributes/qualifications")
          end
        end
      end
    end
  end
end
