# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polist do
  it "has a version number" do
    expect(Polist::VERSION).not_to be(nil)
  end
end
