require "rails_helper"

RSpec.describe SiteSerializer do
  let(:site) { create :site }

  subject { serialize(site) }

  it { is_expected.to include(name: site.location_name, campus_code: site.code) }
  it { is_expected.to include(region_code: "%02d" % site.region_code_before_type_cast) }

  describe "SiteSerializer#region_code" do
    subject do
      serialize(site)["region_code"]
    end

    describe "region code is set" do
      let(:site) { create :site, region_code: region_code }
      let(:region_code) { 1 }

      it { is_expected.to eql("%02d" % region_code) }
    end
  end
end
