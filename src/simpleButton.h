/********  Test sample for ofxInteractiveObject									********/
/********  Make sure you open your console to see all the events being output	********/


#pragma once
#include "ofxMSAInteractiveObject.h"

#define     IDLE_COLOR      0x60ACE6
#define     OVER_COLOR      0xE6643E
#define     DOWN_COLOR      0xFF0000


class simpleButton : public ofxMSAInteractiveObject {
	public:


		string buttonLabel;
		string buttonMessage;
		//ofTrueTypeFont  drawFont;
		ofImage buttonIcon;


		void setPath(string icon_path){
			enableMouseEvents();
			enableKeyEvents();
			buttonIcon.load(icon_path);
			//drawFont.load("gui_resources/Gaultier-Regular.ttf", 26);

		}


		virtual void exit() override {
		}


		virtual void update() override {
			//		x = ofGetWidth()/2 + cos(ofGetElapsedTimef() * 0.2) * ofGetWidth()/4;
			//		y = ofGetHeight()/2 + sin(ofGetElapsedTimef() * 0.2) * ofGetHeight()/4;
		}


		virtual void draw() override {
			ofPushStyle();
//		if(isMousePressed()) ofSetHexColor(DOWN_COLOR);
////		else if(isMouseOver()) ofSetHexColor(OVER_COLOR);
//		else ofSetHexColor(IDLE_COLOR);
//        ofDrawRectRounded(x, y, width, height, 10);
//        ofPopStyle();
//		ofPushStyle();
//		ofSetColor(0);
			buttonIcon.draw(x, y, width, height);
			//drawFont.drawString(buttonLabel, x + ((width - drawFont.getStringBoundingBox(buttonLabel, 0, 0).width)/2), y + ((height - drawFont.getStringBoundingBox(buttonLabel, 0, 0).height)));
			ofPopStyle();
		}

		virtual void onRollOver(int x, int y) override {
		}

		virtual void onRollOut()override {
		}

		virtual void onMouseMove(int x, int y)override {
		}

		virtual void onDragOver(int x, int y, int button) override {
		}

		virtual void onDragOutside(int x, int y, int button) override {
		}

		virtual void onPress(int x, int y, int button) override {
			ofSendMessage(buttonMessage);
		}

		virtual void onRelease(int x, int y, int button) override {
		}

		virtual void onReleaseOutside(int x, int y, int button) override {
		}

		virtual void keyPressed(int key) override {
		}

		virtual void keyReleased(int key) override {
		}

};
