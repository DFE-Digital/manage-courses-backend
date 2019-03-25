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

require "rails_helper"

describe ProviderSerializer do
  let(:provider) { create :provider }

  subject { serialize(provider) }

  it { should include(institution_code: provider.provider_code) }
  it { should include(institution_name: provider.provider_name) }
  it { should include(address1: provider.enrichments.last.address1) }
  it { should include(address2: provider.enrichments.last.address2) }
  it { should include(address3: provider.enrichments.last.address3) }
  it { should include(address4: provider.enrichments.last.address4) }
  it { should include(postcode: provider.enrichments.last.postcode) }
  it { should include(institution_type: provider.provider_type) }
  it { should include(accrediting_provider: provider.accrediting_provider) }
  it { should include(contact_name: provider.contact_name) }
  it { should include(email: provider.enrichments.last.email) }
  it { should include(telephone: provider.enrichments.last.telephone) }

  describe 'ProviderSerializer#region_code' do
    subject do
      serialize(provider)["region_code"]
    end

    describe "provider region code 'London' can be overriden by enrichment region code 'Scotland'" do
      let(:enrichment) do
        build(:provider_enrichment, region_code: :scotland)
      end

      let(:provider) { create :provider, region_code: :london, enrichments: [enrichment] }
      it { is_expected.not_to eql("%02d" % 1) }
      it { is_expected.to eql("%02d" % 11) }
    end

    describe "provider region code 00 is overriden with enrichment region code" do
      let(:enrichment) do
        build(:provider_enrichment, region_code: region_code)
      end
      let(:region_code) { 1 }
      let(:provider) { create :provider, region_code: 0, enrichments: [enrichment] }
      it { is_expected.to eql("%02d" % region_code) }
      it { is_expected.not_to eql("%02d" % 0) }
    end
  end

  describe 'type_of_gt12' do
    subject { serialize(provider)['type_of_gt12'] }

    it { should eq provider.ucas_preferences.type_of_gt12_before_type_cast }
  end

  describe 'utt_application_alerts' do
    subject { serialize(provider)['utt_application_alerts'] }

    it { should eq provider.ucas_preferences.send_application_alerts_before_type_cast }
  end

  describe 'contacts' do
    describe 'admin contact' do
      let(:provider) do
        create :provider,
               contacts: [admin]
      end
      let(:admin) { create(:contact, type: 'admin') }

      subject { serialize(provider)['contacts'].find { |c| c[:type] == 'admin' } }

      its([:name]) { should eq admin.name }
      its([:email]) { should eq admin.email }
      its([:telephone]) { should eq admin.telephone }
    end

    describe 'utt contact' do
      let(:provider) do
        create :provider,
               contacts: [utt]
      end
      let(:utt) { create(:contact, type: 'utt') }

      subject { serialize(provider)['contacts'].find { |c| c[:type] == 'utt' } }

      its([:name]) { should eq utt.name }
      its([:email]) { should eq utt.email }
      its([:telephone]) { should eq utt.telephone }
    end

    describe 'web_link contact' do
      let(:provider) do
        create :provider,
               contacts: [web_link]
      end
      let(:web_link) { create(:contact, type: 'web_link') }

      subject { serialize(provider)['contacts'].find { |c| c[:type] == 'web_link' } }

      its([:name]) { should eq web_link.name }
      its([:email]) { should eq web_link.email }
      its([:telephone]) { should eq web_link.telephone }
    end

    describe 'fraud contact' do
      let(:provider) do
        create :provider,
               contacts: [fraud]
      end

      let(:fraud) { create(:contact, type: 'fraud') }

      subject { serialize(provider)['contacts'].find { |c| c[:type] == 'fraud' } }

      its([:name]) { should eq fraud.name }
      its([:email]) { should eq fraud.email }
      its([:telephone]) { should eq fraud.telephone }
    end

    describe 'finance contact' do
      let(:provider) do
        create :provider,
               contacts: [finance]
      end

      let(:finance) { create(:contact, type: 'finance') }

      subject { serialize(provider)['contacts'].find { |c| c[:type] == 'finance' } }

      its([:name]) { should eq finance.name }
      its([:email]) { should eq finance.email }
      its([:telephone]) { should eq finance.telephone }
    end
  end
end
