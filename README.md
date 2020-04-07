# Dade Systems Interview Challenge

## Problem

1. Create a github repo/repos to track all code
2. Using Docker create a Dockerfile with Sagemaker
3. Create an http endpoint to send the image to see the response results.
  Should return { is_check: true } or { is_check: false }
4. In Ruby write some code that calls that API from images in a s3 bucket. At
  least one of the images in the s3 bucket should not be a check. If it is not
  a check. It should delete that image from the s3 bucket.

## Determining a check

> After talking with the interviewer, I swapped out using Sagemaker with
> Tesseract due to the fact that Sagemaker requires an AWS account with GPU
> access.

To determine whether or not an image a check, we perform the following
analysis of an uploaded JPG or PNG check image.

1. Convert the Check Image to a Black and White image, saving just the black
  text.

Checks that are attached to bank accounts in the US must have blank magnetic
ink printed numbers to comply with the MICR standards set forth by the
Federal Reserve. As a result, most checks have blank ink printed on them.
When new images are uploaded to the API, they are processed with OpenCV to
filter out only the black before being sent to OCR.

2. Send the image to Tesseract for OCR processing

Tesseract is a common OCR library and the one used by Dade Systems. After the
images are processed by OpenCV, which removes any background filters, they
are then sent to Tesseract to parse the text.

3. Determine if the text and image specifications are indeed a valid check.

We look for the following characteristics to determine if a check is a check.

* The image must be longer than it is taller.
* The image must contain a minimum pixel dimensions, this guarantees a more
  accurate read with Tesseract.
* The parsed text from Tesseract must contain at least two of the words "Pay",
  "Order", "Dollars", "Memo", and "Date", which are on all checks.

## Building and Running the API

```bash
cd inference_data
docker build -t api .
docker run -p 5000:5000 api
```

Now you can navigate to the API on your machine at `localhost:5000`. To
determine whether or not the API is up, you can visit `localhost:5000/health`
in your browser, which serves as a healthcheck. This healthcheck can be used
to deploy the API in production environments such as AWS ELB, which requires
a healthcheck like this endpoint for the targets to redirect to.

## Testing the API with CURL

You can test the API with Curl by using the images in the `training_data`
folder. After opening a terminal session in this folder and starting the API
with the steps above you can then try:

```bash
curl  -F image=@$(pwd)/training_data/check10.jpg http://127.0.0.1:5000
```

to then see if the image is a check or not.

## Iterating through an S3 bucket of images to determine if each is a check

If you have a folder of images on S3, you can test whether or not each image
is a check by using the `CheckImage` class defined in
`./ruby_code/check_images.rb`

This class can be initialized with an
[AWS::S3::Client](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html),
the name of an S3 bucket containing check images, and the url of the API to
check if each image is a check or not.

```ruby
client = Aws::S3::Client.new(
  access_key_id: "Your AWS Access Key ID",
  secret_access_key: "Your AWS Secret Access Key"
)

CheckImages.new(
  aws_s3_client: client,
  s3_bucket: "check_images",
  api_url: "https://www.dadesystems.com/validate_check_images"
).validate_images
```

This instantiated class and the `validate_images` method will check each
object in the bucket if it is a check or not, and if it isn't it will delete
the object from the S3 bucket.

> A sample of running this code exists in the `ruby_code/sample.rb` file.

## Tests of the Ruby Code

You can see tests for this class in the `ruby_code/spec` folder, you can run
these tests with these instructions from the `ruby_code` folder:

```
bundle install
bundle exec rspec spec
```

> You must start the API Docker container as detailed above for the tests to
> work. The API_URL is defined on Line 5 of the `check_images_spec.rb`
