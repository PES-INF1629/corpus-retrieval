module GithubConsumer
  module IssuesSearcher
    extend self

    MAX_PAGES = 2

    PARAMS_COMBINATIONS = [
      {sort: nil, order: nil}, # best match
      {sort: "comments", order: "desc"},
      {sort: "created", order: "desc"},
      {sort: "updated", order: "desc"},
      {sort: "comments", order: "asc", reversed: true},
      {sort: "created", order: "asc", reversed: true},
      {sort: "updated", order: "asc", reversed: true}
    ]

    # Builds the main query link and returns the organized structure with the info from each issue
    def get_all_issues_urls(query, match, label)
      issues_url = "https://api.github.com/search/issues?q=#{query.gsub(" ","+")}+#{label}+is:issue&per_page=100"
      all_head_urls = []
      client = Client.new
      items = []
      if match.nil? then # best match only
        url = UrlBuilder.build(issues_url, 1, nil, nil)
        client.register_request url do |first_page_json|
          items = get_items_from_pages(issues_url, first_page_json, {sort: nil, order: nil})

          # merge urls
          all_head_urls[0] = head_urls_from(items, nil)
        end
      else
        PARAMS_COMBINATIONS.each_with_index do |params, paramsIndex|
          url = UrlBuilder.build(issues_url, 1, params[:sort], params[:order])
          client.register_request url do |first_page_json|
            items = get_items_from_pages(issues_url, first_page_json, params)

            # merge urls
            all_head_urls[paramsIndex] = head_urls_from(items, params[:reversed])
          end
        end
      end
      client.run_requests
      all_head_urls.reduce(:|)
      
      ### Visual test...
      #puts "\nPrimeira    issue:\n"
      #puts all_head_urls[0]
      #puts "\nIssue     acabou\n"
      #exit
    end
  private

    # Gets "url" JSON block
    def head_urls_from(items, is_reversed)
      head_urls = items.map do |issue_json|
        issue_json["url"]
      end

      is_reversed ? head_urls.reverse : head_urls
    end

    # Goes to remaining pages and returns a structure with "items" JSON blocks (each block is a issue to request)
    def get_items_from_pages(issues_url, first_page_json, params)
      total_items = first_page_json["total_count"]
      total_pages = [total_items / 100, MAX_PAGES].min

      items = []
      items[1] = first_page_json["items"]
      client = Client.new
      (2..total_pages).each do |page|
        page_url = UrlBuilder.build(issues_url, page, params[:sort], params[:order])
        client.register_request page_url do |json|
          items[page] = json["items"]
        end
      end
      client.run_requests
      
      items.compact.flatten
    end
  end
end
