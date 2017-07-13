module GithubConsumer
  module IssuesSearcher
    extend self

    # 3 (pages) x 7 (match possibilities) x 100 (issues per page) x 2 (comments requisition per issue) = 4200 requisitions max per query (not gonna happen, but seen as worst scenario)
    MAX_PAGES = 3

    MATCHING_COMBINATIONS = [
      {sort: nil, order: nil, reversed: false}, # best match
      {sort: "comments", order: "desc", reversed: false},
      {sort: "created", order: "desc", reversed: false},
      {sort: "updated", order: "desc", reversed: false},
      {sort: "comments", order: "asc", reversed: true},
      {sort: "created", order: "asc", reversed: true},
      {sort: "updated", order: "asc", reversed: true}
    ]

    # Builds the main query link and returns the organized structure with the info from each issue
    def get_all_issues(query, label, issues_set, comments)
      main_query_url = "https://api.github.com/search/issues?q=#{query.gsub(" ","+")}+#{label}+is:issue&per_page=100"
      issues_data = []
      client = Client.new
      json_items = []

      # An estimation of total of issues, quickest and lamest way to inform it...
      # The right way to do it is to inform the exact total of issues, but we are limited for now (only 3 pages)
      issues_set.set_total_issues_amount!(MATCHING_COMBINATIONS.length * MAX_PAGES * 100)

      MATCHING_COMBINATIONS.each_with_index do |matching, orderIndex|
        url = UrlBuilder.build(main_query_url, 1, matching[:sort], matching[:order])
        client.register_request url do |first_page_json|
          json_items = get_items_from_pages(main_query_url, first_page_json, matching)

          # merge urls
          issues_data[orderIndex] = issues_issues_from(json_items, matching[:reversed], issues_set, comments)
        end
      end
      client.run_requests
      issues_data.compact.flatten.uniq { |issue| issue[:id] }
    end

  private

    # Gets each issue data from JSON block
    def issues_issues_from(json_items, is_reversed, issues_set, comments)
      issues_data = []
      json_items.map do |issue_json|
        if not comments # Not finished processing issues
          issues_set.warn_issue_processed!
        end
        issues_data.push(
            id: issue_json["id"], # used in JSON file to better identification
            url: issue_json["url"],
            html_url: issue_json["html_url"],
            title: issue_json["title"],
            user: issue_json["user"]["login"],
            labels: issue_json["labels"],
            body: issue_json["body"],
            comments: issue_json["comments"], # Matching in most commented
            comments_url: issue_json["comments_url"], # in case user requested comments
            created_at: issue_json["created_at"], # Matching in newest
            updated_at: issue_json["updated_at"], # Matching in recently updated
            score: issue_json["score"] # Matching in best match
          )
      end

      is_reversed ? issues_data.reverse : issues_data
    end

    # Goes to remaining pages and returns a structure with "items" JSON blocks (each block is a issue to request)
    def get_items_from_pages(main_query_url, first_page_json, matching)
      total_issues = first_page_json["total_count"]
      total_pages = [total_issues / 100, MAX_PAGES].min

      json_items = []
      json_items[1] = first_page_json["items"]
      client = Client.new
      (2..total_pages).each do |page|
        page_url = UrlBuilder.build(main_query_url, page, matching[:sort], matching[:order])
        client.register_request page_url do |json|
          json_items[page] = json["items"]
        end
      end
      client.run_requests
      
      json_items.compact.flatten
    end
  end
end
