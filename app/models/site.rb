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

class Site < ApplicationRecord
  self.table_name = "site"

  # These correspond to the first-level NUTS regions for the UK (minus Northern Ireland)
  # https://en.wikipedia.org/wiki/First-level_NUTS_of_the_European_Union#United_Kingdom
  enum region_code: {
    'No region' => 0,
    'London' => 1,
    'South East' => 2,
    'South West' => 3,
    'Wales' => 4,
    'West Midlands' => 5,
    'East Midlands' => 6,
    'Eastern' => 7,
    'North West' => 8,
    'Yorkshire & the Humber' => 9,
    'North East' => 10,
    'Scotland' => 11,
  }

  belongs_to :provider
end
