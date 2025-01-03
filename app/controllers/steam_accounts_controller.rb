class SteamAccountsController < ApplicationController
  require 'httparty'
  before_action :set_steam_account, only: %i[edit update destroy show_api_keys edit_api_keys read_ma_file delete_ma_file]
  after_action :set_steam_account_filters, only: %i[create]
  
  def index
    @steam_accounts = SteamAccount.where(user_id: current_user.id).includes(:proxy).paginate(page: params[:page], per_page: 10)
  end

  def new
    @steam_account = SteamAccount.new
  end

  def create
    @steam_account = SteamAccount.new(steam_account_params)
    @steam_account.user_id = current_user.id
    if @steam_account.save
      if @steam_account.valid_account
        base_url = ENV['NODE_TOGGLE_SERVICE_URL']
        url = "#{base_url}/toggleStatusService"
        params = { id: @steam_account.id }
        response = HTTParty.post(url, query: params)
        if response['success'] == 'true'
          response_message.present? ? flash[:alert] = "Steam Account Successfully created but " + response_message : flash[:notice] = 'Steam Account Successfully created.'
        else
          flash[:alert] = response['message']
        end
      else
        flash[:alert] = "Steam Account successfully created but " + response_message if response_message.present?
      end
      redirect_to steam_accounts_path
    else
      flash[:alert] = "#{@steam_account.errors.full_messages[0]}"
      redirect_to new_steam_account_path
    end
  end

  def edit; end

  def update
    if @steam_account.update(steam_account_params)
      flash[:notice] = 'Steam account was successfully updated.'
      redirect_to steam_accounts_path
    else
      render :edit
    end
  end

  def destroy
    logout_steam
    if @steam_account.destroy
      redirect_to steam_accounts_path, notice: 'Steam account was successfully deleted.'
    end
  end

  def show_api_keys
    @success = check_password?
    if current_user.discord_bot_token.present? && current_user.discord_channel_id.present?
      @success ? notify_discord("#{current_user.email} successfully accessed API keys") :  notify_discord("#{current_user.email} tried to access API keys")
    end
    respond_to do |format|
      format.js
    end
  end

  def edit_api_keys
    @success = check_password?
    if current_user.discord_bot_token.present? && current_user.discord_channel_id.present?
      @success ? notify_discord("#{current_user.email} successfully accessed API keys") :  notify_discord("#{current_user.email} tried to edit API keys")
    end
    respond_to do |format|
      format.js
    end
  end

  def read_ma_file
    return unless params[:steam_account][:ma_file].present?

    file_content = File.read(params[:steam_account][:ma_file].path)
    data = JSON.parse(file_content)
    if data.present?
      account_name = data['account_name']
      password = params[:steam_account][:steam_password]
      identity_secret = data['identity_secret']
      shared_secret = data['shared_secret']
      if account_name.present? && password.present? && identity_secret.present? && shared_secret.present?
        params[:steam_account][:steam_account_name] = account_name
        params[:steam_account][:steam_shared_secret] = shared_secret
        params[:steam_account][:steam_identity_secret] = identity_secret

        if @steam_account.update(steam_account_params) && @steam_account.valid_account
          base_url = ENV['NODE_TOGGLE_SERVICE_URL']

          url = "#{base_url}/startsteamservice"
          params = { id: @steam_account.id }

          response = HTTParty.post(url, query: params)
          if response['success'] == 'true'
            flash[:notice] = 'Steam account was successfully Logged In.'
          else
            remove_ma_file_data
            flash[:alert] = 'Steam Login failed please login again'
          end
        else
          flash[:alert] = 'Steam account not updated.'
        end
      end
    end
  end

  def delete_ma_file
    if @steam_account.ma_file.present?
      logout_steam
      remove_ma_file_data
    end
    redirect_to steam_accounts_path
  end

  def logout_steam
    if @steam_account.valid_account
      base_url = ENV['NODE_TOGGLE_SERVICE_URL']
      url = "#{base_url}/logOutSteam"
      params = { id: @steam_account.id }
      HTTParty.post(url, query: params)
    end
  end

  private

  def remove_ma_file_data
    @steam_account.ma_file.purge
    @steam_account.update(steam_account_name: nil, steam_password: nil, steam_identity_secret: nil, steam_shared_secret: nil)
  end

  def check_password?
    current_user.valid_password?(params[:current_password])
  end

  def set_steam_account
    @steam_account = SteamAccount.find_by(id: params[:id])
  end


  def steam_account_params
    params.require(:steam_account).permit(:steam_id, :unique_name, :steam_web_api_key,
      :waxpeer_api_key, :csgoempire_api_key,
      :market_csgo_api_key, :ma_file, :steam_password,
      :steam_account_name, :steam_shared_secret, :steam_identity_secret
    )
  end

  def set_steam_account_filters
    if @steam_account.present?
      TradeService.create(steam_account_id: @steam_account.id)
      SellingFilter.create(steam_account_id: @steam_account.id)
      BuyingFilter.create(steam_account_id: @steam_account.id)
    end
  end

  def notify_discord(message)
    begin
      bot = Discordrb::Bot.new(token: current_user.discord_bot_token)
      channel = bot.channel(current_user.discord_channel_id)
      channel.send_message(message)
    rescue StandardError => e
      @notification = current_user.notifications.create(title: "Discord Login", body: "User is unauthorized", notification_type: "Login")
    end
  end

  def response_message
    message = []
    message << 'CSGOEmpire API Key is invalid.' if !@steam_account.csgoempire_api_key.present? && steam_account_params['csgoempire_api_key'].present?
    message << 'WAXPEER API Key is invalid.' if !@steam_account.waxpeer_api_key.present? && steam_account_params['waxpeer_api_key'].present?
    message << 'Market.CSGO API Key is invalid.' if !@steam_account.market_csgo_api_key.present? && steam_account_params['market_csgo_api_key'].present?
    message.join(' ')
  end
end
