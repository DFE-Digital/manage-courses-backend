require 'spec_helper'
require 'mcb_helper'

describe 'mcb apiv2 token generate' do
  describe 'generating a token with a secret' do
    it 'returns a plain-text JSON string' do
      result = with_stubbed_stdout do
        $mcb.run(%w[apiv2 token generate -S sekret user@local])
      end

      payload = { email: 'user@local' }.to_json
      expect(result.chomp).to eq(
        JWT.encode(payload, 'sekret', 'HS256')
      )
    end
  end
end
