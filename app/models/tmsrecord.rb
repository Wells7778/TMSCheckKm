class Tmsrecord < ApplicationRecord
  belongs_to :list
  validates_uniqueness_of :number, :scope => :list_id
end
