require './lib/reply_markup_formatter'
require './lib/app_configurator'

class MessageSender
  attr_reader :bot
  attr_reader :text
  attr_reader :chat
  attr_reader :answers
  attr_reader :logger
  # atributo image_url para envio de imagens
  attr_reader :photo

  def initialize(options)
    @bot = options[:bot]
    @text = options[:text]
    @chat = options[:chat]
    @answers = options[:answers]
    # inicializa photo vazio se não for passado o parâmetro
    options[:photo] ? @photo = options[:photo] : @photo = []
    @logger = AppConfigurator.new.get_logger
  end

  def send
    if reply_markup
      bot.api.send_message(chat_id: chat.id, text: text, reply_markup: reply_markup)
    elsif @photo != []
      bot.api.send_photo(chat_id: chat.id, photo: Faraday::UploadIO.new(photo, 'image/jpeg'))
    else
      bot.api.send_message(chat_id: chat.id, text: text, parse_mode: 'HTML')
    end

    logger.debug "sending '#{text}' to #{chat.username}"
  end

  private

  def reply_markup
    # if answers
    #   ReplyMarkupFormatter.new(answers).get_markup
    # end
    return unless answers
    ReplyMarkupFormatter.new(answers).get_markup
  end
end
