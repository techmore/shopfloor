require "rails_helper"

RSpec.describe WorkOrder, type: :model do
  subject { build(:work_order) }

  it { is_expected.to belong_to(:part) }
  it { is_expected.to have_many(:assignments).dependent(:destroy) }
  it { is_expected.to have_many(:weigh_sessions).dependent(:restrict_with_error) }
  it { is_expected.to define_enum_for(:status).with_values(planned: 0, in_progress: 1, completed: 2, cancelled: 3) }
  it { is_expected.to define_enum_for(:priority).with_values(low: 0, normal: 1, high: 2, urgent: 3) }
  it { is_expected.to validate_presence_of(:order_number) }
  it { is_expected.to validate_uniqueness_of(:order_number) }
  it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }

  it "has a valid factory" do
    expect(build(:work_order)).to be_valid
  end

  describe "overdue" do
    it "only counts open orders past their due date" do
      late = create(:work_order, due_date: Date.current - 1, status: :in_progress)
      done = create(:work_order, due_date: Date.current - 1, status: :completed)
      future = create(:work_order, due_date: Date.current + 1)
      expect(late).to be_overdue
      expect(done).not_to be_overdue
      expect(future).not_to be_overdue
      expect(WorkOrder.overdue).to contain_exactly(late)
      expect(WorkOrder.open).to contain_exactly(late, future)
    end
  end
end
