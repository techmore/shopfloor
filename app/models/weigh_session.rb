class WeighSession < ApplicationRecord
  belongs_to :work_order
  belongs_to :assignment
  belongs_to :part
  belongs_to :weigh_station
end
