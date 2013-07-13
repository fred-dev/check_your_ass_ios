#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){	
	ofxiPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
    grabber.setDeviceID(1);
	grabber.initGrabber(480, 360);
    grabber.listDevices();
    
    firstRun=true;
    ofSetVerticalSync(true);
    ofSetFrameRate(25);
    arrayCounter=0;
    paused=false;
    isRecording=false;
    newFrameToAdd=false;
    addFrame=0;
    frameToPlay=0;
	
}

//--------------------------------------------------------------
void testApp::update(){
	
    if (isRecording==true) {
        grabber.update();
        if ( grabber.isFrameNew()) {
   
                addFrame++;
         
            if (addFrame>ARRAYMAX) {
                isRecording=false;
                firstRun=false;
                cout<< "Recording Stopped \n";
                addFrame=0;
            }
            
            newFrameToAdd=true;
            
        }
        
        if (newFrameToAdd==true) {
            imageArray[addFrame-1].setFromPixels(grabber.getPixels(), 480, 360, OF_IMAGE_COLOR);
            cout<< "addFrame " + ofToString(addFrame)+"\n";
            newFrameToAdd=false;
            
        }
    }
}

//--------------------------------------------------------------
void testApp::draw(){
    
	
	if (firstRun==false&&isRecording==false) {
        
        imageArray[frameToPlay].draw(0, 0,screenHeight,screenWidth);
    }
    if (isRecording) {
        ofSetColor(0,0,0);
        ofSetColor(255, 255, 255);
        ofDrawBitmapString("Recording", 50,500);
    }
}

//--------------------------------------------------------------
void testApp::exit(){
    
}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){
    frameToPlay=int(ofMap(touch.y, 0, 768, 0, ARRAYMAX));
    cout<<ofToString(frameToPlay)+"\n";
    
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch){
    isRecording=true;
    cout<<"recording \n";
    
}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::lostFocus(){
    
}

//--------------------------------------------------------------
void testApp::gotFocus(){
    
}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){
    
}


