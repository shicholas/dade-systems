from logging import basicConfig, getLogger, INFO
from flask import Flask, request
from json import dumps
from pytesseract import image_to_data, image_to_string
import numpy as np
from PIL import Image
from os import path
from werkzeug.utils import secure_filename
import cv2


app = Flask(__name__)

basicConfig(level=INFO)
logger = getLogger("check_image_api")

UPLOAD_FOLDER = "./uploads"
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg"}

app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route("/", methods=["POST"])
def index():
    image = request.files["image"]

    if "image" not in request.files:
        logger.info("no image file")
        return dumps({"is_check": False})

    if image.filename == "":
        logger.info("no file attached")
        return dumps({"is_check": False})
    if image and allowed_file(image.filename):
        filename = secure_filename(image.filename)
        full_path = path.join(app.config["UPLOAD_FOLDER"], filename)
        image.save(full_path)

        img = cv2.imread(full_path)

        # # Convert BGR to HSV
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

        # # define range of black color in HSV
        lower_val = np.array([0, 0, 0])
        upper_val = np.array([179, 255, 200])

        # Apply a mask to only get black text from the image
        mask = cv2.inRange(hsv, lower_val, upper_val)
        res2 = cv2.bitwise_not(mask)

        # Save just the black text
        cv2.imwrite(full_path, res2)

        processed_image = Image.open(full_path)

        width, height = processed_image.size
        processed_text = image_to_string(processed_image)

        is_check = determine_check(processed_text, width, height)

        return dumps({"is_check": is_check,})

    logger.info("Processing an unexpected image.")
    return dumps({"is_check": False})


@app.route("/health", methods=["GET"])
def health_check():
    return dumps({"healthy": True})


def determine_check(processed_text, width, height):
    if height > width:
        logger.info("A check is twice as long as it is tall. This is not a check.")
        return False
    if (width < 300) or (height < 300):
        logger.info("The image resolution is too small to tell.")
        return False
    lower_case_text = processed_text.lower()
    logger.info(lower_case_text)
    check_matches = 0
    if "pay" in lower_case_text:
        check_matches += 1
    if "order" in lower_case_text:
        check_matches += 1
    if "dollars" in lower_case_text:
        check_matches += 1
    if "date" in lower_case_text:
        check_matches += 1
    if "memo" in lower_case_text:
        check_matches += 1
    if check_matches >= 2:
        logger.info("The image matched enough words that are on every check.")
        return True
    return False


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
