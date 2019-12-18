# == Schema Information
#
# Table name: site
#
#  address1      :text
#  address2      :text
#  address3      :text
#  address4      :text
#  code          :text             not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  latitude      :float
#  location_name :text
#  longitude     :float
#  postcode      :text
#  provider_id   :integer          default(0), not null
#  region_code   :integer
#  updated_at    :datetime         not null
#
# Indexes
#
#  IX_site_provider_id_code              (provider_id,code) UNIQUE
#  index_site_on_latitude_and_longitude  (latitude,longitude)
#

require "rails_helper"

describe Site, type: :model do
  subject { create(:site) }

  describe "auditing" do
    it { should be_audited.associated_with(:provider) }
  end

  it { is_expected.to validate_presence_of(:location_name) }
  it { is_expected.to validate_presence_of(:address1) }
  it { is_expected.to validate_presence_of(:postcode) }
  it { is_expected.to validate_uniqueness_of(:location_name).scoped_to(:provider_id) }
  it { is_expected.to validate_uniqueness_of(:code).case_insensitive.scoped_to(:provider_id) }
  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to validate_inclusion_of(:code).in_array(Site::POSSIBLE_CODES).with_message("must be A-Z, 0-9 or -") }

  describe "associations" do
    it { should belong_to(:provider) }
  end

  describe "#touch_provider" do
    let(:site) { create(:site) }

    it "sets changed_at to the current time" do
      Timecop.freeze do
        site.touch
        expect(site.provider.changed_at).to eq Time.now.utc
      end
    end

    it "leaves updated_at unchanged" do
      timestamp = 1.hour.ago
      site.provider.update updated_at: timestamp
      site.touch
      expect(site.provider.updated_at).to eq timestamp
    end
  end

  describe "after running validation" do
    let(:site) { build(:site, provider: provider, code: nil) }
    let(:provider) { build(:provider) }
    subject { site }

    it "is assigned a valid code by default" do
      expect { subject.valid? }.to change { subject.code.blank? }.from(true).to(false)
      expect(subject.errors[:code]).to be_empty
    end

    it "is assigned easily-confused codes only when all others have been used up" do
      (Site::DESIRABLE_CODES - %w[A]).each { |code| create(:site, code: code, provider: provider) }
      subject.validate
      expect(subject.code).to eq("A")
    end
  end

  its(:recruitment_cycle) { should eq find(:recruitment_cycle) }

  describe "description" do
    subject { build(:site, location_name: "Foo", code: "1") }
    its(:to_s) { should eq "Foo (code: 1)" }
  end

  describe "geolocation" do
    include ActiveJob::TestHelper

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    # Geocoding stubbed with support/helpers.rb
    let(:site) {
      build(:site,
            location_name: "Southampton High School",
            address1: "Long Lane",
            address2: "Holbury",
            address3: "Southampton",
            address4: nil,
            postcode: "SO45 2PA")
    }

    describe "#full_address" do
      it "Concatenates address details" do
        expect(site.full_address).to eq("Southampton High School, Long Lane, Holbury, Southampton, SO45 2PA")
      end
    end

    describe "#needs_geolocation?" do
      subject { site.needs_geolocation? }

      context "latitude is nil" do
        let(:site) { build_stubbed(:site, latitude: nil) }

        it { should be(true) }
      end

      context "longitude is nil" do
        let(:site) { build_stubbed(:site, longitude: nil) }

        it { should be(true) }
      end

      context "latitude and longitude is not nil" do
        let(:site) { build_stubbed(:site, latitude: 1.456789, longitude: 1.456789) }

        it { should be(false) }
      end

      context "address" do
        let(:site) {
          create(:site,
                 latitude: 1.456789,
                 longitude: 1.456789,
                 location_name: "Southampton High School",
                 address1: "Long Lane",
                 address2: "Holbury",
                 address3: "Southampton",
                 address4: nil,
                 postcode: "SO45 2PA")
        }
        context "has not changed" do
          before do
            site.update(address1: "Long Lane")
          end

          it { should be(false) }
        end

        context "has changed" do
          before do
            site.update(address1: "New address 1")
          end

          it { should be(true) }
        end
      end
    end
  end
end
