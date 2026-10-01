#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    grabberDeviceID = 1;
    grabber.setDeviceID(grabberDeviceID);
    grabber.listDevices();
    
    if(!grabber.initGrabber(1080, 1920)){
        ofLogError() << "Video grabber initialization failed!";
    }
    grabber.listDevices();
    
    ofSetFrameRate(50);
    firstRun = true;
    isRecording = false;
    addFrame =  0;
    ofSetOrientation(OF_ORIENTATION_DEFAULT); // Set to vertical if supported
    
    imageArray.reserve(ARRAYMAX); // Preallocate memory for frames
    
    // Retrieve aspect ratios
    cameraAspectRatio = grabber.getWidth() / grabber.getHeight();
    screenAspectRatio = ofGetWidth() / ofGetHeight();
    
    // Calculate the maximum height as 90% of the screen height
    float maxHeight = ofGetHeight() * 0.65;
    
    // Determine the scaling factor based on the maximum allowable height
    scale = maxHeight / grabber.getHeight();  // Start with scaling to the maximum height
    scaledWidth = grabber.getWidth() * scale;
    scaledHeight = grabber.getHeight() * scale;
    
    // If scaling to maximum height makes the width too large, adjust based on width
    if (scaledWidth > ofGetWidth()) {
        scale = ofGetWidth() / grabber.getWidth();  // Scale based on width to fit the screen
        scaledWidth = grabber.getWidth() * scale;
        scaledHeight = grabber.getHeight() * scale;
    }
    
    // Position the image centered horizontally and vertically
    x = (ofGetWidth() - scaledWidth) / 2;  // Center horizontally
    y = (ofGetHeight() - scaledHeight) / 2;  // Center vertically
    
    // In cases where the scaled width is wider than the screen
    if (scaledWidth > ofGetWidth()) {
        x = -(scaledWidth - ofGetWidth()) / 2;  // Negative X to center the oversized image
    }
    
    maintextFont.load("gui_resources/Gaultier-Regular.ttf", 50);
    giantCounterFont.load("gui_resources/Gaultier-Regular.ttf", 300);
    textYPosition = y / 2; // Center text in the space above the camera feed
    
    
    
    operationMode = MODE_RECORD_READY;
    ofSetLogLevel(OF_LOG_VERBOSE);
    ofLogVerbose("Current cam info") << "Cam width: " + ofToString(grabber.getWidth()) << " Cam height: " + ofToString(grabber.getHeight()) << " Screen width: " <<ofGetWidth() << " Screen height: " << ofGetHeight() << " Scale: " << scale << " Scaled width: " << scaledWidth << " Scaled height: " << scaledHeight;
    
    setupButtons();
    
    
}

