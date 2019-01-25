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
#

class Provider < ApplicationRecord
  self.table_name = "provider"

  include RegionCode

  enum provider_type: {
    "SCITT" => "B",
    "Lead school" => "Y",
    "University" => "O",
    "??" => "",
    "Invalid value" => "0", # there is only one of these in the data
  }

  has_and_belongs_to_many :organisations, join_table: :organisation_provider

  has_many :sites
  has_many :enrichments, foreign_key: :provider_code, primary_key: :provider_code, class_name: "ProviderEnrichment"

  scope :changed_since, ->(datetime) do
    joins(:sites).where(
      'provider.updated_at >= :since OR site.updated_at >= :since',
      since: datetime
    )
  end

  # TODO: filter to published enrichments, maybe rename to published_address_info
  def address_info
    (enrichments.with_address_info.last || self)
      .attributes_before_type_cast
      .slice('address1', 'address2', 'address3', 'address4', 'postcode', 'region_code')
  end
end
