if ENV['REDIS_URL']
  $redis = Redis.new(url: ENV['REDIS_URL'])
else 
    $redis = Redis.new({
      host: ENV['REDIS_HOST'],
      port: ENV['REDIS_PORT'] || '6379'
    })
end