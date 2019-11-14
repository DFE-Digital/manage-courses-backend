RSpec::Matchers.define :delegate_method_to_service do |method, service|
  match do |model|
    @service_spy = spy
    stub_const service, double(new: @service_spy)
    model.send(method)

    if @expected_args.present?
      expect(@service_spy).to have_received(:execute) do |actual_args|
        expect(actual_args).to eq(@expected_args)
      end
    else
      expect(@service_spy).to have_received(:execute)
    end
  end

  chain :with_arguments do |expected_args|
    @expected_args = expected_args
  end

  failure_message do |model|
    "expected #{model.class} to delegate ##{method} to #{service}"
  end
end
