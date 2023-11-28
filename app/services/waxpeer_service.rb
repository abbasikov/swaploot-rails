class WaxpeerService
  include HTTParty

  def initialize(current_user)
    @active_steam_account = current_user.active_steam_account
    @params = {
      api: @active_steam_account&.waxpeer_api_key
    }
  end

  def fetch_sold_items
    return [] if waxpeer_api_key_not_found?

    res = self.class.post(WAXPEER_BASE_URL + '/my-history', query: @params)
    item_sold = []
    return item_sold unless res['success']

    if res['data'].present?
      res['data']['trades'].each do |trade|
        item_sold << trade if trade['action'] == 'sell'
      end
    end
    item_sold
  end

  def fetch_item_listed_for_sale
    return [] if waxpeer_api_key_not_found?

    res = self.class.get(WAXPEER_BASE_URL + '/list-items-steam', query: @params)
    res['items'].present? ? res['items'] : []
  end

  def fetch_balance
    return [] if waxpeer_api_key_not_found?

    res = self.class.get(WAXPEER_BASE_URL + '/user', query: @params)
    res['user'].present? ? res['user']['wallet'].to_f / 1000 : 0
  end

  def remove_item(item_id)
    return [] if waxpeer_api_key_not_found?

    res = self.class.get("#{BASE_URL}/remove-items", query: @params.merge(id: item_id))
    res['removed'].count&.positive?
  end

  def waxpeer_api_key_not_found?
    @active_steam_account&.waxpeer_api_key.blank?
  end
end
