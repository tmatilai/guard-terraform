# frozen_string_literal: true

require 'support/guard_mocks'
require 'support/terraform_versions'

require 'guard/terraform'

RSpec.describe Guard::Terraform, :silence_guard_ui do
  subject(:plugin) { described_class.new(options) }

  let(:terraform) { instance_double(::Terraform) }
  let(:options) { {} }

  before do
    allow(::Terraform).to receive(:new) { terraform }
  end

  it 'has a version number' do
    expect(Guard::Terraform::VERSION).not_to be nil
  end

  describe '#start' do
    let(:tf_version) { '1.3.5' }

    before do
      allow(terraform).to receive(:version) { tf_version }
    end

    context 'by default' do
      it 'calls #run_all' do
        expect(plugin).to receive(:run_all)
        plugin.start
      end
    end

    context 'when :all_on_start option is true' do
      let(:options) { { all_on_start: true } }

      it 'calls #run_all' do
        expect(plugin).to receive(:run_all)
        plugin.start
      end
    end

    context 'when :all_on_start option is false' do
      let(:options) { { all_on_start: false } }

      it 'does not call #run_all' do
        expect(plugin).not_to receive(:run_all)
        plugin.start
      end
    end

    context 'when Terraform is not found' do
      let(:tf_version) { nil }

      it 'raises an error' do
        expect(plugin).not_to receive(:run_all)
        expect { plugin.start }.to raise_error(StandardError)
      end
    end
  end

  shared_examples 'options_to_flags' do |**extra_flags|
    context 'without options' do
      let(:flags) do
        { diff: true, write: false, check: true }.merge(extra_flags)
      end

      it 'calls Terraform with default options' do
        expect(terraform).to receive(:fmt).with(anything, flags) { true }
        subject
      end
    end

    context 'with -write=true' do
      let(:options) { { write: true } }
      let(:flags) { { write: true, check: false }.merge(extra_flags) }

      it 'calls Terraform with it and disables -check' do
        expect(terraform).to receive(:fmt).with(anything, hash_including(flags)) { true }
        subject
      end
    end

    context 'with -write=false' do
      let(:options) { { write: false } }
      let(:flags) { { write: false, check: true }.merge(extra_flags) }

      it 'calls Terraform with it and enables -check' do
        expect(terraform).to receive(:fmt).with(anything, hash_including(flags)) { true }
        subject
      end
    end

    context 'with -diff=true option' do
      let(:options) { { diff: true } }
      let(:flags) { { diff: true }.merge(extra_flags) }

      it 'calls Terraform with it' do
        expect(terraform).to receive(:fmt).with(anything, hash_including(flags)) { true }
        subject
      end
    end

    context 'with -diff=false option' do
      let(:options) { { diff: false } }
      let(:flags) { { diff: false }.merge(extra_flags) }

      it 'calls Terraform with it' do
        expect(terraform).to receive(:fmt).with(anything, hash_including(flags)) { true }
        subject
      end
    end
  end

  describe '#run_all' do
    subject { plugin.run_all }

    context 'with pre-0.12 Terraform version', :terraform_pre_012 do
      let(:tfvars_files) { %w[foo.tfvars foo/baz.tfvars a/b/c.tfvars] }

      before do
        allow(terraform).to receive(:find_tfvars_files).with(no_args) { tfvars_files }
      end

      include_examples 'options_to_flags'

      it 'calls Terraform with root dir and tfvars files' do
        paths = ['.'] + tfvars_files
        expect(terraform).to receive(:fmt).with(paths, anything) { true }

        plugin.run_all
      end

      it 'calls Terraform without -recursive flag' do
        expect(terraform).to receive(:fmt)
          .with(anything, hash_excluding(:recursive)) { true }

        plugin.run_all
      end

      it 'throws :task_has_failed if Terraform returns false' do
        expect(terraform).to receive(:fmt) { false }
        expect(plugin).to receive(:throw).with(:task_has_failed)

        plugin.run_all
      end
    end

    context 'with 0.12+ Terraform version', :terraform_post_012 do
      include_examples 'options_to_flags', :run_all, recursive: true

      it 'calls Terraform with root dir' do
        expect(terraform).to receive(:fmt).with(['.'], anything) { true }

        plugin.run_all
      end

      it 'throws :task_has_failed if terraform return false' do
        expect(terraform).to receive(:fmt) { false }
        expect(plugin).to receive(:throw).with(:task_has_failed)

        plugin.run_all
      end
    end
  end

  shared_examples 'run_on_modifications' do
    let(:paths) { %w[foo/bar.tf foo/baz.tf some/dir a/b/c.tfvars] }

    before do
      allow(File).to receive(:directory?) { false }
      allow(File).to receive(:directory?).with('some/dir') { true }
    end

    context 'with pre-0.12 Terraform version', :terraform_pre_012 do
      include_examples 'options_to_flags'

      it 'calls Terraform with unmodified paths' do
        expect(terraform).to receive(:fmt).with(paths.dup, anything) { true }
        subject
      end

      it 'throws :task_has_failed if terraform return false' do
        expect(terraform).to receive(:fmt) { false }
        expect(plugin).to receive(:throw).with(:task_has_failed)
        subject
      end
    end

    context 'with 0.12+ Terraform version', :terraform_post_012 do
      include_examples 'options_to_flags'

      it 'calls Terraform with directory paths' do
        expect(terraform).to receive(:fmt)
          .with(%w[foo some/dir a/b], anything) { true }
        subject
      end

      it 'throws :task_has_failed if terraform return false' do
        expect(terraform).to receive(:fmt) { false }
        expect(plugin).to receive(:throw).with(:task_has_failed)
        subject
      end
    end
  end

  describe '#run_on_modifications' do
    subject { plugin.run_on_modifications(paths) }

    include_examples 'run_on_modifications', :run_on_modifications
  end

  describe '#run_on_additions' do
    subject { plugin.run_on_additions(paths) }

    it_behaves_like 'run_on_modifications', :run_on_additions
  end
end
