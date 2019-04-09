require 'rails_helper'

describe API::V2::SerializableProvider do
  let(:provider) { create :provider }
  let(:resource) { API::V2::SerializableProvider.new object: provider }

  it 'sets type to providers' do
    expect(resource.jsonapi_type).to eq :providers
  end

  subject { resource.as_jsonapi.to_json }

  it { should be_json.with_content(type: 'providers') }
  it {
    should be_json.with_content(attributes: { provider_code: provider.provider_code,
                                              provider_name: provider.provider_name,
                                              opted_in: provider.opted_in,
                                              accrediting_provider: provider.accrediting_provider })
  }
end
