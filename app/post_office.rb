module PostOffice
  MESSAGE_TYPES = %w[text animation audio document photo sticker video
                     video_note voice contact dice game poll venue location].freeze
  MESSAGE = %w[message edited_message].freeze

  def message?(update)
    MESSAGE.include?(update.keys[1])
  end

  def supported?(message)
    @methods['supported'].include?(message_type(message))
  end

  def bot_command?(message)
    message['entities'] ? message['entities'][0]['type'] == 'bot_command' : false
  end

  def message_type(message)
    (message.keys & MESSAGE_TYPES)[0]
  end
end
