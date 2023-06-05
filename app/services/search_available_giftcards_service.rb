class SearchAvailableGiftcardsService
  def initialize(response, search_query=nil, min_price=nil, max_price=nil, category=nil)
    @harmonized_response = response
    @search_query = search_query
    @min_price = min_price
    @max_price = max_price
    @category = category
  end

  def call
    # if @search_query.present?
    res = Concurrent::Future.execute do
      if @search_query.present?
        @harmonized_response = @harmonized_response.select do |item|
          matcher(@search_query, item)
        end
      end

      # if price.present?
      if @min_price.present? && @max_price.present?
        exchange_rate = Fx.get_rate
        @harmonized_response = @harmonized_response.select do |item|
          if item.with_indifferent_access[:currency] === "USD"
            item_prices = item.with_indifferent_access[:value].split(',').map{ |price| price.to_i * exchange_rate }
          else
            item_prices = item.with_indifferent_access[:value].split(',').map(&:to_i)
          end
          !item_prices.find { |price| price.between?(@min_price.to_i, @max_price.to_i)}.nil?
        end
      end

      if @category.present?
        category_array = @category.split(',').map { |value| value.to_i }
        item_ids = []
        CategoryItem.find_each do |item|
          if item.try(:is_active) && category_array.include?(item.try(:category_id).try(:to_i)) 
            item_ids << item.try(:item_id) unless item_ids.include?(item.try(:item_id))
          end
        end
        @harmonized_response = @harmonized_response.select do |item|
          if item_ids.include?(item.with_indifferent_access[:code])
            item
          end
        end

      end
      @harmonized_response
    end
    res.value!
  end

  def matcher(search_query, item)
    !(/#{search_query}/i.match(item.with_indifferent_access["caption"])).nil? ||
    !(/#{search_query}/i.match(item.with_indifferent_access["captionLower"])).nil? ||
    !(/#{search_query}/i.match(item.with_indifferent_access["desc"])).nil? ||
    !(/#{search_query}/i.match(item.with_indifferent_access["domain"])).nil? ||
    !(/#{search_query}/i.match(item.with_indifferent_access["logo"])).nil?
  end

  def filter_by_price

  end
end