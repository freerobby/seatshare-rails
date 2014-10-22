# Configure the S3 Gem
# These are required for ticket file uploading.
if ENV['SEATSHARE_S3_BUCKET'].nil? || ENV['SEATSHARE_S3_BUCKET'].nil? || ENV['SEATSHARE_S3_BUCKET'].nil? || ENV['SEATSHARE_S3_PUBLIC'].nil?
  Rails.logger.warn "S3 configuration is not present!"
end

AWS.config(
  access_key_id:     ENV['SEATSHARE_S3_KEY'],
  secret_access_key: ENV['SEATSHARE_S3_SECRET']
)