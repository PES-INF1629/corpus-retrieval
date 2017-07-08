module GithubConsumer
  module IssuesSearcher
    extend self

    MAX_PAGES = 3 # 3 x 7 match possibilities x 100 issues per page x 2 comments requisition per issue = 4200 requisitions max per query (not gonna happen, but seen as worst scenario)

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
    def get_all_issues_urls(query, match, label)
      main_query_url = "https://api.github.com/search/issues?q=#{query.gsub(" ","+")}+#{label}+is:issue&per_page=100"
      issues_urls = []
      client = Client.new
      json_items = []

      if match.nil? then # best match only
        url = UrlBuilder.build(main_query_url, 1, MATCHING_COMBINATIONS[0][:sort], MATCHING_COMBINATIONS[0][:order]) # Building url for first page in best match
        client.register_request url do |first_page_json|
          json_items = get_items_from_pages(main_query_url, first_page_json, MATCHING_COMBINATIONS[0])

          # merge urls - only one index in this case (only best match)
          issues_urls[0] = issues_urls_from(json_items, MATCHING_COMBINATIONS[0][:reversed])
        end
      else # newest, update and most commented
        MATCHING_COMBINATIONS.each_with_index do |matching, orderIndex|
          url = UrlBuilder.build(main_query_url, 1, matching[:sort], matching[:order])
          client.register_request url do |first_page_json|
            json_items = get_items_from_pages(main_query_url, first_page_json, matching)

            # merge urls
            issues_urls[orderIndex] = issues_urls_from(json_items, matching[:reversed])
          end
        end
      end
      client.run_requests
      issues_urls.reduce(:|)
      
      ### Visual test...
      #puts "\nPrimeira    issue:\n"
      #puts issues_urls[0]
      #puts "\nIssue     acabou\n"
      #exit
    end
  private

    # Gets "url" JSON block
    def issues_urls_from(json_items, is_reversed)
      issues_urls = json_items.map do |issue_json|
        issue_json["url"]
      end

      is_reversed ? issues_urls.reverse : issues_urls
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
