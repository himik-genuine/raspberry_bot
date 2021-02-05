module GetSystemInfo
  def cpu_temp
    (File.read('/sys/class/thermal/thermal_zone0/temp').to_f / 1000).round(1)
  end

  def cpu_freq
    (File.read('/sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq').to_i / 1000).round(1)
  end

  def cpu_freq_max
    (File.read('/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq').to_i / 1000).round(1)
  end

  def cpu_freq_min
    (File.read('/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq').to_i / 1000).round(1)
  end

  def os_version
    os = Settings.read_cfg('/etc/os-release')
    "#{os['NAME'].gsub('"', '')} #{os['VERSION'].gsub('"', '')}"
  end

  def kernel_version
    File.read('/proc/version').split[2]
  end

  def kernel_arch
    `uname -m`
  end

  def load_average
    File.read('/proc/loadavg').split
  end

  def memory_info
    mem = IO.readlines('/proc/meminfo')
            .map(&:chomp)
    total = mem.select { |line| line.match?('MemTotal') }[0]
               .split[1].to_i / 1024
    avail = mem.select { |line| line.match?('MemAvailable') }[0]
               .split[1].to_i / 1024
    used = total - avail
    percents_used = used * 100 / total
    { 'total' => total, 'available' => avail, 'used' => used, 'percents_used' => percents_used }
  end

  def uptime
    uptm = File.read('/proc/uptime')
               .split('.')[0].to_i
    days = uptm / 86400
    hours = (uptm - 86400 * days) / 3600
    minutes = (uptm - (86400 * days + 3600 * hours)) / 60
    seconds = (uptm - (86400 * days + 3600 * hours + 60 * minutes))

    [days, hours, minutes, seconds]
  end

  def cpu_freqstat
    frq = File.read('/sys/devices/system/cpu/cpufreq/policy0/stats/time_in_state')
              .split("\n")
    cpu_time = frq.map { |line| line.split[1] }
                  .map(&:to_f)
    cpu_frq = frq.map { |line| line.split[0] }
                 .map(&:to_i)
    time_sum = cpu_time.sum
    percents = cpu_time.map { |time| (time * 100 / time_sum).round(2) }
    res = []

    frq.each_with_index do |_val, index|
      fq = cpu_frq[index] / 1000
      space = ' ' * (6 - percents[index].to_s.size)
      res << "#{' ' if fq < 1000}#{cpu_frq[index] / 1000} MGz: #{percents[index]}%#{space}- #{cpu_time[index].to_i}\n"
    end
    res.join
  end

  def summary
    curr_freq = cpu_freq
    memory = memory_info
    uptm = uptime
    monitoring = if @bot.settings['monitoring']
                   'Active'
                 else
                   'Disabled'
                 end
    one_m, five_m, fifteen_m, processes = load_average
    temp = @bot.settings['cpu_temperature'] || 'Disabled'
    mem = @bot.settings['used_memory'] || 'Disabled'
    text = "Bot on \"#{@bot.settings['host']}\"\n"
    text += "Bot download directory: #{@bot.settings['download_directory']}\n"
    text += "\nOS: #{os_version}\n"
    text += "Kernel: #{kernel_version}\n"
    text += "Kernel architecture: #{kernel_arch}\n"
    text += "Processes running: #{processes.split('/')[0]} of #{processes.split('/')[1]} total.\n"
    text += "Load average: #{one_m} #{five_m} #{fifteen_m}\n"
    text += "\nMonitoring module: #{monitoring}\n"
    text += "CPU temperature threshold: #{temp}#{' °C' if @bot.settings['cpu_temperature']}\n" if @bot.settings['monitoring']
    text += "Memory usage threshold: #{mem}#{'%' if @bot.settings['used_memory']}\n" if @bot.settings['monitoring']
    if @bot.settings['monitoring']
      text += "\nCPU temperature status: #{'OK' if @bot.states['temperature_state']}#{'Problem!' unless @bot.states['temperature_state']}\n" if @bot.settings['cpu_temperature']
      text += "Memory usage status: #{'OK' if @bot.states['used_memory_state']}#{'Problem!' unless @bot.states['used_memory_state']}\n" if @bot.settings['used_memory']
    end
    text += "\nMaximum CPU frequency: #{cpu_freq_max} MHz\n"
    text += "Minimum CPU frequency: #{cpu_freq_min} MHz\n"
    text += "Current CPU frequency: #{curr_freq} MHz\n"
    text += "\nCurrent CPU temperature: #{cpu_temp} °C\n"
    text += "\nTotal memory: #{memory['total']} Mb\n"
    text += "Available memory: #{memory['available']} Mb\n"
    text += "Used memory: #{memory['used']} Mb\n"
    text += "#{memory['percents_used']}% of memory used.\n"
    text += "\nUptime: #{uptm[0]} day#{'s' if uptm[0] > 1 || uptm[0] == 0} #{uptm[1]} h #{uptm[2]} min #{uptm[3]} sec\n"
    text
  end
end
