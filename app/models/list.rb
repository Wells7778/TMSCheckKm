class List < ApplicationRecord
  mount_uploader :location, FileUploader
  has_many :tmsrecords
end
