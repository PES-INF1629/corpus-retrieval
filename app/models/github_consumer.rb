module GithubConsumer
  extend self

  def get_issues(query, match, label, comments)
    issues_urls = IssuesSearcher.get_all_issues_urls(query, match, label)
    IssueInfoSearcher.get_info_from_issues(issues_urls, comments, match)
  end
end