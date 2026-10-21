require "rails_helper"

RSpec.describe "Factories" do
  it "all build valid records" do
    FactoryBot.lint traits: true
  end
end
