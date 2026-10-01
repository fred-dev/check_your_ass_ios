#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    ofSetFrameRate(60);
    ofSetLogLevel(OF_LOG_NOTICE);

    float shortSide = std::min(ofGetWidth(), ofGetHeight());
    mainTextFont.load("gui_resources/Gaultier-Regular.ttf", shortSide / 26);
    giantCounterFont.load("gui_resources/Gaultier-Regular.ttf", shortSide / 2.5);

    beepSound.load("sounds/beep.wav");
    goSound.load("sounds/go.wav");
    beepSound.setMultiPlay(true);

    setupButtons();

    findCameras();
    startCamera(frontCameraID >= 0 ? frontCameraID : 0);

    frames.reserve(MAX_FRAMES);
    applyOrientation(ofGetOrientation());
}

//--------------------------------------------------------------
void ofApp::update(){
    grabber.update();

    if (mode == MODE_COUNTING_DOWN) {
        int remaining = countdownMillis - int(ofGetElapsedTimeMillis() - countdownStart);
        if (remaining <= 0) {
            goSound.play();
            startRecording();
        } else {
            // One beep per second, then three quick beeps in the last second,
            // like the iOS camera timer.
            int beat = remaining > 1000 ? int(std::ceil(remaining / 1000.0f))
                                        : 100 + (1000 - remaining) / 334;
            if (beat != lastBeepSecond) {
                lastBeepSecond = beat;
                beepSound.play();
            }
        }
    }

    if (mode == MODE_RECORDING && grabber.isFrameNew()) {
        ofPixels pixels = grabber.getPixels();
        float s = float(MAX_STORED_SIZE) / std::max(pixels.getWidth(), pixels.getHeight());
        if (s < 1.0f) {
            pixels.resize(pixels.getWidth() * s, pixels.getHeight() * s);
        }
        frames.push_back(std::move(pixels));
        if ((int)frames.size() >= MAX_FRAMES) {
            stopRecording();
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(30);

    string text;
    switch (mode) {
        case MODE_LIVE:          text = "Pick a timer, then turn around"; break;
        case MODE_COUNTING_DOWN: text = "Get ready"; break;
        case MODE_RECORDING:     text = "Recording"; break;
        case MODE_PLAYBACK:      text = "Drag to look back. Double tap for live view"; break;
    }
    ofRectangle box = mainTextFont.getStringBoundingBox(text, 0, 0);
    mainTextFont.drawString(text, textArea.getCenter().x - box.width / 2, textArea.getCenter().y + box.height / 2);

    if (mode == MODE_PLAYBACK) {
        if (frames.empty()) return;
        if (playbackFrame != frameToPlay) {
            playbackTexture.loadData(frames[frameToPlay]);
            playbackFrame = frameToPlay;
        }
        drawFrame(playbackTexture, playbackTexture.getWidth(), playbackTexture.getHeight(), framesMirrored);

        // Scrub bar under the picture
        ofRectangle r = fitInto(playbackTexture.getWidth(), playbackTexture.getHeight(), videoArea);
        float t = frames.size() > 1 ? frameToPlay / float(frames.size() - 1) : 0;
        ofPushStyle();
        ofSetColor(255, 80);
        ofDrawRectangle(r.x, r.getBottom() - 8, r.width, 8);
        ofSetColor(255);
        ofDrawRectangle(r.x + t * (r.width - 8), r.getBottom() - 8, 8, 8);
        ofPopStyle();
        return;
    }

    if (!grabber.isInitialized() || grabber.getWidth() == 0) return;
    drawFrame(grabber, grabber.getWidth(), grabber.getHeight(), usingFrontCamera);
    ofRectangle r = fitInto(grabber.getWidth(), grabber.getHeight(), videoArea);

    if (mode == MODE_COUNTING_DOWN) {
        int remaining = std::max(0, countdownMillis - int(ofGetElapsedTimeMillis() - countdownStart));
        string number = ofToString(int(std::ceil(remaining / 1000.0f)));
        // Each number starts bright and fades over its second.
        float alpha = ofMap(remaining % 1000, 0, 1000, 60, 255, true);
        ofRectangle nb = giantCounterFont.getStringBoundingBox(number, 0, 0);
        float nx = r.getCenter().x - nb.width / 2 - nb.x;
        float ny = r.getCenter().y - nb.height / 2 - nb.y;
        ofPushStyle();
        ofSetColor(0, alpha * 0.5f);
        giantCounterFont.drawString(number, nx + 6, ny + 6);
        ofSetColor(255, alpha);
        giantCounterFont.drawString(number, nx, ny);
        ofPopStyle();
    }

    if (mode == MODE_RECORDING) {
        float dot = buttonSize * 0.25f;
        float progress = frames.size() / float(MAX_FRAMES);
        ofPushStyle();
        ofSetColor(255, 40, 40, (ofGetElapsedTimeMillis() / 400) % 2 ? 255 : 120);
        ofDrawCircle(r.x + dot * 2, r.y + dot * 2, dot);
        ofSetColor(255, 40, 40);
        ofDrawRectangle(r.x, r.getBottom() - 8, r.width * progress, 8);
        ofPopStyle();
    }
}

//--------------------------------------------------------------
void ofApp::drawFrame(const ofBaseDraws & image, float w, float h, bool mirror){
    ofRectangle r = fitInto(w, h, videoArea);
    if (mirror) {
        // Front camera: show it like a mirror, the same way live and in playback.
        ofPushMatrix();
        ofTranslate(r.getRight(), r.y);
        ofScale(-1, 1);
        image.draw(0, 0, r.width, r.height);
        ofPopMatrix();
    } else {
        image.draw(r.x, r.y, r.width, r.height);
    }
}

//--------------------------------------------------------------
ofRectangle ofApp::fitInto(float w, float h, const ofRectangle & area) const {
    if (w <= 0 || h <= 0) return area;
    float s = std::min(area.width / w, area.height / h);
    return ofRectangle(area.getCenter().x - w * s / 2, area.getCenter().y - h * s / 2, w * s, h * s);
}

//--------------------------------------------------------------
void ofApp::exit(){
    grabber.close();
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    touchMoved(touch);
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    if (mode != MODE_PLAYBACK || frames.empty()) return;
    for (simpleButton * b : {&switchCameraButton, &fiveSecondDelayButton, &twoSecondDelayButton, &directCaptureButton}) {
        if (b->inside(touch.x, touch.y)) return;
    }
    // Left to right moves forward in time, in any orientation.
    frameToPlay = int(ofMap(touch.x, videoArea.x, videoArea.getRight(), 0, frames.size() - 1, true));
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    if (mode == MODE_PLAYBACK || mode == MODE_COUNTING_DOWN) {
        // Back to the live view, freeing the recorded frames.
        frames.clear();
        playbackFrame = -1;
        mode = MODE_LIVE;
        if (pendingOrientation != OF_ORIENTATION_UNKNOWN) applyOrientation(pendingOrientation);
    }
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    if (mode == MODE_RECORDING) stopRecording();
    if (mode == MODE_COUNTING_DOWN) mode = MODE_LIVE;
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    if (mode == MODE_RECORDING) stopRecording();
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    // UIDeviceOrientation 1-4 match OF_ORIENTATION_DEFAULT, _180, _90_LEFT, _90_RIGHT.
    // 5 and 6 are face up / face down, which shouldn't change the layout.
    if (newOrientation < 1 || newOrientation > 4) return;
    ofOrientation orientation = (ofOrientation)newOrientation;
    if (mode == MODE_RECORDING || mode == MODE_COUNTING_DOWN) {
        // Don't restart the camera mid-recording; rotate once it's done.
        pendingOrientation = orientation;
        return;
    }
    if (orientation != ofGetOrientation()) applyOrientation(orientation);
}

//--------------------------------------------------------------
bool ofApp::isPortrait() const {
    ofOrientation o = ofGetOrientation();
    return o == OF_ORIENTATION_DEFAULT || o == OF_ORIENTATION_180;
}

//--------------------------------------------------------------
void ofApp::applyOrientation(ofOrientation orientation){
    pendingOrientation = OF_ORIENTATION_UNKNOWN;
    bool wasPortrait = isPortrait();
    ofSetOrientation(orientation);
    // ofxiOS sizes the grabber's frame buffer for the orientation it was
    // started in, so switching between portrait and landscape needs a restart.
    if (wasPortrait != isPortrait() && cameraID >= 0) {
        startCamera(cameraID);
    }
    layout();
}

//--------------------------------------------------------------
void ofApp::layout(){
    float W = ofGetWidth();
    float H = ofGetHeight();
    std::vector<simpleButton *> buttons = {&switchCameraButton, &fiveSecondDelayButton, &twoSecondDelayButton, &directCaptureButton};
    int n = buttons.size();

    if (isPortrait()) {
        // Buttons in a row along the bottom.
        buttonSize = W / 6;
        float barH = buttonSize * 1.5f;
        float textH = std::max(buttonSize, H * 0.08f);
        textArea.set(0, 0, W, textH);
        videoArea.set(0, textH, W, H - textH - barH);
        float gap = (W - n * buttonSize) / (n + 1);
        for (int i = 0; i < n; i++) {
            buttons[i]->set(gap + i * (buttonSize + gap), H - barH + (barH - buttonSize) / 2, buttonSize, buttonSize);
        }
    } else {
        // Buttons in a column down the right side.
        buttonSize = H / 6;
        float barW = buttonSize * 1.5f;
        float textH = std::max(buttonSize * 0.8f, H * 0.1f);
        textArea.set(0, 0, W - barW, textH);
        videoArea.set(0, textH, W - barW, H - textH);
        float gap = (H - n * buttonSize) / (n + 1);
        for (int i = 0; i < n; i++) {
            buttons[i]->set(W - barW + (barW - buttonSize) / 2, gap + i * (buttonSize + gap), buttonSize, buttonSize);
        }
    }
}

//--------------------------------------------------------------
void ofApp::setupButtons(){
    switchCameraButton.setPath("button_icons/switch_cam_icon.png");
    switchCameraButton.buttonMessage = "SWITCH_CAM";
    switchCameraButton.buttonLabel = "Switch cam";

    fiveSecondDelayButton.setPath("button_icons/5_sec_timer_icon.png");
    fiveSecondDelayButton.buttonMessage = "5_SEC_DELAY";
    fiveSecondDelayButton.buttonLabel = "5 second delay";

    twoSecondDelayButton.setPath("button_icons/2_sec_timer_icon.png");
    twoSecondDelayButton.buttonMessage = "2_SEC_DELAY";
    twoSecondDelayButton.buttonLabel = "2 second delay";

    directCaptureButton.setPath("button_icons/no_timer_icon.png");
    directCaptureButton.buttonMessage = "NO_SEC_DELAY";
    directCaptureButton.buttonLabel = "Capture";
}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){
    if (msg.message == "SWITCH_CAM") {
        if (mode == MODE_RECORDING) return;
        int target = usingFrontCamera ? backCameraID : frontCameraID;
        if (target >= 0) startCamera(target);
        return;
    }
    if (mode == MODE_RECORDING) return;
    if (msg.message == "5_SEC_DELAY") startCountdown(5000);
    if (msg.message == "2_SEC_DELAY") startCountdown(2000);
    if (msg.message == "NO_SEC_DELAY") {
        goSound.play();
        startRecording();
    }
}

//--------------------------------------------------------------
void ofApp::findCameras(){
    std::vector<ofVideoDevice> devices = grabber.listDevices();
    for (size_t i = 0; i < devices.size(); i++) {
        string name = ofToLower(devices[i].deviceName);
        if (name.find("front") != string::npos) {
            if (frontCameraID < 0) frontCameraID = i;
        } else if (backCameraID < 0) {
            backCameraID = i;
        }
    }
    ofLogNotice("findCameras") << "front: " << frontCameraID << " back: " << backCameraID;
}

//--------------------------------------------------------------
void ofApp::startCamera(int deviceID){
    if (grabber.isInitialized()) grabber.close();
    grabber.setDeviceID(deviceID);
    if (!grabber.setup(CAPTURE_W, CAPTURE_H)) {
        ofLogError("startCamera") << "Could not start camera " << deviceID;
    }
    cameraID = deviceID;
    usingFrontCamera = (deviceID == frontCameraID);
}

//--------------------------------------------------------------
void ofApp::startCountdown(int millis){
    frames.clear();
    playbackFrame = -1;
    countdownStart = ofGetElapsedTimeMillis();
    countdownMillis = millis;
    lastBeepSecond = -1;
    mode = MODE_COUNTING_DOWN;
}

//--------------------------------------------------------------
void ofApp::startRecording(){
    frames.clear();
    playbackFrame = -1;
    framesMirrored = usingFrontCamera;
    mode = MODE_RECORDING;
    ofLogNotice() << "Recording started";
}

//--------------------------------------------------------------
void ofApp::stopRecording(){
    ofLogNotice() << "Recording stopped, " << frames.size() << " frames";
    frameToPlay = 0;
    playbackFrame = -1;
    mode = frames.empty() ? MODE_LIVE : MODE_PLAYBACK;
    if (pendingOrientation != OF_ORIENTATION_UNKNOWN) applyOrientation(pendingOrientation);
}
