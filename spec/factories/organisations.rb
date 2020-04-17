# == Schema Information
#
# Table name: organisation
#
#  id     :integer          not null, primary key
#  name   :text
#  org_id :text
#
# Indexes
#
#  IX_organisation_org_id  (org_id) UNIQUE
#

FactoryBot.define do
  factory :organisation do
    name { "LONDON SCITT" + rand(1000000).to_s }
    org_id { (Organisation.pluck(:org_id).map(&:to_i).max || 0) + 1 }

    trait :with_user do
      users { [create(:user)] }
    end
  end
end
