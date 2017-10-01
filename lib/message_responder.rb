require './models/user'
require './lib/message_sender'
require './lib/app_configurator'
require 'pry'

class MessageResponder
  attr_reader :message
  attr_reader :bot
  attr_reader :user
  # cria atributo username para guardar o username daquele uid
  attr_reader :username
  # cria atribute logger para mandar para o log de debug
  attr_reader :logger

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    # inicia o username. Se o uid ainda nao possui um username, atribui [] como
    # de valor do username.
    @username = get_username(message.from.id)
    # @user = User.find_or_create_by(uid: message.from.id)
    # inicia o logger
    @logger = AppConfigurator.new.get_logger
  end

  def respond
    # recebe uma regex e salva no banco associada a uma uid
    # DONE: ele salva varios usernames pra mesma uid. Checar se a UID ja possui
    # username associada;
    # TODO: perguntar se o usuario quer sobrescrever ou nao.
    on /^\/start (.+)/ do |arg|
      logger.debug "O username enviado pelo usuário #{message.from.id} foi: #{arg}"

      return(
              logger.debug "O uid #{message.from.id} já possui o username #{@username} registrado."
              answer_with_message "Você já possui o username #{@username} registrado!"
      ) unless !@username

      @username = arg

      set_username(message.from.id, @username)
      logger.debug "O uid #{message.from.id} agora possui o username #{@username}."
      answer_with_message "Seu username agora é #{@username}!"
    end

    # caso o usuario digite /start sem argumentos, retorna
    # um erro.
    # on /^\/start/ do
    #   binding.pry
    #   logger.debug "O usuario #{message.from.id} nao digitou um username!"
    #   answer_with_message "Digita um username, seu arrombado!"
    # end

    on /^\/all/ do
      answer_with_all
    end

    # envia mensagem de surrender seguida de uma imagem
    on /^\/ff/ do
      answer_with_surrender(message.from.id)
    end

    # apenas para fins de debug
    on /^\/akshuda/ do
      binding.pry
    end

    # on /^\/stop/ do
    #   answer_with_farewell_message
    # end
  end

  private

  def on regex, &block
    regex =~ message.text

    if $~
      case block.arity
      when 0
        yield
      when 1
        yield $1
      when 2
        yield $1, $2
      end
    end
  end

  def answer_with_greeting_message
    answer_with_message I18n.t('greeting_message')
  end

  def answer_with_farewell_message
    answer_with_message I18n.t('farewell_message')
  end

  # metodo para atribuir o username de determinada uid. Retorna [] se o uid
  # chamada ainda nao possui username atribuido, ou o username caso possua.
  def get_username(uid)
    User.where(uid: uid) == [] ? nil : User.where(uid: uid)[0][:username]
  end

  # metodo para salvar um novo uid e username no banco
  def set_username(uid, username)
    @user = User.where(uid: uid).find_or_create_by(username: username)
  end

  # metodo para buscar no banco todos os usuarios.
  # Retorna um User::ActiveRecord_Relation
  def get_all_users
    User.order(:id)
  end

  # metodo que atribui todos os membros da tabela users para um objeto, parseia
  # todos os uids e usernames em uma string e termina enviando uma mensagem com
  # essa string de usernames.
  def answer_with_all
    chat_members = get_all_users
    i = 0
    arroba_channel = ''

    while chat_members[i]
      arroba_channel << "<a href=\"tg://user?id=#{chat_members[i][:uid]}\">#{chat_members[i][:username]}</a> "
      i += 1
    end

    answer_with_message "Acorda ae cambada! #{arroba_channel}"
  end

  # enviado quando alguem manda /ff. Envia uma mensagem de surrender e uma imagem da tela de derrota do LoL
  def answer_with_surrender(uid)
    loser = get_username(uid)
    ff_message = "#{loser} concordou com uma rendição: 1 voto a favor, 0 votos contra"
    answer_with_message(ff_message)
    defeat_jpg = "/Users/caue/Pictures/Outras/derrota.jpg"
    answer_with_image(defeat_jpg)
  end

  def answer_with_message(text)
    MessageSender.new(bot: bot, chat: message.chat, text: text).send
  end

  # envia uma foto para o chat
  def answer_with_image(image_url)
    MessageSender.new(bot: bot, chat: message.chat, photo: image_url).send
  end
end
