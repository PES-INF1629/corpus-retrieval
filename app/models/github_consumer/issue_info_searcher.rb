module GithubConsumer
  module IssueInfoSearcher
    extend self

    # Builds structure containing issues data
    def get_info_from_issues(issues_urls, comments, match, issues_set)
      client = Client.new
      issues_raw_data = []

      issues_urls.each do |issue_url|
        url = UrlBuilder.build(issue_url)
        client.register_request url do |issue_json|
          issues_set.warn_issue_processed! # Issue processed, update percentage
          issues_raw_data.push(
            id: issue_json["id"], # used in JSON file to better identification
            url: issue_json["url"],
            html_url: issue_json["html_url"],
            title: issue_json["title"],
            user: issue_json["user"]["login"],
            labels: issue_json["labels"],
            body: issue_json["body"],
            comments: issue_json["comments"], # in case user requested comments
            comments_url: issue_json["comments_url"],
            created_at: issue_json["created_at"], # Matching in newest
            updated_at: issue_json["updated_at"] # Matching in recently updated
          )
        end
      end
      client.run_requests
      
      ordered_data = order_structure(issues_raw_data, match, issues_urls)
      
      issues_processed_data = []

      # For comments retrieving
      client = Client.new
      ordered_data.compact.each.with_index do |issue_data, data_index|
        
        filename = file_name_from(data_index, issue_data)
        labels = []
        if not issue_data[:labels].nil? then
          issue_data[:labels].each do |label_data| # issue may contain more than one label, store them all
            labels.push(name: label_data["name"])
          end
        end

        issues_processed_data.push(
          filename: filename,
          url: issue_data[:url],
          html_url: issue_data[:html_url],
          title: issue_data[:title],
          user: issue_data[:user],
          labels: labels,
          body: issue_data[:body]
        )

        if comments then # retrieving comments
          url = UrlBuilder.build issue_data[:comments_url]
          client.register_request url do |comments_json|
            comments_content = []
            if not comments_json.nil? then # Some issues may not have comments
              comments_json.each do |comment|
                comments_content.push(user: comment["user"]["login"], body: comment["body"])
              end
            end
            issues_processed_data[data_index][:comments] = issue_data[:comments]
            issues_processed_data[data_index][:comments_content] = comments_content
          end
        end   
      end
      client.run_requests

      issues_processed_data
    end

  private

    # Returns a ordered version of the received structure
    def order_structure(issues_raw_data, match, issues_urls)

      ordered_data = []
      case match # first three cases in decreasing order
      when "comments"
        ordered_data = issues_raw_data.sort! { |a, b| b[:comments] <=> a[:comments] }
      when "created"
        ordered_data = issues_raw_data.sort! { |a, b| b[:created_at] <=> a[:created_at] }
      when "updated"
        ordered_data = issues_raw_data.sort! { |a, b| b[:updated_at] <=> a[:updated_at] }
      else # best match
        issues_urls.each do |url| # issues_urls is ordered by default in best match, using it as order parameter
          issues_raw_data.each do |issueData|
            if url == issueData[:url] then # Storing data in right position
              ordered_data.push(issueData)
              break
            end
          end
        end
      end

      ordered_data
    end

    # Makes corresponding file name of given issue
    # Logic: 'position in request'.-.'repository owner'.-.'repository name'.-.'issue id in GitHub'.json
    def file_name_from(corresponding_index, issue_data)
      data = [
        sprintf("%.4d", corresponding_index+1),
        issue_data[:url].split("/")[4],
        issue_data[:url].split("/")[5],
        issue_data[:id]
      ]
      "#{data.join(".-.")}.json"
    end
  end
end
