require 'mcb_helper'

describe 'mcb users grant_access_to_provider' do
  def grant_access_to_provider(provider_code, commands)
    stderr = ""
    output = with_stubbed_stdout(stdin: commands, stderr: stderr) do
      cmd.run([provider_code])
    end
    [output, stderr]
  end

  let(:lib_dir) { "#{Rails.root}/lib" }
  let(:cmd) do
    Cri::Command.load_file(
      "#{lib_dir}/mcb/commands/users/grant_access_to_provider.rb"
    )
  end
  let(:organisation) { create(:organisation) }
  let(:provider) { create(:provider, organisations: [organisation]) }
  let(:output) { grant_access_to_provider(provider.provider_code, input_commands.join("\n") + "\n").first }

  context 'when the user exists and already has access to the provider' do
    let(:input_commands) { [user.email] }
    let(:user) { create(:user, organisations: [organisation]) }

    it 'informs the support agen that it is not going to do anything' do
      expect(output).to include("#{user} already belongs to #{organisation.name}")
    end
  end

  context 'when the user does not exist' do
    let(:input_commands) { %w[jsmith@acme.org Jane Smith y y] }

    before do
      output
    end

    it 'creates the user' do
      expect(User.find_by(first_name: 'Jane', last_name: 'Smith', email: 'jsmith@acme.org')).to be_present
    end

    it 'grants organisation membership to that user' do
      user = User.find_by!(first_name: 'Jane', last_name: 'Smith', email: 'jsmith@acme.org')
      expect(user.organisations).to eq([organisation])
    end

    it 'confirms user creation and organisation membership' do
      expect(output).to include("jsmith@acme.org appears to be a new user")
      expect(output).to include("You're about to give Jane Smith <jsmith@acme.org> access to #{organisation.name}.")
    end
  end

  context 'when the user details are invalid' do
    let(:input_commands) { %w[jsmith Jane Smith] }

    before do
      output
    end

    it 'does not create the user' do
      expect(User.count).to eq(0)
    end

    it 'displays the validation errors' do
      expect(output).to include("Email must contain @")
    end
  end

  context 'when the user exists but is not a member of the org' do
    let(:user) { create(:user, organisations: []) }
    let(:input_commands) { [user.email, 'y'] }

    before do
      output
    end

    it 'grants organisation membership to that user' do
      expect(user.reload.organisations).to eq([organisation])
    end

    it 'confirms user creation and organisation membership' do
      expect(output).to include("You're about to give #{user} access to #{organisation.name}.")
    end
  end
end
