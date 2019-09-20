# == Schema Information
#
# Table name: ucas_subject
#
#  id           :bigint           not null, primary key
#  type         :text
#  subject_code :text
#  subject_name :text
#

require 'rails_helper'

RSpec.describe UCASSubject, type: :model do
  subject { find_or_create(:ucas_subject, :mathematics) }

  it { should have_many(:courses).through(:course_ucas_subjects) }
  its(:to_s) { should eq('Mathematics') }
end
