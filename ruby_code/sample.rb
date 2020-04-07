require_relative './check_images'

# These keys no longer exist, and are just examples
AWS_ACCESS_KEY_ID = "AKIASKBZVVVIDIF6G76I"
AWS_ACCESS_SECRET_KEY = "YkCRCzadc0uZH/EbiMhP2cSIZjlTwqw/AKt68EH9"

API_URL = "https://api.neonlaw.net"

s3_bucket = "dade-systems-interview-question"

client = Aws::S3::Client.new(
  access_key_id: AWS_ACCESS_KEY_ID,
  secret_access_key: AWS_ACCESS_SECRET_KEY
)

valid_check_images = CheckImages.new(
  aws_s3_client: client,
  s3_bucket: s3_bucket,
  api_url: API_URL
).validate_images

puts valid_check_images.map(&:key)
