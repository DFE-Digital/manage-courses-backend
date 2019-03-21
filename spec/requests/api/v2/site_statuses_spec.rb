require 'rails_helper'

describe 'Site Helpers API V2' do
  let(:user) { create(:user) }
  let(:organisation) { create(:organisation, users: [user]) }
  let(:payload) { { email: user.email } }
  let(:token) do
    JWT.encode payload,
                Settings.authentication.secret,
                Settings.authentication.algorithm
  end
  let(:credentials) do
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end
  let!(:provider) { create(:provider, organisations: [organisation]) }

  describe 'PATCH update' do
    context 'when authenticated' do
      let(:course) do
        create(
          :course,
          provider: provider,
          with_site_statuses: [%i[
           with_no_vacancies
           running
           published
          ]]
        )
      end
      let(:site_status) { course.site_statuses.first }
      let(:jsonapi_renderer) { JSONAPI::Serializable::Renderer.new }
      let(:params) do
        {
          _jsonapi: jsonapi_renderer.render(
            site_status,
            class: {
              SiteStatus: API::V2::SerializableSiteStatus
            }
          )
        }
      end
      let(:site_status_params)         { params[:_jsonapi][:data][:attributes] }
      let(:applications_accepted_from) { '2019-01-01 00:00:00' }
      let(:publish)                    { 'unpublished' }
      let(:status)                     { 'discontinued' }
      let(:vac_status)                 { 'full_time_vacancies' }

      before do
        site_status_params[:applications_accepted_from] = applications_accepted_from
        site_status_params[:publish]                    = publish
        site_status_params[:status]                     = status
        site_status_params[:vac_status]                 = vac_status
      end

      subject do
        patch(
          api_v2_site_status_path(site_status),
          headers: { 'HTTP_AUTHORIZATION' => credentials },
          params: params
        )
      end

      it 'updates applications_accepted_from on the site status' do
        expect { subject }.to(
          change { site_status.reload.applications_accepted_from }
          .to(Date.parse('2019-01-01 00:00:00'))
        )
      end

      it 'updates publish on the site status' do
        expect { subject }.to(change { site_status.reload.publish }
          .from('published').to('unpublished'))
      end

      it 'updates status on the site status' do
        expect { subject }.to(change { site_status.reload.status }
          .from('running').to('discontinued'))
      end

      it 'updates vac_status on the site status' do
        expect { subject }.to(change { site_status.reload.vac_status }
          .from('no_vacancies').to('full_time_vacancies'))
      end
    end
  end
end
