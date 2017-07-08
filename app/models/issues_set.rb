class IssuesSet
  include Mongoid::Document
  include Mongoid::Timestamps

  class StatusDoesNotExist < StandardError; end

  STATUSES = %i[processing finished failed] # zip file being processed's possible statuses
  MAX_STORED = 30

  field :query, type: String
  field :filename, type: String
  field :zip, type: BSON::Binary
  field :worker_id, type: String
  field :status, type: Integer, default: STATUSES.index(:processing)

  # For processing percentage using
  field :total_issues_amount, type: Integer, default: 0
  field :issues_processed_amount, type: Integer, default: 0

  def self.destroy_olds!
    IssuesSet.order(:created_at.desc).offset(MAX_STORED).destroy_all
  end

  def self.status_of(status_symbol)
    index = STATUSES.index(status_symbol)
    (index >= 0) ? index : (raise StatusDoesNotExist, status_symbol.inspect)
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

  def set_total_issues_amount!(amount)
    self.update_attributes!(total_issues_amount: amount)
  end

  def warn_issue_processed!
    amount = self.issues_processed_amount + 1
    self.update_attributes!(issues_processed_amount: amount)
  end

  def get_processed_percentage
    percentage = 0
    if(self.total_issues_amount != 0)
      percentage = ((self.issues_processed_amount.to_f / self.total_issues_amount)*100).to_i
    end 
    percentage
  end
end
