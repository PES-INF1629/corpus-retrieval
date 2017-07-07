module GithubConsumer
  module IssueInfoSearcher
    extend self

    # Builds structure representing info inside each file in corpus and returns it (doesn't build file nor corpus, only info)
    def get_info_from_issues(issues_urls, comments, match, issues_set)
      client = Client.new
      issues_data = []
      issues_urls.each_with_index do |head_url, i|
        issue_data = nil
        url = UrlBuilder.build(head_url)
        client.register_request url do |root_json|
	    # Not changing the number of issues processed
	    issues_set.warn_issue_processed!
            issues_data.push(
              id: root_json["id"], # To identify in json file
              url: root_json["url"],
              html_url: root_json["html_url"],
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

      # Not changing the number of total issues processed
      #issues_set.set_total_issues_amount!(issues_urls.length)
      client.run_requests
      
      ###Test
      issues_dataSizeBefore = issues_data.length
      #issues_dataBefore = issues_data.clone
      
      ordered_data = order_structure(issues_data, match, issues_urls)
      
      issues_content = []

      # For comments retrieving
      client = Client.new

      ordered_data.compact.each.with_index do |issue_data, i|
        
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
          html_url: issue_data[:html_url],
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
      #puts "    Some issue content:"
      #for issuesContentIndex in 0..issues_content.length - 1
      #  if not issues_content[issuesContentIndex][:body].blank? and # Issue has body
      #      (not comments or issues_content[issuesContentIndex][:comments] == 3) and # Has 3 comments
      #      (not issues_content[issuesContentIndex][:labels].nil? and issues_content[issuesContentIndex][:labels].length == 2) then # Has two labels
      #    puts issues_content[issuesContentIndex]
      #   break
      #  end
      #end
      #puts "    Content finished"
      #puts "    1    issues_urls size:"
      #puts issues_urls.length
      #puts "    2    issues_data size before ordering:"
      #puts issues_dataSizeBefore
      #puts "    3    ordered_data size after ordering:"
      #puts ordered_data.length
      #puts "    4    issues_content size:"
      #puts issues_content.length
      #puts "      issues_data before order best match first 5:"
      #for i in 0..4
      #  puts issues_dataBefore[i][:url]
      #end
      #puts "      finished"
      #puts "      issues_data after order best match first 5:"
      #for i in 0..4
      #  puts issues_data[i][:url]
      #end
      #puts "      finished"

      issues_content
    end

  private

    # Returns a ordered version of the received structure
    def order_structure(issues_data, match, issues_urls)

      ordered_data = []
      case match
      when "comments"
        ordered_data = issues_data.sort! { |a, b| b[:comments] <=> a[:comments] }
      when "created"
        ordered_data = issues_data.sort! { |a, b| b[:created_at] <=> a[:created_at] }
      when "updated"
        ordered_data = issues_data.sort! { |a, b| b[:updated_at] <=> a[:updated_at] }
      else # best match
        issues_urls.each.with_index do |url, urlIndex| # Using urls index as order parameter
          issues_data.each.with_index do |issueData, issueDataIndex|
            if url == issueData[:url] then # Storing data in right position
              ordered_data.push(issueData)
              break
            end
          end
        end
      end

      ## Tests
      #puts "    ordered_data ordered in \"#{if not match.nil? then match else "best match" end}\":"
      #ordered_data.each do |issue|
      #  if match == "comments"
      #    puts issue[:comments]
      #  elsif match == "created"
      #    puts issue[:created_at]
      #  elsif match == "updated"
      #    puts issue[:updated_at]
      #  else
      #    puts issue[:url]
      #  end
      #end

      ordered_data
    end

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
