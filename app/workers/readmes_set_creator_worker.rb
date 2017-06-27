class ReadmesSetCreatorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(query, match, label, comments)
    # TESTS
    #puts(query)
    #puts(match)
    #puts(label)
    #puts(comments)
    #print("\nHERE\n")
    #sleep(60)
    filename = query.gsub(/ +/, "_") + ".zip"
    issues_set = ReadmesSet.create query: query, filename: filename, worker_id: self.jid
    ReadmesSet.destroy_olds!

    begin
      issues = GithubConsumer.get_issues query, match, label, comments
      binary = ZipBinaryCreator.create_zip_for(issues)

      issues_set.finish! BSON::Binary.new(binary)
    rescue Exception => e
      issues_set.update_attributes! status: ReadmesSet.status_of(:failed)
      raise e
    end
  end
end
