describe DFESubject do
  subject { DFESubject.new(subject_name) }

  context "(secondary mathematics)" do
    let(:subject_name) { "Mathematics" }

    it { should have_bursary }
    it { should have_scholarship }

    it { should eq(DFESubject.new("Mathematics")) }
  end

  context "(physical education)" do
    let(:subject_name) { "Physical education" }

    it { should_not have_bursary }
    it { should_not have_scholarship }
  end
end
