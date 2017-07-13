module GithubConsumer
  extend self

  # First calls for all issues URLs, then calls for each issue data and returns it
  # Also informs to et class how many results to calculate the percentage of the process
  def get_issues(query, match, label, comments, issues_set)
    issues_data = IssuesSearcher.get_all_issues(query, label, issues_set, comments)
    IssueInfoRetriever.get_info_from_issues(issues_data, comments, match, issues_set)
  end
end
