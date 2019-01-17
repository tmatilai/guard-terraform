# frozen_string_literal: true

# Monkey patch Guard classes

require 'guard/plugin'

module Guard
  class Plugin
    def initialize(options = {})
      # Do nothing
    end
  end

  class Notifier; end

  module UI; end
end

RSpec.shared_context 'Silence Guard UI and Notifier', :silence_guard_ui do
  before do
    allow(Guard::UI).to receive(:debug)
    allow(Guard::UI).to receive(:info)
    allow(Guard::UI).to receive(:warning)
    allow(Guard::UI).to receive(:error)
    allow(Guard::UI).to receive(:deprecation)

    allow(Guard::Notifier).to receive(:notify)
  end
end
