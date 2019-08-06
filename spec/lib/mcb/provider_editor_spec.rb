require 'mcb_helper'

describe MCB::ProviderEditor do
  def run_editor(*input_cmds)
    stderr = nil
    output = with_stubbed_stdout(stdin: input_cmds.join("\n"), stderr: stderr) do
      subject.run
    end
    [output, stderr]
  end

  let(:provider_code) { 'X12' }
  let(:email) { 'user@education.gov.uk' }
  let(:provider) {
    create(:provider,
           provider_code: provider_code,
           provider_name: 'Original name')
  }

  subject { described_class.new(provider: provider, requester: requester) }

  context 'when an authorised user' do
    let!(:requester) { create(:user, email: email, organisations: provider.organisations) }

    describe 'runs the editor' do
      it 'updates the provider name' do
        expect { run_editor("edit provider name", "ACME SCITT", "exit") }
          .to change { provider.reload.provider_name }
          .from("Original name").to("ACME SCITT")
      end

      describe "(course editing)" do
        let!(:courses) { create(:course, course_code: 'A01X', name: 'Biology', provider: provider) }
        let!(:course2) { create(:course, course_code: 'A02X', name: 'History', provider: provider) }
        let!(:course3) { create(:course, course_code: 'A03X', name: 'Economics', provider: provider) }

        it 'lists the courses for the given provider' do
          output, = run_editor("edit courses", "continue", "exit")
          expect(output).to include("[ ] Biology (A01X)", "[ ] History (A02X)", "[ ] Economics (A03X)")
        end

        it 'invokes course editing on the selected courses' do
          allow($mcb).to receive(:run)

          run_editor(
            "edit courses", # choose the option
            "[ ] Biology (A01X)", # pick the first course
            "[ ] Economics (A03X)", # pick the second course
            "continue", # finish selecting courses
            "exit" # from the command
          )

          expect($mcb).to have_received(:run).with(%w[courses edit X12 A01X A03X])
        end

        it 'invokes course editing on courses selected by their course code' do
          allow($mcb).to receive(:run)

          run_editor(
            "edit courses", # choose the option
            "A01X", # pick the first course
            "A03X", # pick the second course
            "continue", # finish selecting courses
            "exit" # from the command
          )

          expect($mcb).to have_received(:run).with(%w[courses edit X12 A01X A03X])
        end

        it 'allows to easily select all courses' do
          allow($mcb).to receive(:run)

          run_editor("edit courses", "select all", "continue", "exit")

          expect($mcb).to have_received(:run).with(%w[courses edit X12 A01X A02X A03X])
        end

        context "(run against an Azure environment)" do
          let(:environment) { 'qa' }
          subject { described_class.new(provider: provider, requester: requester, environment: environment) }

          it 'invokes course editing in the environment that the "providers edit" command was invoked' do
            allow($mcb).to receive(:run)

            run_editor("edit courses", "[ ] Biology (A01X)", "continue", "exit")

            expect($mcb).to have_received(:run).with(%w[courses edit X12 A01X -E qa])
          end
        end
      end

      it 'does nothing upon an immediate exit' do
        expect { run_editor("exit") }.to_not change { provider.reload.provider_name }.
          from("Original name")
      end
    end

    describe 'runs the provider creation wizard' do
      def run_new_provider_wizard(*input_cmds)
        stderr = nil
        output = with_stubbed_stdout(stdin: input_cmds.join("\n"), stderr: stderr) do
          subject.new_provider_wizard
        end
        [output, stderr]
      end
      let(:provider) { RecruitmentCycle.current_recruitment_cycle.providers.build }

      let(:desired_attributes) {
        {
          name: "ACME SCITT",
          code: 'X01',
          type: 'scitt',
          first_location_name: "ACME Primary School",
          address1: '123 Acme Lane',
          address2: '',
          town_or_city: 'Acmeton',
          county: '',
          postcode: 'SW13 9AA',
          region_code: 'london',
          contact_name: 'Jane Smith',
          email: 'jsmith@acme-scitt.org.uk',
          telephone: "0123456",
          organisation_name: 'ACME SCITT',
        }
      }

      let(:valid_answers) {
        [
          desired_attributes[:name],
          desired_attributes[:code],
          desired_attributes[:type],
          desired_attributes[:contact_name],
          desired_attributes[:email],
          desired_attributes[:telephone],
          desired_attributes[:first_location_name],
          desired_attributes[:address1],
          desired_attributes[:address2],
          desired_attributes[:town_or_city],
          desired_attributes[:county],
          desired_attributes[:postcode],
          desired_attributes[:region_code],
        ]
      }

      let(:expected_provider_attributes) {
        {
          "provider_name" => desired_attributes[:name],
          "provider_code" => desired_attributes[:code],
          "provider_type" => desired_attributes[:type],
          "contact_name" => desired_attributes[:contact_name],
          "email" => desired_attributes[:email],
          "telephone" => desired_attributes[:telephone],
          "address1" => desired_attributes[:address1],
          "address2" => desired_attributes[:address2],
          "address3" => desired_attributes[:town_or_city],
          "address4" => desired_attributes[:county],
          "postcode" => desired_attributes[:postcode],
          "region_code" => desired_attributes[:region_code],
          "scitt" => 'Y',
          "accrediting_provider" => "accredited_body",
        }
      }

      context "when adding a new provider into a completely new organisation" do
        before do
          @output, = run_new_provider_wizard(
            *valid_answers,
            # adding the provider into a new organisation
            desired_attributes[:organisation_name],
            "y" # confirm creation of a new org
          )
        end

        let(:created_provider) { RecruitmentCycle.current_recruitment_cycle.providers.find_by!(provider_code: desired_attributes[:code]) }

        it "creates a new provider with the passed parameters" do
          expect(@output).to include("New provider has been created")

          expect(created_provider.attributes).to include(expected_provider_attributes)

          expect(created_provider.changed_at).to be_present
          expect(created_provider.scheme_member).to eq('Y')
          expect(created_provider.year_code).to eq(RecruitmentCycle.current_recruitment_cycle.year)
        end

        it "creates a new organisation with the passed parameters" do
          expect(created_provider.organisations.count).to eq(1)
          expect(created_provider.organisation.name).to eq(desired_attributes[:organisation_name])
        end

        it "creates the first training location with the passed parameters" do
          expect(created_provider.sites.count).to eq(1)

          site = created_provider.sites.first
          expect(site.address1).to eq(desired_attributes[:address1])
          expect(site.address2).to eq(desired_attributes[:address2])
          expect(site.address3).to eq(desired_attributes[:town_or_city])
          expect(site.address4).to eq(desired_attributes[:county])
          expect(site.postcode).to eq(desired_attributes[:postcode])
          expect(site.region_code).to eq(desired_attributes[:region_code])
        end
      end

      context "when adding a new provider into an existing organisation" do
        let!(:existing_organisation) { create(:organisation, name: desired_attributes[:organisation_name]) }

        it "creates a new provider into the existing organisation with the passed parameters" do
          output, = run_new_provider_wizard(
            *valid_answers,
            desired_attributes[:organisation_name], # adding the provider into an existing organisation
          )

          expect(output).to include("New provider has been created")

          provider = RecruitmentCycle.current_recruitment_cycle.providers.find_by!(provider_code: desired_attributes[:code])
          expect(provider.organisation).to eq(existing_organisation)

          # no other orgs should have been created
          expect(Organisation.count).to eq(1)
        end

        it "creates a new provider into the existing organisation, even if the user makes and then corrects a typo in the org name" do
          output, = run_new_provider_wizard(
            *valid_answers,
            "ACCCCME SCITT", # mistyped organisation name
            "no", # don't create the mistyped org
            desired_attributes[:organisation_name], # try typing in the org name again
          )

          expect(output).to include("New provider has been created")

          provider = RecruitmentCycle.current_recruitment_cycle.providers.find_by!(provider_code: desired_attributes[:code])
          expect(provider.organisation).to eq(existing_organisation)

          # no other orgs should have been created
          expect(Organisation.count).to eq(1)
        end
      end

      context "when there are later recruitment cycles after the one that's been added to" do
        let!(:next_recruitment_cycle) { create :recruitment_cycle, :next }
        let!(:one_after_next_recruitment_cycle) { create :recruitment_cycle, year: next_recruitment_cycle.year.to_i + 1 }

        it "clones the provider into all subsequent recruitment cycles" do
          run_new_provider_wizard(
            *valid_answers,
            desired_attributes[:organisation_name],
            "yes"
          )

          expect(next_recruitment_cycle.providers.count).to eq(1)
          expect(next_recruitment_cycle.providers.first.attributes).to include(expected_provider_attributes)

          expect(one_after_next_recruitment_cycle.providers.count).to eq(1)
          expect(one_after_next_recruitment_cycle.providers.first.attributes).to include(expected_provider_attributes)
        end
      end
    end
  end

  context 'for an unauthorised user' do
    let!(:requester) { create(:user, email: email, organisations: []) }

    it 'raises an error' do
      expect { subject }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
