class Assignment < ApplicationRecord
  belongs_to :shift
  belongs_to :work_order
  belongs_to :work_station
end
