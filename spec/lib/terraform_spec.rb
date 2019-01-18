# frozen_string_literal: true

require 'terraform'

RSpec.describe Terraform do
  subject(:terraform) { described_class.new }

  before do
    # Add a safeguard do that `system` would not be called accidentally
    allow(terraform).to receive(:system) do |*args|
      warn "\nERROR: Stub for system() called with: #{args.inspect}\n"
    end
  end

  describe '#fmt' do
    subject { terraform.fmt(paths, flags) }

    let(:flags) { {} }

    context 'with no paths' do
      let(:paths) { [] }

      it 'does nothing' do
        expect(terraform).not_to receive(:system)
        terraform.fmt(paths, flags)
      end

      it 'does not yield' do
        yielded = false
        terraform.fmt(paths, flags) { yielded = true }
        expect(yielded).to be false
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'with one path' do
      let(:paths) { ['foo/bar'] }

      context 'without flags' do
        let(:paths) { '.' }
        let(:flags) { {} }

        it 'invokes Terraform with the specified path' do
          expect(terraform).to receive(:system).with('terraform', 'fmt', '.') { true }

          terraform.fmt(paths, flags)
        end
      end

      context 'with flags' do
        let(:paths) { ['main.tf'] }
        let(:flags) { { debug: true, write: false } }

        it 'invokes Terraform with the specified flags' do
          expect(terraform).to receive(:system)
            .with('terraform', 'fmt', '-debug=true', '-write=false', 'main.tf') { true }

          terraform.fmt(paths, flags)
        end
      end

      it 'returns true' do
        allow(terraform).to receive(:system) { true }
        is_expected.to be_truthy
      end

      context 'with failure' do
        it 'returns false' do
          allow(terraform).to receive(:system) { false }
          is_expected.to be_falsey
        end
      end

      context 'when Terraform is not found' do
        it 'returns false' do
          allow(terraform).to receive(:system) { nil }
          is_expected.to be_falsey
        end
      end
    end

    context 'with multiple path' do
      let(:paths) { %w[foo/bar some/baz.tf some/thing.tfvars] }

      context 'without flags' do
        let(:paths) { %w[first second] }
        let(:flags) { {} }

        it 'invokes Terraform with the specified paths' do
          expect(terraform).to(receive(:system).with('terraform', 'fmt', 'first').ordered) { true }
          expect(terraform).to(receive(:system).with('terraform', 'fmt', 'second').ordered) { true }

          terraform.fmt(paths, flags)
        end
      end

      context 'with flags' do
        let(:flags) { { foo: 'bar', x: 42 } }

        it 'invokes Terraform with the specified flags' do
          expect(terraform).to(receive(:system)
            .with('terraform', 'fmt', '-foo=bar', '-x=42', anything)
            .exactly(paths.length).times) { true }

          terraform.fmt(paths, flags)
        end
      end

      it 'returns true' do
        allow(terraform).to receive(:system) { true }
        is_expected.to be_truthy
      end

      context 'with failure' do
        before do
          allow(terraform).to receive(:system) { true }
          # Fail the second call
          allow(terraform).to receive(:system).with('terraform', 'fmt', 'some/baz.tf') { false }
        end

        it 'runs all' do
          terraform.fmt(paths, flags)
          expect(terraform).to have_received(:system).exactly(paths.length).times
        end

        it 'returns false' do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#version' do
    subject { terraform.version }

    let(:terraform_version) { '1.2.3' }

    context 'when Terraform is found' do
      before do
        expect(terraform).to receive(:`)
          .with(/^terraform version$/)
          .and_return("Terraform v#{terraform_version}\n\n")
      end

      it 'returns the current Terraform version number' do
        expect(terraform.version).to eq('1.2.3')
      end
    end

    context 'when Terraform is not found' do
      before do
        allow(terraform).to receive(:`).and_raise(Errno::ENOENT)
      end

      it { is_expected.to be_nil }
    end

    context 'when `terraform version` returns rubbish' do
      before do
        expect(terraform).to receive(:`) { 'Hello, world!' }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#pre_0_12?' do
    subject { terraform.pre_0_12? }

    before do
      expect(terraform).to receive(:`)
        .with(/^terraform version$/)
        .and_return("Terraform v#{terraform_version}\n\n")
    end

    context 'with older version' do
      let(:terraform_version) { '0.11.11' }

      it { is_expected.to be_truthy }
    end

    context 'with slightly newer version' do
      let(:terraform_version) { '0.12.0' }

      it { is_expected.to be_falsey }
    end

    context 'with much newer version' do
      let(:terraform_version) { '1.5.3' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#find_tfvars_files' do
    let(:fixtures_root) { File.expand_path('../fixtures', __dir__) }
    let(:test_root) { File.join(fixtures_root, 'terraform') }
    let(:test_files) { %w[foo/terraform.tfvars foo/bar/x.tfvars foo/bar/y.tfvars] }
    let(:expected_paths) { test_files }

    before do
      @old_dir = Dir.pwd
      Dir.chdir(test_root) if test_root
    end

    after do
      Dir.chdir(@old_dir) if @old_dir
    end

    context 'without dir' do
      subject { terraform.find_tfvars_files }

      context 'with block' do
        it 'yields the relative paths' do
          paths = []
          terraform.find_tfvars_files { |path| paths << path }

          expect(paths).to match_array(expected_paths)
        end
      end

      context 'without block' do
        it 'returns the relative paths' do
          is_expected.to match_array(expected_paths)
        end
      end
    end

    context 'with relative path' do
      subject { terraform.find_tfvars_files(dir) }

      let(:test_root) { fixtures_root }
      let(:dir) { 'terraform' }
      let(:expected_paths) { test_files.map { |path| "#{dir}/#{path}" } }

      context 'with block' do
        it 'yields the relative paths' do
          paths = []
          terraform.find_tfvars_files(dir) { |path| paths << path }

          expect(paths).to match_array(expected_paths)
        end
      end

      context 'without block' do
        it 'returns the relative paths' do
          is_expected.to match_array(expected_paths)
        end
      end
    end

    context 'with absolute path' do
      subject { terraform.find_tfvars_files(dir) }

      let(:test_root) { nil }
      let(:dir) { File.join(fixtures_root, 'terraform') }
      let(:expected_paths) { test_files.map { |path| "#{dir}/#{path}" } }

      context 'with block' do
        it 'yields the absolute paths' do
          paths = []
          terraform.find_tfvars_files(dir) { |path| paths << path }

          expect(paths).to match_array(expected_paths)
        end
      end

      context 'without block' do
        it 'returns the absolute paths' do
          is_expected.to match_array(expected_paths)
        end
      end
    end
  end
end
