# == Schema Information
#
# Table name: site
#
#  id            :integer          not null, primary key
#  address2      :text
#  address3      :text
#  address4      :text
#  code          :text             not null
#  location_name :text
#  postcode      :text
#  address1      :text
#  provider_id   :integer          default(0), not null
#

require "rails_helper"

RSpec.describe SiteSerializer do
  let(:site) { create :site }
  subject { serialize(site) }

  it { is_expected.to include(name: site.location_name, campus_code: site.code, region_code: site.region_code) }
end
