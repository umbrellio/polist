# frozen_string_literal: true

class User
  include Polist::Builder

  builds do |role|
    case role
    when /admin/
      Admin
    end
  end

  attr_accessor :role

  def initialize(role)
    self.role = role
  end
end

class Admin < User
  builds do |role|
    role == "super_admin" ? SuperAdmin : Admin
  end

  class SuperAdmin < self
    def super?
      true
    end
  end

  def super?
    false
  end
end

RSpec.describe Polist::Builder do
  let(:user) { User.build(role) }

  context "user role" do
    let(:role) { "user" }

    it "builds user" do
      expect(user.class).to eq(User)
      expect(user.role).to eq("user")
    end
  end

  context "admin role" do
    let(:role) { "admin" }

    it "builds admin" do
      expect(user.class).to eq(Admin)
      expect(user.role).to eq("admin")
      expect(user.super?).to eq(false)
    end
  end

  context "super_admin role" do
    let(:role) { "super_admin" }

    it "builds super_admin" do
      expect(user.class).to eq(Admin::SuperAdmin)
      expect(user.role).to eq("super_admin")
      expect(user.super?).to eq(true)
    end
  end
end
