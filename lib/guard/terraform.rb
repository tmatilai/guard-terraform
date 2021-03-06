# frozen_string_literal: true

require 'guard/plugin'

require 'guard/terraform/version'
require 'terraform'

module Guard
  # Guard plugin for checking Terraform configuration style
  class Terraform < Plugin
    # Include the `VERSION` constant
    include TerraformVersion

    DEFAULT_OPTIONS = {
      all_on_start: true,   # check all files on start?

      diff:         true,   # show diffs of the changes?
      write:        false,  # fix the formatting instead of just verifying?
    }.freeze

    attr_reader :options
    attr_reader :terraform, :tf_flags

    def initialize(**options)
      super

      options = DEFAULT_OPTIONS.merge(options)

      @options = {
        all_on_start: options[:all_on_start],
      }

      # Enforce boolean values as they get passed to CLI
      @tf_flags = {
        diff:  !!options[:diff],  # rubocop:disable Style/DoubleNegation
        write: !!options[:write], # rubocop:disable Style/DoubleNegation
        check: !options[:write],
      }

      @terraform = ::Terraform.new
    end

    def start
      UI.info "#{self.class} started"
      UI.info "Terraform version: #{terraform.version}"

      raise(StandardError, 'Terraform not found') if !terraform.version

      run_all if options[:all_on_start]
    end

    def run_all
      paths = ['.']
      extra_flags = {}

      if terraform.pre_0_12?
        # Terraform v<0.12 does not check *.tfvars by default,
        # so find and check them separately
        paths += terraform.find_tfvars_files
      else
        # Terraform 0.12+ does not check recursively by default
        extra_flags[:recursive] = true
      end

      run(paths, extra_flags)
    end

    def run_on_modifications(paths)
      run(mungle_paths(paths))
    end

    alias run_on_additions run_on_modifications

    def run(paths, **extra_flags)
      print_pre_run_message(paths)

      flags = tf_flags.merge(extra_flags)

      result = terraform.fmt(paths, flags) do |_, cmd|
        UI.debug(Shellwords.join(cmd))
      end

      return if result

      notify_failure
      throw(:task_has_failed)
    end

    def print_pre_run_message(paths)
      @msg_format ||= "#{options[:write] ? 'Enforcing' : 'Inspecting'} " \
                      'Terraform formatting for %s'

      target = if paths.count > 1
                 "#{paths.count} files or dirs"
               elsif paths.first == '.'
                 'the whole project'
               else
                 paths.first
               end

      UI.info(format(@msg_format, target))
    end

    def notify_failure
      Notifier.notify(
        'Terraform format check failed',
        title: self.class.to_s,
        image: :failed
      )
    end

    # Terraform 0.12+ only supports checking directories,
    # older versions accept also files
    def mungle_paths(paths)
      return paths if terraform.pre_0_12?

      paths.map do |path|
        File.directory?(path) ? path : File.dirname(path)
      end.uniq
    end
  end
end
