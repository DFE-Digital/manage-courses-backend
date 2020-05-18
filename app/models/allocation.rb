# == Schema Information
#
# Table name: allocation
#
#  accredited_body_code :text
#  accredited_body_id   :bigint
#  created_at           :datetime         not null
#  id                   :bigint           not null, primary key
#  number_of_places     :integer
#  provider_code        :text
#  provider_id          :bigint
#  recruitment_cycle_id :integer
#  request_type         :integer          default("initial")
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_allocation_on_accredited_body_id  (accredited_body_id)
#  index_allocation_on_provider_id         (provider_id)
#  index_allocation_on_request_type        (request_type)
#
class Allocation < ApplicationRecord
  belongs_to :provider
  belongs_to :accredited_body, class_name: "Provider"
  belongs_to :recruitment_cycle

  validates :provider, :accredited_body, presence: true
  validates :number_of_places, numericality: true

  validate :accredited_body_is_an_accredited_body

  enum request_type: { initial: 0, repeat: 1, declined: 2 }

  def previous
    Allocation.find_by(
      provider_code: provider_code,
      accredited_body_code: accredited_body_code,
      recruitment_cycle: recruitment_cycle.previous,
    )
  end

private

  def accredited_body_is_an_accredited_body
    errors.add(:accredited_body, "must be an accredited body") unless accredited_body&.accredited_body?
  end
end
