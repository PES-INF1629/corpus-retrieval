class IssuesController < ApplicationController

  # Returns the sets of previous results in decresc order of date
  def index
    @sets = IssuesSet.order(:created_at.desc).all.to_a
  end

  # When a download request is made
  def download
    set = IssuesSet.find(params[:issue_id])
    send_data set.zip_to_download, filename: set.filename, type: 'application/octet-stream'
  end

  def search_form; end

  # Receive every params when a query is requested and sends it to worker.
  # worker will work in the background so the website doesn't load forever.
  def search
    comments = false
    if(params.has_key?("comments"))
        comments = true
    end
    
    IssuesSetCreatorWorker.perform_async(params[:query], params[:match], params[:label], comments)
    redirect_to issues_path
  end
end
