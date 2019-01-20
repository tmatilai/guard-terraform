#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'

require 'terraform'

class Terraform
  # Provides a method to define a Rake task that
  # checks and optionally fixes Terraform configuration format
  class RakeTask < Rake::TaskLib
    # Name of task (default: `:terraform`)
    attr_accessor :name

    # Path to the project root (default: `.`)
    attr_accessor :project_root

    # Show diffs of the changes? (default: `true`)
    attr_accessor :diff

    # Fix the formatting instead of just verifying? (default: `false`)
    attr_accessor :write

    # Whether or not to fail Rake when an error occurs.
    # If `write` is disabled, this include formatting issues.
    attr_accessor :fail_on_error

    # Use verbose output. If this is set to true, the task will print the
    # executed commands. Defaults to `true`.
    attr_accessor :verbose

    def initialize(*args, &task_block)
      @name = args.shift || :terraform

      @project_root = '.'

      @diff  = true
      @write = false

      @fail_on_error = true
      @verbose       = true

      define(args, &task_block)
    end

    def terraform
      @terraform ||= Terraform.new
    end

    def define(args, &task_block)
      desc('Check Terraform file formatting') if !Rake.application.last_description

      task(name, *args) do |_, task_args|
        RakeFileUtils.verbose(verbose) do
          yield(*[self, task_args].slice(0, task_block.arity)) if block_given?
          run_task
        end
      end
    end

    def run_task
      rake_output_message("#{write ? 'Auto-correcting' : 'Inspecting'}" \
                          " Terraform formatting for #{project_root}")

      return if terraform.fmt(paths, tf_flags, &print_commands_proc)

      warn('Terraform file formatting check failed')
      exit 1 if fail_on_error
    end

    def paths
      paths = [project_root]
      paths += terraform.find_tfvars_files if terraform.pre_0_12?
      paths
    end

    def tf_flags
      {}.tap do |flags|
        flags[:diff]  = !!diff  # rubocop:disable Style/DoubleNegation
        flags[:write] = !!write # rubocop:disable Style/DoubleNegation
        flags[:check] = !write
        flags[:recursive] = true if !terraform.pre_0_12?
      end
    end

    def print_commands_proc
      return if !verbose

      proc { |_, cmd| rake_output_message(cmd.join(' ')) }
    end
  end
end