//--------------------------------------------------------------
void ofApp::update(){
    grabber.update();
    if (isRecording) {
        if (grabber.isFrameNew()) {
            if (addFrame >= ARRAYMAX) {
                isRecording = false;
                firstRun = false;
                ofLogNotice() << "Recording Stopped";
                addFrame = 0;
                frameToPlay = 0;
                operationMode = MODE_PLAYBACK;
                
            } else {
                ofPixels flippedPixels = grabber.getPixels();
                flippedPixels.mirror(false, true); // Flip pixels horizontally
                imageArray.emplace_back(flippedPixels);
                ofLogNotice() << "Frame " << addFrame + 1 << " added";
                addFrame++;
                frameToPlay = 0;
            }
        }
    }
    
    if (isCountingDown) {
        int currentTime = ofGetElapsedTimeMillis();
        int elapsedTime = currentTime - startTime;
        
        // Check if countdown is complete
        if (elapsedTime >= countdownTime) {
            isCountingDown = false;
            startRecording(); // Call the recording function when countdown ends
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofSetBackgroundColor(127);
    string text;
    switch (operationMode) {
        case MODE_RECORD_READY:
             text = "Double tap to start";
            maintextFont.drawString(text, (ofGetWidth() - maintextFont.stringWidth(text)) / 2, maintextFont.stringHeight(text) *4);
            ofPushMatrix();
            ofTranslate(x + scaledWidth, y);
            ofScale(-1, 1);
            grabber.draw(0, 0, scaledWidth, scaledHeight);
            ofPopMatrix();
            break;
        case MODE_RECORDING:
            text = "Recording";
            maintextFont.drawString(text, (ofGetWidth() - maintextFont.stringWidth(text)) / 2, maintextFont.stringHeight(text) *4);
            
            ofPushMatrix();
            ofTranslate(x + scaledWidth, y);
            ofScale(-1, 1);
            grabber.draw(0, 0, scaledWidth, scaledHeight);
            ofPopMatrix();
            break;
        case MODE_PLAYBACK:
             text = "Drag left and right to scroll";
            maintextFont.drawString(text, (ofGetWidth() - maintextFont.stringWidth(text)) / 2, maintextFont.stringHeight(text) *4);
            ofPushMatrix();
            ofTranslate(x + scaledWidth, y); // Shift the pivot to the right side of the image
            ofScale(-1, 1); // Flip horizontally
            imageArray[frameToPlay].draw(0, 0, scaledWidth, scaledHeight);
            ofPopMatrix();

            break;
        case MODE_COUNTING_DOWN:
            ofPushMatrix();
            ofTranslate(x + scaledWidth, y); // Shift the pivot to the right side of the image
            ofScale(-1, 1); // Flip horizontally
            grabber.draw(0, 0, scaledWidth, scaledHeight);
            ofPopMatrix();
            
            int currentTime = ofGetElapsedTimeMillis();
            int elapsedTime = currentTime - startTime;
            int remainingTime = countdownTime - elapsedTime;
            int currentSecond = (remainingTime / 1000) + 1; // Calculate current second
            
            // Show the countdown number only at the start of each second and for 300 milliseconds
            if (remainingTime % 1000 <= 700 && currentSecond != lastSecondShown) {
                lastSecondShown = currentSecond; // Update the last shown second
                string countdownString = ofToString(currentSecond);
                ofPushStyle();
                ofSetColor(255, 0, 0);
                giantCounterFont.drawString(countdownString, (scaledWidth - giantCounterFont.stringWidth(countdownString)) / 2, (scaledHeight - giantCounterFont.stringHeight(countdownString)) / 2); // Draw the countdown number
                ofPopStyle();
          
            }
            
            break;
    }

}

//--------------------------------------------------------------
void ofApp::exit(){
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    if (!isRecording && !imageArray.empty()) {
         // Map touch coordinates to frame index based on orientation
         float touchMapped;
         if (currentOrientation == OF_ORIENTATION_DEFAULT || currentOrientation == OF_ORIENTATION_180) {
             touchMapped = ofMap(touch.y, ofGetHeight(), 0, 0, ARRAYMAX);
         } else {
             touchMapped = ofMap(touch.x, ofGetWidth(), 0, 0, ARRAYMAX);
         }
         frameToPlay = int(touchMapped);
         ofLogNotice() << "Frame to Play: " << frameToPlay;
     }
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    if (!isRecording && !imageArray.empty()) {
         // Map touch coordinates to frame index based on orientation
         float touchMapped;
         if (currentOrientation == OF_ORIENTATION_DEFAULT || currentOrientation == OF_ORIENTATION_180) {
             touchMapped = ofMap(touch.y, ofGetHeight(), 0, 0, ARRAYMAX);
         } else {
             touchMapped = ofMap(touch.x, ofGetWidth(), 0, 0, ARRAYMAX);
         }
         frameToPlay = int(touchMapped);
         ofLogNotice() << "Frame to Play: " << frameToPlay;
     }
}



//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    
}

//------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    ofLogVerbose() << "Device orientation changed to " << newOrientation;
    ///setupButtons();
    // Retrieve aspect ratios
    cameraAspectRatio = grabber.getWidth() / grabber.getHeight();
    screenAspectRatio = ofGetWidth() / ofGetHeight();
    
    // Calculate the maximum height as 90% of the screen height
    float maxHeight = ofGetHeight() * 0.9;
    
    // Determine the scaling factor based on the maximum allowable height
    scale = maxHeight / grabber.getHeight();  // Start with scaling to the maximum height
    scaledWidth = grabber.getWidth() * scale;
    scaledHeight = grabber.getHeight() * scale;
    
    // If scaling to maximum height makes the width too large, adjust based on width
    if (scaledWidth > ofGetWidth()) {
        scale = ofGetWidth() / grabber.getWidth();  // Scale based on width to fit the screen
        scaledWidth = grabber.getWidth() * scale;
        scaledHeight = grabber.getHeight() * scale;
    }
    
    // Position the image centered horizontally and vertically
    x = (ofGetWidth() - scaledWidth) / 2;  // Center horizontally
    y = (ofGetHeight() - scaledHeight) / 2;  // Center vertically
    
    // In cases where the scaled width is wider than the screen
    if (scaledWidth > ofGetWidth()) {
        x = -(scaledWidth - ofGetWidth()) / 2;  // Negative X to center the oversized image
    }
}


