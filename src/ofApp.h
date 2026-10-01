#pragma once

#include "ofxiOS.h"
#include "simpleButton.h"

#define MODE_RECORD_READY 0
#define MODE_RECORDING 1
#define MODE_PLAYBACK 2
#define MODE_COUNTING_DOWN 3




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
    
    
    
    
    ofVideoGrabber  grabber;
    std::vector<ofImage> imageArray; // Vector to store image frames
    const int ARRAYMAX = 200; // Example max size of the array    int arrayCounter;
    bool firstRun;
    bool paused;
    int playCounter;
    int myFrameRate;
    bool isRecording;
    int frameToPlay;
    int addFrame;
    bool newFrameToAdd;
    
    float cameraAspectRatio;
    float screenAspectRatio;
    float scale;
    
    float scaledWidth;
    float scaledHeight;
    float x;
    float y;
    
    ofTrueTypeFont    maintextFont, giantCounterFont;
    float textYPosition;
    
    void setupButtons();
    simpleButton switchCameraButton;
    simpleButton fiveSecondDelayButton;
    simpleButton twoSecondDelayButton;
    simpleButton directCaptureButton;
    
    void adjustForOrientation(ofOrientation orientation, float x, float y, float width, float height);
    
    int grabberDeviceID;
    
    
    void runTimer(int millis);
    
    void startRecording();
    
    int startTime; // Get the current time as the start time
    int countdownTime;
    bool isCountingDown;  // Start the countdown
    int lastSecondShown;  //
    
    int operationMode = MODE_RECORD_READY;
    
    void adjustCameraSetup();
    int currentOrientation;

};
