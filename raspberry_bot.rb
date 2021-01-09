#!/usr/bin/ruby

require './lib/telegram_api'
require './app/get_system_info'
require './app/post_office'
require './app/bot_commands'
require './app/message_handler'
require './app/monitoring'
require './app/settings'

class Bot
  include PostOffice
  include BotCommands
  include MessageHandler

  attr_accessor :settings, :states

  def initialize
    @settings, @methods, @states = Settings.settings
    @tg = TelegramApi.new(@settings['api_url'], @settings['token'])

    @methods['defined_commands'] = BotCommands.instance_methods.map(&:to_s)
    @methods['supported'] = MessageHandler.instance_methods.map(&:to_s)

    @mon = Monitoring.new(self)
    Thread.new { @mon.monitor }

    @off = false
    @run = true
    start_bot
  end

  def start_bot
    while @run
      updates = @tg.session('getUpdates', { 'timeout' => @settings['api_timeout'] })
      next if updates['result'].empty?

      updates['result'].each do |update|
        process_update(update)
      end
      @tg.session('getUpdates', { 'offset' => updates['result'].map { |update| update['update_id'] }.max + 1 })
    end
  end

  def process_update(hash)
    type = hash.keys[1]

    unautorized(hash) && return unless authorised?(hash[type]['from']['id'])
    unsupported(hash) && return unless message?(hash)

    send(message_type(hash[type]), hash[type]) if supported?(hash[type])
    unsupported(hash) unless supported?(hash[type])
  end

  def authorised?(user_id)
    @settings['users'].include?(user_id)
  end

  def unsupported(hash)
    send_message(hash[hash.keys[1]]['chat']['id'],
                 'Unsupported message type!')
  end

  def unautorized(hash)
    type = hash.keys[1]
    send_message(hash[type]['chat']['id'],
                 "User with id #{hash[type]['from']['id']} unautorised!")
  end

  def send_message(chat_id, text)
    @tg.session('sendMessage', { 'chat_id' => chat_id, 'text' => text })
  end
end

Bot.new