void ofApp::setupButtons() {
    ofOrientation currentOrientation = ofGetOrientation();
    //ofOrientation currentOrientation =  OF_ORIENTATION_DEFAULT;
    float buttonWidth = ofGetWidth() / 9;
    float buttonYPos, buttonXPos;
    
    // Check orientation to determine positioning
    if (currentOrientation == OF_ORIENTATION_DEFAULT || currentOrientation == OF_ORIENTATION_180) {
        buttonWidth = ofGetWidth() / 9;
        // Portrait or upside-down: Buttons at the bottom
        buttonYPos = ofGetHeight() - (buttonWidth * 2); // Single row at bottom
        buttonXPos = buttonWidth; // Starting position for X
    } else {
        buttonWidth = ofGetHeight() / 9;
        // Landscape left or right: Buttons down the side
        buttonYPos = buttonWidth; // Starting position for Y
        buttonXPos = ofGetWidth() - (buttonWidth * 2); // All buttons aligned to the right side
    }
    
    // Setup buttons with dynamic positioning
    switchCameraButton.setPath("button_icons/switch_cam_icon.png");
    switchCameraButton.buttonMessage = "SWITCH_CAM";
    switchCameraButton.buttonLabel = "Switch cam";
    if (currentOrientation == OF_ORIENTATION_DEFAULT || currentOrientation == OF_ORIENTATION_180) {
        switchCameraButton.set(buttonXPos, buttonYPos, buttonWidth, buttonWidth);
    } else {
        switchCameraButton.set(buttonXPos, buttonYPos, buttonWidth, buttonWidth);
        buttonYPos += buttonWidth; // Increment Y position for the next button
    }
    
    ofLog(OF_LOG_VERBOSE) << "switchCameraButton X pos: " << buttonXPos << " Y pos: " << buttonYPos << " Width: " << buttonWidth;
    
    
    
    fiveSecondDelayButton.setPath("button_icons/5_sec_timer_icon.png");
    fiveSecondDelayButton.buttonMessage = "5_SEC_DELAY";
    fiveSecondDelayButton.buttonLabel = "5 second delay";
    if (currentOrientation == OF_ORIENTATION_DEFAULT || currentOrientation == OF_ORIENTATION_180) {
        fiveSecondDelayButton.set(buttonXPos * 3, buttonYPos, buttonWidth, buttonWidth);
    } else {
        fiveSecondDelayButton.set(buttonXPos * 3, buttonYPos, buttonWidth, buttonWidth);
        buttonYPos += buttonWidth; // Increment Y position for the next button
    }
    ofLog(OF_LOG_VERBOSE) << "fiveSecondDelayButton X pos: " << buttonXPos *2 << " Y pos: " << buttonYPos << " Width: " << buttonWidth;
    
    twoSecondDelayButton.setPath("button_icons/2_sec_timer_icon.png");
    twoSecondDelayButton.buttonMessage = "2_SEC_DELAY";
    twoSecondDelayButton.buttonLabel = "2 second delay";
    if (currentOrientation == OF_ORIENTATION_DEFAULT || currentOrientation == OF_ORIENTATION_180) {
        twoSecondDelayButton.set(buttonXPos * 5, buttonYPos, buttonWidth, buttonWidth);
    } else {
        twoSecondDelayButton.set(buttonXPos * 5, buttonYPos, buttonWidth, buttonWidth);
        buttonYPos += buttonWidth; // Increment Y position for the next button
    }
    ofLog(OF_LOG_VERBOSE) << "twoSecondDelayButton X pos: " << buttonXPos *3 << " Y pos: " << buttonYPos << " Width: " << buttonWidth;
    
    
    directCaptureButton.setPath("button_icons/no_timer_icon.png");
    directCaptureButton.buttonMessage = "NO_SEC_DELAY";
    directCaptureButton.buttonLabel = "Capture";
    if (currentOrientation == OF_ORIENTATION_DEFAULT || currentOrientation == OF_ORIENTATION_180) {
        directCaptureButton.set(buttonXPos * 7, buttonYPos, buttonWidth, buttonWidth);
    } else {
        directCaptureButton.set(buttonXPos * 7, buttonYPos, buttonWidth, buttonWidth);
    }
    ofLog(OF_LOG_VERBOSE) << "directCaptureButton X pos: " << buttonXPos *4 << " Y pos: " << buttonYPos << " Width: " << buttonWidth;
    
    ofLogVerbose("ofApp::setupReviewModeButtons") << "Review mode buttons setup and disabled";
}

