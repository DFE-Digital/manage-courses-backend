# == Schema Information
#
# Table name: provider
#
#  id                   :integer          not null, primary key
#  address4             :text
#  provider_name        :text
#  scheme_member        :text
#  contact_name         :text
#  year_code            :text
#  provider_code        :text
#  provider_type        :text
#  postcode             :text
#  scitt                :text
#  url                  :text
#  address1             :text
#  address2             :text
#  address3             :text
#  email                :text
#  telephone            :text
#  region_code          :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  accrediting_provider :text
#  last_published_at    :datetime
#  changed_at           :datetime         not null
#  opted_in             :boolean          default(FALSE)
#

require 'rails_helper'

describe Provider, type: :model do
  subject { create(:provider) }

  describe 'associations' do
    it { should have_many(:sites) }
    it { should have_many(:users).through(:organisations) }
    it { should have_one(:ucas_preferences).class_name('ProviderUCASPreference') }
    it { should have_many(:contacts) }
  end

  describe 'changed_at' do
    it 'is set on create' do
      provider = Provider.create
      expect(provider.changed_at).to be_present
      expect(provider.changed_at).to eq provider.updated_at
    end

    it 'is set on update' do
      Timecop.freeze do
        provider = create(:provider, updated_at: 1.hour.ago)
        provider.touch
        expect(provider.changed_at).to eq provider.updated_at
        expect(provider.changed_at).to eq Time.now.utc
      end
    end
  end

  describe '#contact_info' do
    it 'returns address of the provider' do
      provider = create(:provider, enrichments: [])

      expect(provider.contact_info).to eq(
        'address1' => provider.address1,
        'address2' => provider.address2,
        'address3' => provider.address3,
        'address4' => provider.address4,
        'postcode' => provider.postcode,
        'region_code' => provider.region_code_before_type_cast,
        'email' => provider.email,
        'telephone' => provider.telephone
      )
    end
  end

  describe '#changed_since' do
    context 'with a provider that has been changed after the given timestamp' do
      let(:provider) { create(:provider, changed_at: 5.minutes.ago) }

      subject { Provider.changed_since(10.minutes.ago) }

      it { should include provider }
    end

    context 'with a provider that has been changed less than a second after the given timestamp' do
      let(:timestamp) { 5.minutes.ago }
      let(:provider) { create(:provider, changed_at: timestamp + 0.001.seconds) }

      subject { Provider.changed_since(timestamp) }

      it { should include provider }
    end

    context 'with a provider that has been changed exactly at the given timestamp' do
      let(:publish_time) { 10.minutes.ago }
      let(:provider) { create(:provider, changed_at: publish_time) }

      subject { Provider.changed_since(publish_time) }

      it { should_not include provider }
    end

    context 'with a provider that has been changed before the given timestamp' do
      let(:provider) { create(:provider, changed_at: 1.hour.ago) }

      subject { Provider.changed_since(10.minutes.ago) }

      it { should_not include provider }
    end
  end

  describe '.opted_in' do
    let!(:opted_in_provider) { create(:provider, opted_in: true) }
    let!(:opted_out_provider) { create(:provider, opted_in: false) }

    it 'returns only the opted_in provider' do
      expect(Provider.opted_in).to match_array([opted_in_provider])
    end
  end

  describe '.in_order' do
    let!(:second_alphabetical_provider) { create(:provider, provider_name: "Zork") }
    let!(:first_alphabetical_provider) { create(:provider, provider_name: "Acme") }

    it 'returns sorted providers' do
      expect(Provider.in_order).to match_array([first_alphabetical_provider, second_alphabetical_provider])
    end
  end

  describe '#update_changed_at' do
    let(:provider) { create(:provider, changed_at: 1.hour.ago) }

    it 'sets changed_at to the current time' do
      Timecop.freeze do
        provider.update_changed_at
        expect(provider.changed_at).to eq Time.now.utc
      end
    end

    it 'sets changed_at to the given time' do
      timestamp = 1.hour.ago
      provider.update_changed_at timestamp: timestamp
      expect(provider.changed_at).to eq timestamp
    end

    it 'leaves updated_at unchanged' do
      timestamp = 1.hour.ago
      provider.update updated_at: timestamp

      provider.update_changed_at
      expect(provider.updated_at).to eq timestamp
    end
  end
end
