class IssuesController < ApplicationController

  def index
    @sets = ReadmesSet.order(:created_at.desc).all.to_a
  end

  def download
    set = ReadmesSet.find(params[:issue_id])
    send_data set.zip_to_download, filename: set.filename, type: 'application/octet-stream'
  end

  def search_form; end

  def search
    comments = false
    if(params.has_key?("comments"))
        comments = true
    end
    
    ReadmesSetCreatorWorker.perform_async(params[:query], params[:match], params[:label], comments)
    redirect_to issues_path
  end
end
