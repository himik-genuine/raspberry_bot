module Settings
  def self.settings
    @settings = read_cfg('bot.cfg')
    @settings['users'] = users
    @settings['cpu_temperature'] = i_or_false(@settings['cpu_temperature']) if @settings['cpu_temperature']
    @settings['used_memory'] = i_or_false(@settings['used_memory']) if @settings['used_memory']
    @settings['monitoring'] = true_false(@settings['monitoring'])
    @settings['commands_timeout'] = i_or_false(@settings['commands_timeout'])
    @settings['messages_limit'] = i_or_false(@settings['messages_limit'])
    @settings['monitor_update'] = i_or_false(@settings['monitor_update'])
    @settings['api_timeout'] = i_or_false(@settings['api_timeout'])
    @settings['host'] = `hostname`.chomp unless @settings['host']
    @methods = { 'user_commands' => read_commands }
    @methods['user_commands_keys'] = @methods['user_commands'].keys
    if (%w[/help /monitoring /shell /thresholds] - @methods['user_commands_keys']).size < 4
      puts 'You can\'t override commands "/help", "/monitoring", "/thresholds" or "/shell", please redifine it!'
      abort
    end
    @states = { 'temperature_state' => true }
    @states['used_memory_state'] = true
    [@settings, @methods, @states]
  end

  def self.save_settings
    array = @settings.map do |key, value|
      value = value.join(', ') if key == 'users'
      "#{key} = #{value}\n"
    end.join
    File.open('bot.cfg', 'w') { |file| file.puts array }
  end

  def self.read_cfg(file)
    IO.readlines(file)
      .reject { |line| line.strip[0] == '#' }
      .map(&:chomp)
      .reject { |line| line == '' }
      .map { |line| line.split('#')[0] }
      .map { |line| line.split('=') }
      .map { |line| line.map(&:strip) }
      .to_h
  end

  def self.read_commands
    IO.readlines('user_commands.cfg')
      .reject { |line| line.strip[0] == '#' }
      .map(&:chomp)
      .reject { |line| line == '' }
      .map { |line| line.split('#') }
      .map { |line| line.map(&:strip) }
      .to_h
  end

  def self.users
    @settings['users'].gsub(', ', ',')
                      .split(',')
                      .map(&:to_i)
  end

  def self.i_or_false(value)
    if value.match('^\d{1,}$')
      value.to_i
    else
      true_false(value)
    end
  end

  def self.true_false(value)
    value == 'true'
  end
end
