# frozen_string_literal: true

RSpec.shared_context 'with Terraform pre-0.12', :terraform_pre_012 do
  before do
    allow(terraform).to receive(:pre_0_12?) { true }
  end
end

RSpec.shared_context 'with Terraform post-0.12', :terraform_post_012 do
  before do
    allow(terraform).to receive(:pre_0_12?) { false }
  end
end
