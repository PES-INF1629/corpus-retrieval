module ZipBinaryCreator
  extend self

  def create_zip_for(files)
    zipOutputBuffer = Zip::OutputStream.write_buffer do |zipElement|
      files.each do |file|
        filename = file[:filename]
        content = file[:content]
        zipElement.put_next_entry filename
        zipElement.write content
      end
    end
    zipOutputBuffer.rewind
    zipOutputBuffer.sysread
  end
end
