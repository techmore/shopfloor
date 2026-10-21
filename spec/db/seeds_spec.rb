require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "creates the demo accounts with their roles (regression: roles were silently dropped)" do
    expect {
      quietly { Rails.application.load_seed }
    }.to change(User, :count).by(7)

    expect(User.find_by!(email: "admin@shopfloor.local")).to be_admin
    expect(User.find_by!(email: "scheduler@shopfloor.local")).to be_scheduler
    expect(User.find_by!(email: "viewer@shopfloor.local")).to be_viewer
    expect(User.where(role: nil)).to be_empty
  end

  it "is idempotent" do
    quietly { Rails.application.load_seed }
    expect { quietly { Rails.application.load_seed } }.not_to change(User, :count)
  end

  def quietly
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end
end
