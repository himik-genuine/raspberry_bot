module MessageHandler
  def text(message)
    if bot_command?(message)
      command(message)
    else
      send_message(message['chat']['id'],
                   "#{message['text']} not recognized as command! Type /help for list of available commands.")
    end
  end

  def document(message)
    downloader(message)
  end

  private

  def command(message)
    command = message['text']
    if @methods['user_commands_keys'].include?(command.split[0])
      shell(message['chat']['id'], @methods['user_commands'][command.split[0]], command.split[1..-1].join(' '))
    elsif @methods['defined_commands'].include?(command.split[0].gsub('/', ''))
      send(command.split[0].gsub('/', ''), message['chat']['id'], command.split[1..-1].join(' '))
    else
      send_message(message['chat']['id'],
                   "Command #{command} not defined yet! Type /help for list of available commands.")
    end
  end

  def downloader(message)
    return unless file_size_ok?(message)

    file_url = @tg.session('getFile', { 'file_id' => message['document']['file_id'] })
    if file_url['ok']
      download_file(message, file_url)
    else
      send_message(message['chat']['id'], "Can't get file URL")
    end
  end

  def file_size_ok?(message)
    if message['document']['file_size'] * 0.000001 > 20
      send_message(message['chat']['id'], 'Bots can download files only of up to 20MB :o(')
      return false
    end
    true
  end

  def download_file(message, file_url)
    uri = URI("#{@settings['api_url']}file/bot#{@settings['token']}/#{file_url['result']['file_path']}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Get.new(uri)
    begin
      File.open("#{@settings['download_directory']}/#{message['document']['file_name']}", 'w') { |file| file.write(http.request(request).body) }
    rescue Errno::EACCES
      file_error = "Can't save file, permission denied to #{@settings['download_directory']}."
    rescue Errno::ENOENT
      file_error = "Can't save file, download directory #{@settings['download_directory']} not exist."
    end
    unless file_error
      send_message(message['chat']['id'],
                   "File #{message['document']['file_name']} saved to #{@settings['download_directory']}.")
    end
    send_message(message['chat']['id'], file_error) if file_error
  end
end
