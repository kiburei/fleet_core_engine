json.extract! marketplace_product, :id, :name, :description, :price, :category, :target_audience, :active, :featured, :tags, :image, :created_at, :updated_at
json.url marketplace_product_url(marketplace_product, format: :json)
json.image url_for(marketplace_product.image)
