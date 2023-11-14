class SteamAccountsController < ApplicationController
  before_action :set_steam_account, only: %i[edit update]
  def index
    @steam_accounts = SteamAccount.all
  end

  def new
    @steam_account = SteamAccount.new
  end

  def create
    @steam_account = SteamAccount.new(steam_account_params)
    if @steam_account.save
      flash[:notice] = 'Steam account was successfully added.'
      redirect_to steam_accounts_path 
    else
      render :new
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

  private

  def set_steam_account
    @steam_account = SteamAccount.find_by(id: params[:id])
  end

  def steam_account_params
    params.require(:steam_account).permit(:steam_id, :unique_name,:steam_web_api_key, :waxpeer_api_key, :csgoempire_api_key, :market_csgo_api_key)
  end
end
