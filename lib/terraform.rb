# frozen_string_literal: true

require 'terraform/version_requirement'

# Wrapper for Terraform commands
class Terraform
  def fmt(paths, **flags)
    base_cmd = %w[terraform fmt] + cli_flags(flags)

    Array(paths).inject(true) do |result, path|
      cmd = base_cmd + [path]

      yield(path, cmd) if block_given?

      system(*cmd) && result # carry on failure
    end
  end

  # Find out current Terraform version
  def version
    @version ||= begin
      m = /^Terraform v(?<version>[^\s]+)/.match(`terraform version`)
      m && m[:version]
    end
  rescue Errno::ENOENT
    nil
  end

  # Checks if the version is older than 0.12
  def pre_0_12?
    VersionRequirement.new('< 0.12.0-alpha').satisfied_by?(version)
  end

  # Finds all *.tfvars files recursively in the given directory,
  # or current working directory if not specified.
  def find_tfvars_files(dir = nil, &block)
    dir = "#{dir}/" if dir && !dir.empty? && dir[-1] != '/'

    Dir.glob("#{dir}**/*.tfvars", &block)
  end

  # Returns `Array` of CLI flags for Terraform
  # E.g. `{ foo: true, bar: 'baz' }` -> `[ '-foo=true', '-bar=baz' ]`
  def cli_flags(**flags)
    flags.map { |k, v| "-#{k}=#{v}" }
  end
end
