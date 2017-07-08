module ZipBinaryCreator
  extend self

  # Creates the corpus/zip of json files with each having issue data
  def create_zip_for(issues_data)
    zipOutputBuffer = Zip::OutputStream.write_buffer do |zipElement|
      issues_data.each do |issue|
        filename = issue[:filename]
        content = create_json issue
        zipElement.put_next_entry filename
        zipElement.write content
      end
    end
    zipOutputBuffer.rewind
    zipOutputBuffer.sysread
  end

private

  # Organizes data in JSON style
  def create_json(issue)
	jsonFile = "{\n"

	jsonFile += "\t\"url\": \"#{issue[:url]}\",\n"
	jsonFile += "\t\"html_url\": \"#{issue[:html_url]}\",\n"
	jsonFile += "\t\"title\": \"#{issue[:title]}\",\n"
	jsonFile += "\t\"user\": \"#{issue[:user]}\",\n"
	jsonFile += "\t\"labels\": [\n"

	issue[:labels].each.with_index do |label, index|
		jsonFile += "\t\t{\n"
		
		jsonFile += "\t\t\t\"name\": \"#{label[:name]}\"\n"

		if index == issue[:labels].length - 1 then
			jsonFile += "\t\t}\n"
		else
			jsonFile += "\t\t},\n"
		end
	end
    
	jsonFile += "\t],\n"

	treatSpecialChars(issue)
	
	if issue[:comments].nil? then
		jsonFile += "\t\"body\": \"#{issue[:body]}\"\n"
	else
		jsonFile += "\t\"body\": \"#{issue[:body]}\",\n"

		jsonFile += "\t\"comments\": #{issue[:comments]},\n"
		jsonFile += "\t\"comments_content\": [\n"


		issue[:comments_content].each.with_index do |comment_content, index|
			treatSpecialChars(comment_content)
			jsonFile += "\t{\n"
			jsonFile += "\t\t\"user\": \"#{comment_content[:user]}\",\n"
			jsonFile += "\t\t\"body\": \"#{comment_content[:body]}\"\n"

			if index == issue[:comments_content].length - 1 then
				jsonFile += "\t}\n"
			else
				jsonFile += "\t},\n"
			end
		end

		jsonFile += "\t]\n"
	end

	jsonFile += "}"
  end

  # In case specified special chars below are used, so they are not written as they are in file
  def treatSpecialChars(hash)
  	if not hash[:body].nil? then # In case it doesn't have body
		hash[:body].gsub!("\n","\\n")
		hash[:body].gsub!("\r","\\r")
		hash[:body].gsub!("\t","\\t")
		hash[:body].gsub!("\"","\\\"")
		hash[:body].gsub!("\'","\\\'")
		hash[:body].gsub!("\0","\\0")
		hash[:body].gsub!("\\","\\\\")
		if not hash[:title].nil? then # If is label, treat title too
			hash[:title].gsub!("\n","\\n")
			hash[:title].gsub!("\r","\\r")
			hash[:title].gsub!("\t","\\t")
			hash[:title].gsub!("\"","\\\"")
			hash[:title].gsub!("\'","\\\'")
			hash[:title].gsub!("\0","\\0")
			hash[:title].gsub!("\\","\\\\")
		end
	end
  end
end
