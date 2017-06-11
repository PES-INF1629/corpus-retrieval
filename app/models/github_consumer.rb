module GithubConsumer
  extend self

  def get_readmes(query)
    issues_urls = IssuesSearcher.get_all_issues_urls(query)
    IssueInfoSearcher.get_info_from_issues(issues_urls)
  end
end