module GithubConsumer
  module IssueInfoSearcher
    extend self

    # Builds structure representing info inside each file in corpus and returns it (doesn't build file nor corpus, only info)
    #######
    # TODO:
    # 1 - Order issues_content with match logic
    #######
    def get_info_from_issues(issues_urls, comments, match)
      unrecognizeds = [] # Needed?
      client = Client.new
      issues_data = []
      issues_urls.each_with_index do |head_url, i|
        issue_data = nil
        url = UrlBuilder.build(head_url)
        client.register_request url do |root_json|
            issues_data.push(
              id: root_json["id"], # To identify in json file
              url: root_json["url"],
              title: root_json["title"],
              user: root_json["user"]["login"],
              labels: root_json["labels"],
              body: root_json["body"],

              comments: root_json["comments"], # If comments info are needed (match in most commented and/or getting comments content)
              comments_url: root_json["comments_url"],
              
              created_at: root_json["created_at"], # Matching in most recently created
              updated_at: root_json["updated_at"] # Matching in most recently updated
            )
        end
      end
      client.run_requests

      issues_content = []

      # For comments retrieving
      client = Client.new

      issues_data.compact.each.with_index do |issue_data, i|
        
        filename = file_name_from(i, issue_data)
        labels = []
        if not issue_data[:labels].nil? then
          for labelIndex in 0..issue_data[:labels].length - 1 # Issue may contain more than one label
            labels.push(name: issue_data[:labels][labelIndex]["name"])
          end
        end

        issues_content.push(
          filename: filename,
          url: issue_data[:url],
          title: issue_data[:title],
          user: issue_data[:user],
          labels: labels,
          body: issue_data[:body]
        )

        if comments then
          url = UrlBuilder.build issue_data[:comments_url]
          client.register_request url do |comments_json|
            comments_content = []
            if not comments_json.nil? then # Some issues may not have comments
              for commentIndex in 0..comments_json.length - 1 # comments_json contains a vector with each index being a comment
                comments_content.push(user: comments_json[commentIndex]["user"]["login"], body: comments_json[commentIndex]["body"])
              end
            end
            issues_content[i][:comments] = issue_data[:comments]
            issues_content[i][:comments_content] = comments_content
          end
        end   
      end
      client.run_requests

      ### Visual test...
      #puts "\n    Some issue content:    \n"
      #for issuesContentIndex in 0..issues_content.length - 1
      #  if not issues_content[issuesContentIndex][:body].blank? and # Issue has body
      #      (not comments or issues_content[issuesContentIndex][:comments] == 3) and # Has 3 comments
      #      (not issues_content[issuesContentIndex][:labels].nil? and issues_content[issuesContentIndex][:labels].length == 2) then # Has two labels
      #    puts issues_content[issuesContentIndex]
      #   break
      #  end
      #end
      #puts "\n    Content finished    \n"

      issues_content
    end

  private

    # Returns the name to file containing info of given issue
    # Logic: 'position in request'.-.'repository owner'.-.'repository name'.-.'issue id in GitHub'.json
    def file_name_from(i, issue_data)
      data = [
        sprintf("%.4d", i+1),
        issue_data[:url].split("/")[4],
        issue_data[:url].split("/")[5],
        issue_data[:id]
      ]
      "#{data.join(".-.")}.json"
    end
  end
end
