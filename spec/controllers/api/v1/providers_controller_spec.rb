require 'rails_helper'

RSpec.describe Api::V1::ProvidersController, type: :controller do
  describe "index" do
    it "render service unavailable" do
      allow(controller).to receive(:index).and_raise(PG::ConnectionBad)
      allow(controller).to receive(:authenticate)

      get :index
      expect(response).to have_http_status(:service_unavailable)
      json = JSON.parse(response.body)
      expect(json). to eq(
        'code' => 503, 'status' => 'Service Unavailable'
      )
    end

    it "calls limit on the model with default value of 100" do
      allow(controller).to receive(:authenticate)
      expect(Provider).to receive_message_chain(:changed_since, :limit).with(100).and_return([])

      get :index
    end

    it 'renders a 400 when the changed_since param is not valid' do
      allow(controller).to receive(:authenticate)

      get :index, params: { changed_since: '2019' }
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json). to eq(
        'status' => 400, 'message' => 'Invalid changed_since value, the format should be a iso8601 timestamp'
      )
    end
  end
end
