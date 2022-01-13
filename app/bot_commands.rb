module BotCommands
  def system(chat_id, help = false)
    return 'System summary. Can be used with "temp", "freq" and "uptime" commands.' if help == true

    case help.split[0]
    when 'temp'
      send_message(chat_id, "#{@mon.cpu_temp} °C")
    when 'freq'
      send_message(chat_id, "Current frequency: #{@mon.cpu_freq} MHz\n\nCPU frequency statistics:\n#{@mon.cpu_freqstat}")
    when 'uptime'
      uptm = @mon.uptime
      send_message(chat_id, "#{uptm[0]} Days #{uptm[1]} Hours #{uptm[2]} Minutes #{uptm[3]} Seconds")
    else
      send_message(chat_id, @mon.summary)
    end
  end

  def off(chat_id, help = false)
    return 'Bot shutdown.' if help == true

    send_message(chat_id, 'Repite this command in 10 seconds to stop the bot. Since stopped, bot cant be up again via telegram!') unless @off
    @run = false if @off
    send_message(chat_id, 'Bot stopped.') if @off
    Thread.new { @off = true; sleep 10; @off = false; send_message(chat_id, '"Off" command canceled.') }
  end

  def monitoring(chat_id, help = false)
    return 'Monitoring module start\stop, thresholds set.' if help == true

    if %w[start stop temp mem].include?(help.split[0])
      send_message(chat_id, @mon.monitoring(help))
    elsif help.split[0].nil?
      send_message(chat_id, mon_state)
    else
      send_message(chat_id, "Command not recognized!\n\n#{mon_state}")
    end
  end

  def config(chat_id, help = false)
    return 'Save\reload configuration, set parameters.' if help == true

    case help.split[0]
    when 'save'
      Settings.save_settings
      send_message(chat_id, 'Configuration saved!')
    when 'load'
      load_settings
      send_message(chat_id, 'Configuration reloaded from config file, all unsaved changes dropped!')
    when 'host'
      host_set(chat_id, help.split[1..-1].join(' '))
    when 'download'
      download_set(chat_id, help.split[1..-1].join(' '))
    else
      text = "\"/config host \"hostname\"\" for set hostname.\n"
      text += "\"/config download \"path\"\" for set download directory.\n"
      text += "\"/config load\" for reload configuration from config file.\n"
      text += "\"/config save\" for save configuration to config file.\n"
      send_message(chat_id, text)
    end
  end

  def shell(chat_id, help, command = "")
    return 'Execute shell command.' if help == true

    if help == ''
      send_message(chat_id, 'Command was empty!')
      return
    end
    exec_shell(chat_id, help, command)
  end

  def help(chat_id, help = false)
    return 'List of available commands.' if help == true

    monitoring = if @settings['monitoring']
                   'Active'
                 else
                   'Disabled'
                 end
    text = "Monitoring module is: #{monitoring}\n"
    if @settings['monitoring']
      text += "\nCPU temperature status: #{'OK' if @states['temperature_state']}#{'Problem!' unless @states['temperature_state']}\n" if @settings['cpu_temperature']
      text += "Memory usage status: #{'OK' if @states['used_memory_state']}#{'Problem!' unless @states['used_memory_state']}\n" if @settings['used_memory']
    end
    text += "\nAvailable commands:\n"
    @methods['defined_commands'].each { |cmd| text += "/#{cmd} - #{send(cmd, 0, true)}#{" (Overrided by user defined command!)" if @methods['user_commands_keys'].include?("/#{cmd}")}\n" }
    text += "\nUser defined commands:\n" if @methods['user_commands'].any?
    @methods['user_commands_keys'].each { |cmd| text += "#{cmd} - #{@methods['user_commands'][cmd]}\n" } if @methods['user_commands'].any?

    send_message(chat_id, text)
  end

  private

  def host_set(chat_id, hostname)
    if hostname == ''
      send_message(chat_id, 'You must specify host name after "/system host".')
    else
      @settings['host'] = hostname
      send_message(chat_id, "Name of the host set to \"#{hostname}\"")
    end
  end

  def download_set(chat_id, directory)
    if directory == ''
      send_message(chat_id, 'You must specify directory after "/system download".')
    else
      @settings['download_directory'] = directory
      send_message(chat_id, "Download directory set to \"#{directory}\"")
    end
  end

  def load_settings
    @settings, @methods = Settings.settings
    @methods['defined_commands'] = BotCommands.instance_methods.map(&:to_s)
    @methods['supported'] = MessageHandler.instance_methods.map(&:to_s)
  end

  def message_split(string, size)
    string.chars
          .each_slice(size)
          .map(&:join)
  end

  def mon_state
    text = "Monitoring module is #{'active' if @settings['monitoring']}#{'stopped' unless @settings['monitoring']}.\n\n"
    if @settings['monitoring']
      text += "CPU temp threshold is #{@settings['cpu_temperature']} °C, status: #{'OK' if @states['temperature_state']}#{'Problem!' unless @states['temperature_state']}\n" if @settings['cpu_temperature']
      text += "CPU themperature threshold disabled\n" unless @settings['cpu_temperature']
      text += "Memory usage threshold is #{@settings['used_memory']}%, status: #{'OK' if @states['used_memory_state']}#{'Problem!' unless @states['used_memory_state']}\n" if @settings['used_memory']
      text += "Memory usage threshold disbled\n" unless @settings['used_memory']
    end
    text += "\nUse \"/monitoring start\" or \"/monitoring stop\" to change state.\n"
    text += "Use \"/monitoring temp\" or \"/monitoring mem\" to change thresholds."
    text
  end

  def exec_shell(chat_id, cmd, command = "")
    send_message(chat_id, "Starting execution: #{cmd}")
    Thread.new do
      begin
        cmd = cmd.gsub("$@", "#{command}".shellescape);
        result = Timeout.timeout(@settings['commands_timeout']) { `#{cmd} 2>&1` }
      rescue Errno::ENOENT
        result = 'Execution failed, no such file or directory!'
      rescue Timeout::Error
        result = "Execution of command reached timeout(#{@settings['commands_timeout']} seconds), aborted!"
      end
      result = message_split(result, 4000)
      if result.size == 1
        send_message(chat_id, "Result for \"#{cmd}\" is:\n#{result.join}")
      elsif result.size <= @settings['messages_limit']
        send_message(chat_id, "Result for \"#{cmd}\" is:")
        result.each { |res| send_message(chat_id, res) }
      else
        send_message(chat_id,
                     "Result for \"#{cmd}\" is exceeding messages limit. Output size is #{result.size} messages, while only #{@settings['messages_limit']} messages allowed!")
      end
    end
  end
end
