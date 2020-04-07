require_relative '../check_images'

describe 'CheckImages' do
  let(:s3_bucket) { "images" }
  let(:api_url) { "http://localhost:5000" }

  subject do
    CheckImages.new(
      aws_s3_client: aws_s3_client,
      s3_bucket: s3_bucket,
      api_url: api_url
    )
  end

  context 'with invalid AWS credentials' do
    let(:aws_s3_client) do
      Aws::S3::Client.new(
        access_key_id: "fake",
        secret_access_key: "fake"
      )
    end

    it 'throws an Aws::S3::Errors::InvalidAccessKeyId error' do
      expect do
        subject.validate_images
      end.to raise_error Aws::S3::Errors::InvalidAccessKeyId
    end
  end

  context 'with valid AWS credentials' do
    let(:aws_s3_client) do
      Aws::S3::Client.new(stub_responses: true).tap do |client|
        client.create_bucket({ bucket: s3_bucket })
      end.tap do |client|
        client.stub_responses(
          :list_objects,
          { contents: [{ key: 'sample.jpg' }] }
        )
        client.stub_responses(
          :get_object,
          { body: File.open(image_filename) }
        )
      end
    end
    let(:object) { Aws::S3::Types::Object.new({ key: 'sample.jpg' }) }

    context 'and a valid check image' do
      let(:image_filename) { "#{__dir__}/../../training_data/check5.jpg" }

      it 'returns the valid check object' do
        expect(subject.validate_images).to eq [object]
      end
    end

    context 'and an invalid check image' do
      # This image is not a check because it is too small, please refer to the README.
      let(:image_filename) { "#{__dir__}/../../training_data/check1.jpeg" }
      before do
        aws_s3_client.stub_responses(
          :delete_object,
          true
        )
      end

      it 'returns an empty array' do
        expect(subject.validate_images).to eq []
      end
    end
  end
end
