# == Schema Information
#
# Table name: provider_ucas_preference
#
#  id                      :bigint(8)        not null, primary key
#  provider_id             :integer          not null
#  type_of_gt12            :text
#  send_application_alerts :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

require "rails_helper"

describe ProviderUCASPreference, type: :model do
  it { should belong_to(:provider) }

  describe 'type_of_gt12' do
    it 'is an enum' do
      expect(subject)
        .to define_enum_for(:type_of_gt12)
              .backed_by_column_of_type(:text)
              .with_values(
                coming_or_not: 'Coming or Not (GT12B)',
                coming_enrol: 'Coming / Enrol (GT12E)',
                not_coming: 'Not coming (GT12N)',
                no_response: 'No response (GT12)',
              )
              .with_prefix('type_of_gt12')
    end
  end

  describe 'send_application_alerts' do
    it 'is an enum' do
      expect(subject)
        .to define_enum_for(:send_application_alerts)
              .backed_by_column_of_type(:text)
              .with_values(
                all: 'Yes, required',
                none: 'No, not required',
                my_programmes: 'Yes - only my programmes',
                accredited_programmes: 'Yes - for accredited programmes only',
              )
              .with_prefix('send_application_alerts_for')
    end
  end
end
