# == Schema Information
#
# Table name: allocation
#
#  accredited_body_id :bigint
#  created_at         :datetime         not null
#  id                 :bigint           not null, primary key
#  number_of_places   :integer
#  provider_id        :bigint
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_allocation_on_accredited_body_id  (accredited_body_id)
#  index_allocation_on_provider_id         (provider_id)
#
class Allocation < ApplicationRecord
  belongs_to :provider
  belongs_to :accredited_body, class_name: "Provider"

  validates :provider, :accredited_body, presence: true
  validate :accredited_body_is_an_accredited_body

private

  def accredited_body_is_an_accredited_body
    errors.add(:accredited_body, "must be an accredited body") unless accredited_body&.accredited_body?
  end
end