# == Schema Information
#
# Table name: recruitment_cycle
#
#  id                     :bigint           not null, primary key
#  year                   :string
#  application_start_date :date
#  application_end_date   :date
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'rails_helper'

describe RecruitmentCycle, type: :model do
  subject { RecruitmentCycle.find_by(year: "2019") }

  its(:to_s) { should eq("2019/20") }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it { is_expected.to validate_presence_of(:year) }

  describe 'associations' do
    it { should have_many(:courses).through(:providers) }
    it { should have_many(:sites).through(:providers) }
  end

  describe "current?" do
    let(:current_cycle) { subject }
    let(:second_cycle) { create(:recruitment_cycle, year: "2020") }

    it "should return true when it's the current cycle" do
      expect(current_cycle.current?).to be(true)
    end

    it "should return true false it's not the current cycle" do
      expect(second_cycle.current?).to be(false)
    end
  end

  describe "#next" do
    let(:current_cycle) { subject }
    let!(:second_cycle) { create(:recruitment_cycle, year: "2020") }
    let!(:third_cycle) { create(:recruitment_cycle, year: "2021") }

    its(:next) { should eq(second_cycle) }

    it "is nil for the newest cycle" do
      expect(third_cycle.next).to be_nil
    end

    it "returns the next cycle along when there is one" do
      expect(second_cycle.next).to eq(third_cycle)
    end
  end
end
