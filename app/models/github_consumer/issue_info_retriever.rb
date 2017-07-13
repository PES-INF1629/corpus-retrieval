module GithubConsumer
  module IssueInfoRetriever
    extend self

    # Builds structure containing issues data
    def get_info_from_issues(issues_data, comments, match, issues_set)  
      # For comments retrieving
      client = Client.new

      issues_processed_data = []
      order_structure(issues_data, match) 
      
      issues_data.compact.each.with_index do |issue_data, data_index|
        
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
          issues_set.warn_issue_processed!
        end   
      end
      client.run_requests

      issues_processed_data
    end

  private

    # Returns a ordered version of the received structure
    def order_structure(issues_data, match)

      case match # Treating in decreasing order
      when "comments"
        issues_data.sort! { |issueA, issueB| issueB[:comments] <=> issueA[:comments] }
      when "created"
        issues_data.sort! { |issueA, issueB| issueB[:created_at] <=> issueA[:created_at] }
      when "updated"
        issues_data.sort! { |issueA, issueB| issueB[:updated_at] <=> issueA[:updated_at] }
      else # best match
        issues_data.sort! { |issueA, issueB| issueB[:score] <=> issueA[:score] }
      end
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
