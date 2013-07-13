#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"

#define ARRAYMAX 100
#define screenWidth 768
#define screenHeight 1024

class testApp : public ofxiPhoneApp{
	
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
		
    ofVideoGrabber  grabber;
    ofImage     imageArray[ARRAYMAX];
    int arrayCounter;
    bool firstRun;
    bool paused;
    int playCounter;
    int myFrameRate;
    bool isRecording;
    int frameToPlay;
    int addFrame;
    bool newFrameToAdd;
 
};
