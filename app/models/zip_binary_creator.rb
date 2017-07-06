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

  def create_json(file)
	jsonFile = "{\n"

	jsonFile += "\"url\": \"#{file[:url]}\",\n"
	jsonFile += "\"html_url\": \"#{file[:html_url]}\",\n"
	jsonFile += "\"title\": \"#{file[:title]}\",\n"
	jsonFile += "\"user\": \"#{file[:user]}\",\n"
	jsonFile += "\"labels\": [\n"

	file[:labels].each_with_index { |label, index|
		jsonFile += "\t{"
		
		jsonFile += "\t\t\"name\": \"#{label[:name]}\"\n"

		if index == file[:labels].length - 1 then
			jsonFile += "\t}\n"
		else
			jsonFile += "\t},\n"
		end
	}

	if file[:comments].nil? then
		jsonFile += "\"body\": \"#{file[:body]}\"\n"
	else
		jsonFile += "\"body\": \"#{file[:body]}\",\n"

		jsonFile += "\"comments\": #{file[:comments]},\n"
		jsonFile += "\"comments_content\": [\n"


		file[:comments_content].each_with_index { |comment_content, index|
			jsonFile += "\t{"
			jsonFile += "\t\t\"user\": \"#{comment_content[:user]}\"\n"
			jsonFile += "\t\t\"body\": \"#{comment_content[:body]}\"\n"

			if index == file[:comments_content].length - 1 then
				jsonFile += "\t}\n"
			else
				jsonFile += "\t},\n"
			end
		}

		jsonFile += "]\n"
	end

	jsonFile += "}"
  end
end
