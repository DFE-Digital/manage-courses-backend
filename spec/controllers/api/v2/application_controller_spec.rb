require 'rails_helper'

describe Api::V2::ApplicationController, type: :controller do
  describe '#authenticate' do
    let(:user) { create(:user) }
    let(:payload) { { email: user.email } }
    let(:encoded_token) do
      JWT.encode payload.to_json,
                 Settings.authentication.secret,
                 Settings.authentication.encoding
    end

    before do
      controller.response = response
      request.headers['Authorization'] = "Bearer #{encoded_token}"
    end

    subject { controller.authenticate }

    it { should be true }

    context 'user is not valid' do
      let(:payload) { { email: 'foobar' } }

      it { should eq "HTTP Token: Access denied.\n" }

      it 'requests authentication via the http header' do
        controller.authenticate

        expect(response.headers['WWW-Authenticate'])
          .to eq 'Token realm="Application"'
      end
    end

    context `errors` do
      context 'empty payload' do
        let(:payload) {}

        it 'raise error' do
          expect { controller.authenticate }.to raise_error NoMethodError
        end
      end

      context 'JWT mismatch' do
        context 'secret' do
          let(:encoded_token) do
            JWT.encode payload.to_json,
                       'mismatch secret',
                       Settings.authentication.encoding
          end

          it 'raise error' do
            expect { controller.authenticate }.to raise_error JWT::VerificationError
          end
        end

        context 'encoding' do
          let(:encoded_token) do
            JWT.encode payload.to_json,
                       Settings.authentication.secret,
                       'HS384'
          end

          it 'raise error' do
            expect { controller.authenticate }.to raise_error JWT::IncorrectAlgorithm
          end
        end
      end
    end
  end
end
