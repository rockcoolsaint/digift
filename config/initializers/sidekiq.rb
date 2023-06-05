
if ENV['REDIS_URL']
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_URL'], network_timeout: 5 }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV['REDIS_URL'], network_timeout: 5 }
  end  
else
  Sidekiq.configure_server do |config|
    config.redis = {
      host: ENV['REDIS_HOST'],
      port: ENV['REDIS_PORT'] || '6379'
    }
  end
  
  Sidekiq.configure_client do |config|
    config.redis = {
      host: ENV['REDIS_HOST'],
      port: ENV['REDIS_PORT'] || '6379'
    }
  end
end