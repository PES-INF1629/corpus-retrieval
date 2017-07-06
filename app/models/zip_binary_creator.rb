module ZipBinaryCreator
  extend self

  def create_zip_for(files)
    zipOutputBuffer = Zip::OutputStream.write_buffer do |zipElement|
      files.each do |file|
        filename = file[:filename]
        content = create_json file
        zipElement.put_next_entry filename
        zipElement.write content
      end
    end
    zipOutputBuffer.rewind
    zipOutputBuffer.sysread
  end

private

  def create_json(file)
	jsonFile = "{\n"

	jsonFile += "\t\"url\": \"#{file[:url]}\",\n"
	jsonFile += "\t\"html_url\": \"#{file[:html_url]}\",\n"
	jsonFile += "\t\"title\": \"#{file[:title]}\",\n"
	jsonFile += "\t\"user\": \"#{file[:user]}\",\n"
	jsonFile += "\t\"labels\": [\n"

	file[:labels].each_with_index { |label, index|
		jsonFile += "\t\t{\n"
		
		jsonFile += "\t\t\t\"name\": \"#{label[:name]}\"\n"

		if index == file[:labels].length - 1 then
			jsonFile += "\t\t}\n"
		else
			jsonFile += "\t\t},\n"
		end
	}
    
	jsonFile += "\t],\n"

	treatSpecialChars(file)
	
	if file[:comments].nil? then
		jsonFile += "\t\"body\": \"#{file[:body]}\"\n"
	else
		jsonFile += "\t\"body\": \"#{file[:body]}\",\n"

		jsonFile += "\t\"comments\": #{file[:comments]},\n"
		jsonFile += "\t\"comments_content\": [\n"


		file[:comments_content].each_with_index { |comment_content, index|
			treatSpecialChars(comment_content)
			jsonFile += "\t{\n"
			jsonFile += "\t\t\"user\": \"#{comment_content[:user]}\",\n"
			jsonFile += "\t\t\"body\": \"#{comment_content[:body]}\"\n"

			if index == file[:comments_content].length - 1 then
				jsonFile += "\t}\n"
			else
				jsonFile += "\t},\n"
			end
		}

		jsonFile += "\t]\n"
	end

	jsonFile += "}"
  end

  def treatSpecialChars(hash)
	hash[:body].gsub!("\n","\\n")
	hash[:body].gsub!("\r","\\r")
	hash[:body].gsub!("\t","\\t")
	hash[:body].gsub!("\"","\\\"")
	hash[:body].gsub!("\'","\\\'")
	hash[:body].gsub!("\0","\\0")
	hash[:body].gsub!("\\","\\\\")
  end
end
