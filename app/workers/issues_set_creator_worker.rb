class IssuesSetCreatorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  # Define the name of the zip
  # Didn't understood IssuesSet
  # Destroy olds just let the 30 recent files alive
  def perform(query, match, label, comments)
    filename = query.gsub(/ +/, "_") + ".zip"
    issues_set = IssuesSet.create query: query, filename: filename, worker_id: self.jid
    IssuesSet.destroy_olds!

    begin
      issues = GithubConsumer.get_issues query, match, label, comments, issues_set
      binary = ZipBinaryCreator.create_zip_for(issues)

      issues_set.finish! BSON::Binary.new(binary)
    rescue Exception => e
      issues_set.update_attributes! status: IssuesSet.status_of(:failed)
      raise e
    end
  end
end
