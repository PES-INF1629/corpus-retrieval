module GithubConsumer
  module IssueInfoSearcher
    extend self

    # Builds structure representing info inside each file in corpus and returns it (doesn't build file nor corpus, only info)
    def get_info_from_issues(issues_urls)
      unrecognizeds = [] # Needed?
      client = Client.new
      issues_data = []
      issues_urls.each_with_index do |head_url, i|
        issue_data = nil
        url = UrlBuilder.build(head_url)
        client.register_request url do |root_json|
          ### IDEA 1: Build issues info alongside comments info
          # if 'no_comments'
            issues_data.push(
              id: root_json["id"], # Just to identify in txt file...
              url: root_json["url"],
              title: root_json["title"],
              labels: root_json["labels"],
              body: root_json["body"],
              comments_url: root_json["comments_url"] # Needed for IDEA 2
            )
          # else
          #  issues_data.push(
          #   ...
          #   comments: root_json["comments"],
          #   ####
          # => Line below will probably need another request: 'Client.new' bla bla bla
          #   ####
          #   comments_info: 'comment info' from root_json["comments_url"] 
          #  )
        end
      end
      client.run_requests

      issues_content = []

      ### IDEA 2: We use block below to look for comments, taking info from block above and merging
      ###         with "comments" and "comments_info" into a new structure. See that client class usage
      ###         for requests is specified below in commented lines.
      # client = Client.new
      issues_data.compact.each.with_index do |issue_data, i|
        # url = UrlBuilder.build issue_data[:comments_url]
        # client.register_request url do |issue_json|
          # Gotta see how to store into structure each comment separately (or together)...
          # comments_content = 'info from "comments_url"'
          filename = file_name_from(i, issue_data)
          issues_content.push(
            filename: filename,
            url: issue_data[:url],
            title: issue_data[:title],
            labels: issue_data[:labels],
            body: issue_data[:body]
            #,comments_info: comments_content)
          )
        # end
      end
      # client.run_requests

      ### Visual test...
      # puts "\n    First issue content:    \n"
      # puts issues_content[0]
      # puts "\n    Content finished    \n"

      issues_content
    end

  private

    # Returns the name to file containing info of given issue
    # Logic: 'position in request'.-.'repository owner'.-.'repository name'.-.'issue id in GitHub'.txt
    def file_name_from(i, issue_data)
      data = [
        sprintf("%.4d", i+1),
        issue_data[:url].split("/")[4],
        issue_data[:url].split("/")[5],
        issue_data[:id]
      ]
      "#{data.join(".-.")}.txt"
    end
  end
end
