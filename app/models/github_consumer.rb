module GithubConsumer
  extend self

  # First calls for all issues URLs, then calls for each issue data and returns it
  # Also informs to et class how many results to calculate the percentage of the process
  def get_issues(query, match, label, comments, issues_set)
    issues_urls = IssuesSearcher.get_all_issues_urls(query, match, label)
    issues_set.set_total_issues_amount!(issues_urls.length)
    IssueInfoSearcher.get_info_from_issues(issues_urls, comments, match, issues_set)
  end
end
