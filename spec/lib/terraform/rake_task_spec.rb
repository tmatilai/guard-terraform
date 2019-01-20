# frozen_string_literal: true

require 'support/terraform_versions'

require 'terraform/rake_task'

RSpec.describe Terraform::RakeTask do
  subject(:task) { described_class.new }

  let(:terraform) { instance_double(::Terraform) }
  let(:fmt_result) { true }
  let(:tfvars_files) { %w[foo.tfvars bar/baz.tfvars] }

  before do
    Rake::Task.clear

    allow(::Terraform).to receive(:new) { terraform }
    allow(terraform).to receive(:find_tfvars_files) { tfvars_files }
  end

  after do
    Rake::Task.clear
  end

  describe 'defining tasks' do
    context 'with default name' do
      it 'creates a task' do
        described_class.new

        expect(Rake::Task.task_defined?(:terraform)).to be true
      end
    end

    context 'with specified name' do
      it 'creates a task' do
        described_class.new(:something)

        expect(Rake::Task.task_defined?(:something)).to be true
      end
    end
  end

  describe 'running the task' do
    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    after do
      $stdout = STDOUT
      $stderr = STDERR
    end

    context 'with pre-0.12 Terraform version', :terraform_pre_012 do
      context 'with defaults' do
        before do
          described_class.new
        end

        it 'calls Terraform with root dir and tfvars files' do
          paths = ['.'] + tfvars_files
          expect(terraform).to receive(:fmt).with(paths, anything) { true }

          Rake::Task[:terraform].execute
        end

        it 'calls Terraform with default flags' do
          flags = { check: true, diff: true, write: false }
          expect(terraform).to receive(:fmt).with(anything, flags) { true }

          Rake::Task[:terraform].execute
        end

        context 'on failure' do
          before do
            allow(terraform).to receive(:fmt) { false }
          end

          it 'exits with error code' do
            expect { Rake::Task[:terraform].execute }.to raise_error(SystemExit)
            expect($stderr.string).to match(/Terraform .* failed/)
          end
        end
      end

      context 'with specified options' do
        context 'with write enabled' do
          it 'also disables check' do
            described_class.new do |task|
              task.project_root = '/somewhere/else'
              task.write = true
            end

            expect(terraform).to receive(:fmt).with(
              array_including('/somewhere/else'),
              hash_including(write: true, check: false)
            ) { true }

            Rake::Task[:terraform].execute
          end
        end

        context 'with fail_on_error disabled' do
          context 'on failure' do
            before do
              described_class.new do |task|
                task.fail_on_error = false
              end

              allow(terraform).to receive(:fmt) { false }
            end

            it 'does not exit with error code on error' do
              expect { Rake::Task[:terraform].execute }.not_to raise_error
            end

            it 'prints out error message' do
              expect { Rake::Task[:terraform].execute }.to output(/Terraform .* failed/).to_stderr
            end
          end
        end
      end
    end

    context 'with 0.12+ Terraform version', :terraform_post_012 do
      context 'with defaults' do
        before do
          described_class.new
        end

        it 'calls Terraform with only root dir' do
          expect(terraform).to receive(:fmt).with(['.'], anything) { true }

          Rake::Task[:terraform].execute
        end

        it 'calls Terraform with default flags' do
          flags = { check: true, diff: true, write: false, recursive: true }
          expect(terraform).to receive(:fmt).with(anything, flags) { true }

          Rake::Task[:terraform].execute
        end

        context 'on failure' do
          before do
            allow(terraform).to receive(:fmt) { false }
          end

          it 'exits with error code' do
            expect { Rake::Task[:terraform].execute }.to raise_error(SystemExit)
            expect($stderr.string).to match(/Terraform .* failed/)
          end
        end
      end

      context 'with specified options' do
        context 'with write enabled' do
          it 'also disables check' do
            described_class.new do |task|
              task.project_root = '/somewhere/else'
              task.write = true
            end

            expect(terraform).to receive(:fmt).with(
              array_including('/somewhere/else'),
              hash_including(write: true, check: false)
            ) { true }

            Rake::Task[:terraform].execute
          end
        end

        context 'with fail_on_error disabled' do
          context 'on failure' do
            before do
              described_class.new do |task|
                task.fail_on_error = false
              end

              allow(terraform).to receive(:fmt) { false }
            end

            it 'does not exit with error code on error' do
              expect { Rake::Task[:terraform].execute }.not_to raise_error
            end

            it 'does not print out error message' do
              expect { Rake::Task[:terraform].execute }.to output(/Terraform .* failed/).to_stderr
            end
          end
        end
      end
    end
  end
end
