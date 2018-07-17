class List < ApplicationRecord
  mount_uploader :location, FileUploader
  has_many :tmsrecords, dependent: :destroy

  def can_export?
    self.status == "IMPORT"
  end
end
