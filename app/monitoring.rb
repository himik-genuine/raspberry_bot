#!/usr/bin/ruby

class Monitoring
  include GetSystemInfo

  def initialize(bot)
    @bot = bot
  end

  def send_message(message)
    @bot.settings['users'].each { |user| @bot.message(user, message) }
  end

  def monitoring(comm)
    return set_thresholds(comm) unless %w[start stop].include?(comm)

    if comm == 'stop' && @bot.settings['monitoring']
      @bot.settings['monitoring'] = false
      'Monitoring module is stopped!'
    elsif comm == 'start' && !@bot.settings['monitoring']
      @bot.settings['monitoring'] = true
      Thread.new { monitor }
      'Monitoring module is started!'
    else
      "Monitoring module is already #{'started' if @bot.settings['monitoring']}#{'stopped' unless @bot.settings['monitoring']}!"
    end
  end

  def set_thresholds(comm)
    case comm.split[0]
    when 'temp'
      set_temp(comm)
    when 'mem'
      set_mem(comm)
    else
      'Command not recognized!'
    end
  end

  def set_temp(comm)
    if !comm.split[1].nil? && comm.split[1].match('^\d{1,3}$')
      return "#{comm.split[1]} is too high!" if comm.split[1].to_i > 101

      @bot.settings['cpu_temperature'] = comm.split[1].to_i
      "CPU themperature threshold is #{@bot.settings['cpu_temperature']} °C now."
    elsif !comm.split[1].nil? && comm.split[1] == 'disable'
      @bot.settings.delete('cpu_temperature')
      'CPU themperature monitoring disabled.'
    else
      'You must define temperature or "disable" after "/thresholds temp"!'
    end
  end

  def set_mem(comm)
    if !comm.split[1].nil? && comm.split[1].match('^\d{1,3}$')
      return "There can't be more than 100% ;o)" if comm.split[1].to_i > 100

      @bot.settings['used_memory'] = comm.split[1].to_i
      "Memory usage threshold is #{@bot.settings['used_memory']}% now."
    elsif !comm.split[1].nil? && comm.split[1] == 'disable'
      @bot.settings.delete('used_memory')
      'Memory usage monitoring disabled.'
    else
      'You must define percents or "disable" after "/thresholds mem"!'
    end
  end

  def monitor
    temp_sent = false
    mem_sent = false
    while @bot.settings['monitoring']
      temp_sent = check_temp(temp_sent) if @bot.settings['cpu_temperature']
      @bot.states['temperature_state'] = temp_sent == false
      mem_sent = check_mem(mem_sent) if @bot.settings['used_memory']
      @bot.states['used_memory_state'] = mem_sent == false
      sleep @bot.settings['monitor_update']
    end
  end

  def check_mem(mem_sent)
    mem = memory_info['percents_used']
    if mem > @bot.settings['used_memory'] && !mem_sent
      send_message("On \"#{@bot.settings['host']}\" #{mem}% memory used, wile treshold is #{@bot.settings['used_memory']}%!")
      mem_sent = true
    end
    if mem < (@bot.settings['used_memory'] - 5) && mem_sent
      send_message("On \"#{@bot.settings['host']}\" memory usage drropped to #{mem}%.")
      mem_sent = false
    end
    mem_sent
  end

  def check_temp(temp_sent)
    cpu = cpu_temp
    if cpu > @bot.settings['cpu_temperature'] && !temp_sent
      send_message("On \"#{@bot.settings['host']}\" CPU temperature hit #{cpu} °C, wile treshold is #{@bot.settings['cpu_temperature']} °C!")
      temp_sent = true
    end
    if cpu < (@bot.settings['cpu_temperature'] - 5) && temp_sent
      send_message("On \"#{@bot.settings['host']}\" CPU temperature drropped to #{cpu} °C.")
      temp_sent = false
    end
    temp_sent
  end
end