// Function to apply transformations based on the current orientation
void ofApp::adjustForOrientation(ofOrientation orientation, float x, float y, float width, float height) {
    orientation =  OF_ORIENTATION_DEFAULT;
    switch (orientation) {
        case OF_ORIENTATION_DEFAULT:
            // No transformation needed
            break;
        case OF_ORIENTATION_180:
            ofTranslate(x + width, y + height);
            ofRotateDeg(180);
            break;
        case OF_ORIENTATION_90_RIGHT:
            ofTranslate(x + width, y);
            ofRotateDeg(90);
            break;
        case OF_ORIENTATION_90_LEFT:
            ofTranslate(x, y + height);
            ofRotateDeg(-90);
            break;
        default:
            // Handle unknown orientation, possibly no transformation or default case
            break;
    }
}
void ofApp::gotMessage(ofMessage msg){
    if (msg.message == "5_SEC_DELAY") {
        runTimer(5000);
        
        
    }
    if (msg.message == "2_SEC_DELAY") {
        runTimer(2000);
    }
    if (msg.message == "NO_SEC_DELAY") {
        operationMode = MODE_RECORD_READY;
    }
    if (msg.message == "SWITCH_CAM") {
            if (grabberDeviceID == 0) {
                grabber.setDeviceID(1);
                grabberDeviceID = 1;
                grabber.setup(1080, 1920);
            } else if (grabberDeviceID == 1) { // Changed to 'else if' to prevent immediate switch-back
                grabber.setDeviceID(0);
                grabberDeviceID = 0;
                grabber.setup(1080, 1920);
            }
        }
}

void ofApp::runTimer(int millis){
    operationMode = MODE_COUNTING_DOWN;

    
    startTime = ofGetElapsedTimeMillis(); // Get the current time as the start time
    countdownTime = millis;
    isCountingDown = true;  // Start the countdown
    lastSecondShown = -1;  // Initialize so that the first second will be shown immediately
}

void ofApp::startRecording(){
    if (!isRecording) {
        operationMode = MODE_RECORDING;
    
        isRecording = true;
        imageArray.clear();
        
        ofLogNotice() << "Recording started";
    }
}
