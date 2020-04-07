require 'aws-sdk-s3'

class CheckImages
  def initialize(aws_s3_client:, s3_bucket:, api_url:)
    @api_url = api_url
    @bucket = s3_bucket
    @client = aws_s3_client
  end

  def validate_images
    validated_check_images = []

    client.list_objects({ bucket: bucket }).contents.each do |object|
      key = object.key

      if valid_check?(key)
        validated_check_images << object
        puts "object s3://#{bucket}/#{key} is a valid check"
      else
        delete_image(key)
        puts "deleted object s3://#{bucket}/#{key}"
      end
    end

    return validated_check_images
  end

  private

  attr_reader :api_url, :bucket, :client

  def delete_image(key)
    client.delete_object({ bucket: bucket, key: key })
  end

  def valid_check?(key)
    api_response = post_image_to_api(key)
    parsed_body = JSON.parse!(api_response.body)
    return parsed_body["is_check"]
  end

  def post_image_to_api(key)
    bucket_string_io = client.get_object({ bucket: bucket, key: key }).body

    file_extension = key.split('.').last

    image_tempfile = Tempfile.new(['image', ".#{file_extension}"])
    image_tempfile.binmode
    image_tempfile.write(bucket_string_io.read)
    image_tempfile.rewind

    uri = URI.parse(api_url)

    request = Net::HTTP::Post.new(uri)

    form_data = [['image', image_tempfile]]

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    request.set_form form_data, 'multipart/form-data'
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end
end
