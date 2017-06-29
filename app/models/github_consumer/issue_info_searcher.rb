module GithubConsumer
  module IssueInfoSearcher
    extend self

    # Builds structure representing info inside each file in corpus and returns it (doesn't build file nor corpus, only info)
    #######
    # TODO: Make comment part without repeating code
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

      ### Code repeating below, make it better ###
      # Passin info to new structure AND searching for comments
      if comments then
        client = Client.new
        flag = true
        issues_data.compact.each.with_index do |issue_data, i|
          url = UrlBuilder.build issue_data[:comments_url]
          filename = file_name_from(i, issue_data)
          comments_content = []

          client.register_request url do |comments_json|
            
            for commentIndex in 0..comments_json.length - 1 # Vector of comments content
              comments_content.push({user: comments_json[commentIndex]["user"]["login"], body: comments_json[commentIndex]["body"]})
            end
            
            issues_content.push(
              filename: filename,
              url: issue_data[:url],
              title: issue_data[:title],
              user: issue_data[:user],
              labels: issue_data[:labels],
              body: issue_data[:body],
              comments: issue_data[:comments],
              comments_content: comments_content
            )
          end

        end
        client.run_requests
      else # Only passing info to new structure
        issues_data.compact.each.with_index do |issue_data, i|
          filename = file_name_from(i, issue_data)
          issues_content.push(
            filename: filename,
            url: issue_data[:url],
            title: issue_data[:title],
            user: issue_data[:user],
            labels: issue_data[:labels],
            body: issue_data[:body]
          )
        end
      end

      ### Visual test...
      #puts "\n    Random issue content:    \n"
      #puts issues_content[10]
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
