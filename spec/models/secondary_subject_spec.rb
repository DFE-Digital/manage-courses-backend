# == Schema Information
#
# Table name: subject
#
#  created_at   :datetime
#  id           :bigint           not null, primary key
#  subject_code :text
#  subject_name :text
#  type         :text
#  updated_at   :datetime
#
# Indexes
#
#  index_subject_on_subject_name  (subject_name)
#

require "rails_helper"

describe SecondarySubject, type: :model do
  describe "#modern_languages" do
    let!(:modern_languages) do
      find_or_create(:secondary_subject, :modern_languages)
    end

    it "returns the modern language subject" do
      expect(SecondarySubject.modern_languages).to eq(modern_languages)
    end

    it "memoises the subject object" do
      SecondarySubject.modern_languages

      allow(SecondarySubject).to receive(:find_by)

      expect(SecondarySubject.modern_languages).to eq(modern_languages)
      expect(SecondarySubject).not_to have_received(:find_by)
    end
  end
end
