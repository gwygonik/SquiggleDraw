// SquiggleDraw
//
// A processing sketch by Gregg Wygonik
//
// https://github.com/gwygonik/SquiggleDraw
//
// Contributions 

import controlP5.*;
import processing.svg.*;

ControlP5 gui;

PShape s;
PShape liner;

PImage p1;
PImage p2;


int ystep = 160;//80;
int ymult = 6;//5;
int xstep = 3;

int imageScaleUp = 3;

float r = 0.0;
float a = 0.0;
int strokeWidth = 1;

float startx,starty;

int b,oldb;

boolean isRunning = true;
boolean isRecording = false;
boolean needsReload = true;

boolean invert = false;

String imageName = "Rachel-Carson.jpg";

void setup() {
  size(100,100);
  loadMainImage(imageName);
  createSecondaryImage();

  gui = new ControlP5(this);
  gui.addSlider("sldLines").setSize(130,30).setCaptionLabel("Number of Lines").setPosition(10,20).setRange(10,200).setValue(120).setColorCaptionLabel(color(0));
  gui.getController("sldLines").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addToggle("tglInvert").setCaptionLabel("Invert Colors").setPosition(10,80).setValue(false).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(0));
  gui.getController("tglInvert").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("sldAmplitude").setSize(130,30).setCaptionLabel("Squiggle Strength").setPosition(10,140).setRange(0,20).setValue(13).setColorCaptionLabel(color(0));
  gui.getController("sldAmplitude").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("sldXSpacing").setSize(130,30).setCaptionLabel("Detail").setPosition(10,200).setRange(1,30).setValue(28).setColorCaptionLabel(color(0));
  gui.getController("sldXSpacing").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("lineWidth").setSize(130,30).setCaptionLabel("Line Width").setPosition(10,260).setRange(1,10).setValue(5).setColorCaptionLabel(color(0));
  gui.getController("lineWidth").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addBang("bangSave").setSize(130,30).setCaptionLabel("Save SVG").setPosition(10,360).setColorCaptionLabel(color(255));
  gui.getController("bangSave").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);

  smooth();
  background(255);
  shapeMode(CORNER);
}

void loadMainImage(String inImageName) {
  p1 = loadImage(inImageName);
  surface.setSize(p1.width + 150, p1.height);

  // filter image
  p1.filter(GRAY);
  p1.filter(BLUR,2);
  if (invert) {
    p1.filter(INVERT);
  }
}

void createSecondaryImage() {
  p2 = createImage(p1.width*imageScaleUp,p1.height*imageScaleUp,RGB);
  p2.copy(p1,0,0,p1.width,p1.height,0,0,p1.width*imageScaleUp,p1.height*imageScaleUp);
}

void draw() {
  if (isRunning) {
    if (isRecording) {
      beginRecord(SVG, "squiggleImage_" + millis() + ".svg");
    }
    createPic();
    if (isRecording) {
      endRecord();
    }
    isRunning = false;
    isRecording = false;
    createPic();
  }
}

void createPic() {

  if (needsReload) {
    loadMainImage(imageName);
    createSecondaryImage();
    needsReload = false;
  }
  
  stroke(0);
  noFill();
  strokeWeight(strokeWidth);
 
  startx = 0.0;
  starty = 0.0;

  s = createShape(GROUP);

  for (int y=0;y<p2.height;y+=p2.height/ystep) {
    
    liner = createShape(PShape.PATH);
    liner.beginShape();
    a = 0.0;
    startx = 0;
    
    b = (int)brightness(p2.get(1,y));
    float z = 255.0-b;
    r = 5;
    starty = y + sin(a)*r;
    
    liner.vertex(startx,starty);
    
    for (int x = 0;x<p2.width;x+=xstep) {
      b = (int)brightness(p2.get(x,y));
      z = max(250.0-b,0);
      r = z/ystep*ymult;
      a += z/128.0;
      liner.vertex(x,y+sin(a)*r);
    }
    liner.endShape();
    s.addChild(liner);
  }
    
  background(255);
  s.scale(1.0/imageScaleUp);
  shape(s,isRecording ? 0 : 150,0);
}

void sldLines(int value) {
  ystep = value;
  needsReload = false;
  redrawImage();
}

void sldAmplitude(int value) {
  ymult = value;
  needsReload = false;
  redrawImage();
}

void sldXSpacing(int value) {
  xstep = 31-value;
  needsReload = false;
  redrawImage();
}

void tglInvert(boolean value) {
  invert = value;
  needsReload = true;
  redrawImage();
}

void lineWidth(int value) {
  strokeWidth = value;
  redrawImage();
}

void bangSave() {
  isRecording = true;
  isRunning = true;
  redraw();
}

void redrawImage() {
  isRunning = true;
  isRecording = false;
}

void keyPressed() {
  if (key == ' ') {
    // nothing here
  } else if (key == 's') {
    isRecording = true;
    isRunning = true;
    redraw();
  }
}