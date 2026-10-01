#pragma once

#include "ofxiOS.h"
#include "simpleButton.h"

enum AppMode {
    MODE_LIVE,          // live camera, waiting for a timer button
    MODE_COUNTING_DOWN, // timer running, beeping each second
    MODE_RECORDING,     // grabbing frames into memory
    MODE_PLAYBACK       // scrubbing back through the recorded frames
};

class ofApp : public ofxiOSApp {

public:
    void setup();
    void update();
    void draw();
    void exit();

    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);

    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);

    void gotMessage(ofMessage msg);

private:
    // Camera
    void findCameras();
    void startCamera(int deviceID);
    ofVideoGrabber grabber;
    int frontCameraID = -1;
    int backCameraID = -1;
    int cameraID = -1;
    bool usingFrontCamera = true;
    // Capture size passed to ofxiOS (must be one of its presets, landscape order).
    const int CAPTURE_W = 1280;
    const int CAPTURE_H = 720;

    // Orientation and layout
    void applyOrientation(ofOrientation orientation);
    void layout();
    bool isPortrait() const;
    ofRectangle fitInto(float w, float h, const ofRectangle & area) const;
    ofOrientation pendingOrientation = OF_ORIENTATION_UNKNOWN;
    ofRectangle videoArea;   // space available for the picture
    ofRectangle textArea;    // space for the instruction line
    float buttonSize = 0;

    // Recording and playback
    void startCountdown(int millis);
    void startRecording();
    void stopRecording();
    void drawFrame(const ofBaseDraws & image, float w, float h, bool mirror);
    AppMode mode = MODE_LIVE;
    std::vector<ofPixels> frames;   // pixels only, so 200 frames stay small in memory
    ofTexture playbackTexture;
    int playbackFrame = -1;          // frame currently uploaded to playbackTexture
    int frameToPlay = 0;
    bool framesMirrored = true;      // whether the recorded frames came from the front camera
    const int MAX_FRAMES = 200;
    const int MAX_STORED_SIZE = 640; // longest side of a stored frame, in pixels

    // Countdown
    uint64_t countdownStart = 0;
    int countdownMillis = 0;
    int lastBeepSecond = -1;
    ofSoundPlayer beepSound;
    ofSoundPlayer goSound;

    // UI
    void setupButtons();
    simpleButton switchCameraButton;
    simpleButton fiveSecondDelayButton;
    simpleButton twoSecondDelayButton;
    simpleButton directCaptureButton;
    ofTrueTypeFont mainTextFont;
    ofTrueTypeFont giantCounterFont;
};
