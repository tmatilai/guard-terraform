# frozen_string_literal: true

class Terraform
  # Helper class for checking if versions match requirements
  class VersionRequirement
    attr_reader :requirement

    def initialize(requirement)
      @requirement = requirement && Gem::Requirement.new(*requirement)
    end

    def satisfied_by?(version)
      !requirement || requirement.satisfied_by?(Gem::Version.new(version))
    end

    def to_s
      requirement.to_s
    end
  end
end
