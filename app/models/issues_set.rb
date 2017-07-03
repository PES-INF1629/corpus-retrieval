class IssuesSet
  include Mongoid::Document
  include Mongoid::Timestamps

  class StatusDoesNotExist < StandardError; end

  STATUSES = %i[processing finished failed]
  MAX_STORED = 30

  field :query, type: String
  field :filename, type: String
  field :zip, type: BSON::Binary
  field :worker_id, type: String
  field :status, type: Integer, default: STATUSES.index(:processing)

  def self.destroy_olds!
    IssuesSet.order(:created_at.desc).offset(MAX_STORED).destroy_all
  end

  def self.status_of(status_symbol)
    inx = STATUSES.index(status_symbol)
    (inx >= 0) ? inx : (raise StatusDoesNotExist, status_symbol.inspect)
  end

  def finish!(zip)
    self.update_attributes! zip: zip, status: IssuesSet.status_of(:finished)
    IssuesSet.where(query: self.query, :id.ne => self.id).destroy_all
  end

  def zip_to_download
    zip && zip.data
  end

  def status_name
    STATUSES[self.status]
  end

  def finished?
    self.status == IssuesSet.status_of(:finished)
  end
  
  def processing?
    self.status == IssuesSet.status_of(:processing)
  end
end
