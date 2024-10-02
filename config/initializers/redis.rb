if ENV["RAILS_ENV"] == "production"
  redis_url = ENV["REDIS_URL"]
else
  redis_url = "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}/0"
end
Resque.redis = Redis.new(url: redis_url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })

# Resque.redis = Redis.new(:url => ENV['REDIS_URL'])

# Heroku RedisでRailsからRedisを使う場合
# $redis = Redis.new(url: ENV["REDIS_URL"])

#ActiveRecordが使えるように設定
Resque.after_fork = Proc.new { ActiveRecord::Base.establish_connection }
