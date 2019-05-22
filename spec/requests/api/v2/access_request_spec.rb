require 'rails_helper'

describe 'Access Request API V2', type: :request do
  # Specify a fixed admin email to avoid randomisation from the factory, must qualify as #admin?
  let(:admin_user) { create(:user, email: "super.admin@digital.education.gov.uk") }
  let(:requesting_user) { create(:user, organisations: [organisation]) }
  let(:requested_user) { create(:user) }
  let(:organisation) { create(:organisation) }
  let(:payload) { { email: admin_user.email } }
  let(:access_request) {
    create(:access_request,
           email_address: requested_user.email,
           requester_email: requesting_user.email,
           requester_id: requesting_user.id,
           organisation: organisation.name)
  }
  let(:token) do
    JWT.encode payload,
               Settings.authentication.secret,
               Settings.authentication.algorithm
  end
  let(:credentials) do
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end

  subject { response }

  describe 'GET #index' do
    let(:access_requests_index_route) do
      get "/api/v2/access_requests",
          headers: { 'HTTP_AUTHORIZATION' => credentials },
          params: { include: 'requester' }
    end

    context 'when unauthenticated' do
      before do
        access_requests_index_route
      end

      let(:payload) { { email: 'foo@bar' } }

      it { should have_http_status(:unauthorized) }
    end

    context 'when unauthorized' do
      let(:unauthorised_user) { create(:user) }
      let(:payload) { { email: unauthorised_user.email } }
      let(:unauthorised_user_route) do
        get "/api/v2/access_requests",
            headers: { 'HTTP_AUTHORIZATION' => credentials }
      end


      it "should raise an error" do
        expect { unauthorised_user_route }.to raise_error Pundit::NotAuthorizedError
      end
    end

    context 'when authorised' do
      let!(:first_access_request) { create(:access_request) }
      let!(:second_access_request) { create(:access_request) }

      before do
        Timecop.freeze
        access_requests_index_route
      end

      after do
        Timecop.return
      end


      it 'JSON displays the correct attributes' do
        json_response = JSON.parse response.body

        expect(json_response).to eq(
          "data" => [
            {
              "id" => first_access_request.id.to_s,
              "type" => "access_request",
              "attributes" => {
                "email_address" => first_access_request.recipient.email,
                "first_name" => first_access_request.recipient.first_name,
                "last_name" => first_access_request.recipient.last_name,
                "requester_email" => first_access_request.requester.email,
                "requester_id" => first_access_request.requester.id,
                "organisation" => first_access_request.organisation,
                "reason" => first_access_request.reason,
                "request_date_utc" => first_access_request.request_date_utc.iso8601,
                "status" => first_access_request.status
              },
              "relationships" => {
                "requester" => {
                  "data" => {
                    "type" => "users",
                    "id" => first_access_request.requester.id.to_s
                  }
                }
              }
            },
            {
             "id" => second_access_request.id.to_s,
             "type" => "access_request",
             "attributes" => {
               "email_address" => second_access_request.recipient.email,
               "first_name" => second_access_request.recipient.first_name,
               "last_name" => second_access_request.recipient.last_name,
               "requester_email" => second_access_request.requester.email,
               "requester_id" => second_access_request.requester.id,
               "organisation" => second_access_request.organisation,
               "reason" => second_access_request.reason,
               "request_date_utc" => second_access_request.request_date_utc.iso8601,
               "status" => second_access_request.status
             },
             "relationships" => {
               "requester" => {
                 "data" => {
                   "type" => "users",
                   "id" => second_access_request.requester.id.to_s
                 }
               }
             }
            }
            ],
        "jsonapi" => {
          "version" => "1.0"
        },
        "included" => [{
          "id" => first_access_request.requester.id.to_s,
          "type" => "users",
          "attributes" => {
            "first_name" => first_access_request.requester.first_name,
            "last_name" => first_access_request.requester.last_name,
            "email" => first_access_request.requester.email,
            "accept_terms_date_utc" => first_access_request.requester.accept_terms_date_utc.utc.strftime('%FT%T.%3NZ'),
            "state" => first_access_request.requester.state
          }
        }, {
          "id" => second_access_request.requester.id.to_s,
          "type" => "users",
          "attributes" => {
            "first_name" => second_access_request.requester.first_name,
            "last_name" => second_access_request.requester.last_name,
            "email" => second_access_request.requester.email,
            "accept_terms_date_utc" => second_access_request.requester.accept_terms_date_utc.utc.strftime('%FT%T.%3NZ'),

            "state" => second_access_request.requester.state
          }
        }]
       )
      end
    end
  end

  describe 'POST #approve' do
    let(:approve_route_request) do
      post "/api/v2/access_requests/#{access_request.id}/approve",
           headers: { 'HTTP_AUTHORIZATION' => credentials }
    end
    context 'when unauthenticated' do
      before do
        approve_route_request
      end

      let(:payload) { { email: 'foo@bar' } }

      it { should have_http_status(:unauthorized) }
    end

    context 'when unauthorized' do
      let(:unauthorised_user) { create(:user) }
      let(:payload) { { email: unauthorised_user.email } }

      it "should raise an error" do
        expect { approve_route_request }.to raise_error Pundit::NotAuthorizedError
      end
    end

    context 'when authorised' do
      before do
        approve_route_request
      end

      it 'updates the requests status to completed' do
        expect(access_request.reload.status). to eq 'completed'
      end

      it 'has a successful response' do
        expect(response.body).to eq({ result: true }.to_json)
      end

      context 'when the user requested user already exists' do
        it 'gives a pre existing user access to the right organisations' do
          expect(requested_user.organisations).to eq requesting_user.organisations
        end
      end

      context 'when email address does not belong to a user' do
        let(:new_user_access_request) {
          create(:access_request,
                 first_name: 'test',
                 last_name: 'user',
                 email_address: 'test@user.com',
                 requester_email: requesting_user.email,
                 requester_id: requesting_user.id,
                 organisation: organisation.name)
        }
        before do
          post "/api/v2/access_requests/#{new_user_access_request.id}/approve",
               headers: { 'HTTP_AUTHORIZATION' => credentials }
        end

        it 'creates a new account for a new user and gives access to the right orgs' do
          new_user = User.find_by!(email: 'test@user.com')

          expect(new_user.organisations).to eq requesting_user.organisations
        end
      end
    end
  end

  describe 'POST #create' do
    let(:do_post) do
      post "/api/v2/access_requests",
           headers: { 'HTTP_AUTHORIZATION' => credentials },
           params: { access_request: {
             email_address: "bob@example.org",
             first_name: "bob",
             last_name: "monkhouse",
             organisation: "bbc",
             reason: "star qualities",
           } }.as_json
    end
    context 'when unauthenticated' do
      before do
        do_post
      end

      let(:payload) { { email: 'foo@bar' } }

      it { should have_http_status(:unauthorized) }
    end

    context 'when unauthorized' do
      let(:unauthorised_user) { create(:user) }
      let(:payload) { { email: unauthorised_user.email } }

      it "should raise an error" do
        expect { do_post }.to raise_error Pundit::NotAuthorizedError
      end
    end

    context 'when authorised' do
      before do
        Timecop.freeze
        do_post
      end

      after do
        Timecop.return
      end

      it 'returns the correct id' do
        string_id = JSON.parse(response.body)["data"]['id']
        id = Integer(string_id)

        expect(id).to be > 0
      end

      describe 'JSON returns the correct attributes' do
        subject { JSON.parse(response.body)["data"]['attributes'] }

        its(%w[email_address]) { should eq('bob@example.org') }
        its(%w[first_name]) { should eq('bob') }
        its(%w[last_name]) { should eq('monkhouse') }
        its(%w[organisation]) { should eq('bbc') }
        its(%w[reason]) { should eq('star qualities') }
      end

      context 'with a user that does not already exist' do
        it 'should create the access_request record' do
          expect(response).to have_http_status(:success)
          access_request = AccessRequest.find_by(email_address: "bob@example.org")
          expect(access_request).not_to be_nil
          expect(access_request.first_name).to eq("bob")
          expect(access_request.last_name).to eq("monkhouse")
          expect(access_request.organisation).to eq("bbc")
          expect(access_request.reason).to eq("star qualities")
          expect(access_request.request_date_utc).to be_within(1.second).of Time.now.utc # https://github.com/travisjeffery/timecop/issues/97
          expect(access_request.requester.email).to eq("super.admin@digital.education.gov.uk")
        end
      end
    end
  end
end
