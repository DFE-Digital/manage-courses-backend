describe DFESubject do
  subject { DFESubject.new(subject_name) }

  context "(secondary mathematics)" do
    let(:subject_name) { "Mathematics" }

    it { should have_bursary }
    it { should have_scholarship }
    it { should have_early_career_payments }
    its(:bursary_amount) { should eq(20_000) }
    its(:scholarship_amount) { should eq(22_000) }
    its(:total_bursary_and_early_career_payments_amount) { should eq(30_000) }

    it { should eq(DFESubject.new("Mathematics")) }
  end

  context "(physical education)" do
    let(:subject_name) { "Physical education" }

    it { should_not have_bursary }
    it { should_not have_scholarship }
    it { should_not have_early_career_payments }
    its(:bursary_amount) { should eq(0) }
    its(:scholarship_amount) { should eq(0) }
    its(:total_bursary_and_early_career_payments_amount) { should eq(0) }
  end
end
