# frozen_string_literal: true

class Point
  include Polist::Struct

  struct :x, :y
end

RSpec.describe Polist::Struct do
  specify "basic usage" do
    a = Point.new(15, 25)
    expect(a.x).to eq(15)
    expect(a.y).to eq(25)
  end

  context "too many arguments" do
    it "raises exception" do
      expect { Point.new(15, 25, 35) }.to raise_error(ArgumentError, "struct size differs")
    end
  end

  context "only 1 argument" do
    it "defaults to nil" do
      a = Point.new(15)
      expect(a.x).to eq(15)
      expect(a.y).to eq(nil)
    end
  end
end
