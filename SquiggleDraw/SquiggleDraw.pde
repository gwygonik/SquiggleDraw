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


int ystep = 160;
int ymult = 6;
int xstep = 3;
float xsmooth = 128.0;

int imageScaleUp = 3;

float r = 0.0;
float a = 0.0;
int strokeWidth = 1;

float startx,starty;

int b,oldb;
int maxB = 255;
int minB = 0;

boolean isRunning = true;
boolean isRecording = false;
boolean needsReload = true;

//boolean isInit = false;

boolean invert = false;

//! TODO: scroll bar for big images 

String imageName = "Rachel-Carson.jpg";

void setup() {
  size(100,100);
  //surface.setResizable(true);
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

  gui.addSlider("sldXFrequency").setSize(130,30).setCaptionLabel("Frequency").setPosition(10,260).setRange(5.0,256.0).setValue(128.0).setColorCaptionLabel(color(0));
  gui.getController("sldXFrequency").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("sldImgScale").setSize(130,30).setCaptionLabel("Resolution Scale").setPosition(10,320).setRange(1,3).setValue(3).setColorCaptionLabel(color(0));
  gui.getController("sldImgScale").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("lineWidth").setSize(130,30).setCaptionLabel("Line Width").setPosition(10,380).setRange(1,10).setValue(5).setColorCaptionLabel(color(0));
  gui.getController("lineWidth").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("minBrightness").setSize(130,30).setCaptionLabel("Black Point").setPosition(10,440).setRange(0,255).setValue(0).setColorCaptionLabel(color(0));
  gui.getController("minBrightness").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("maxBrightness").setSize(130,30).setCaptionLabel("White Point").setPosition(10,500).setRange(0,255).setValue(255).setColorCaptionLabel(color(0));
  gui.getController("maxBrightness").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  // added: .setTriggerEvent(Bang.RELEASE)
  // now you don't have to click 's' to save. save button work fine now. 
  gui.addBang("bangLoad").setSize(130,30).setTriggerEvent(Bang.RELEASE).setCaptionLabel("Load image").setPosition(10,600).setColorCaptionLabel(color(255));
  gui.getController("bangLoad").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addBang("bangSave").setSize(130,30).setCaptionLabel("Save SVG").setPosition(10,660).setColorCaptionLabel(color(255));
  gui.getController("bangSave").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  
  // add 'default' button
  gui.addBang("bangDefault").setSize(130,30).setCaptionLabel("Default").setPosition(10,720).setColorCaptionLabel(color(255));
  gui.getController("bangDefault").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  
  //// add 'fit' button. fit image to window size 
  //gui.addBang("bangFit").setSize(65, 30).setCaptionLabel("Fit").setPosition(10, 780).setColorCaptionLabel(color(255));
  //gui.getController("bangFit").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  
  //// add 'full' button. load orig image size
  //gui.addBang("bangFull").setSize(65, 30).setCaptionLabel("Full").setPosition(10 + 66, 780).setColorCaptionLabel(color(255));
  //gui.getController("bangFull").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
    
  smooth();
  background(255);
  shapeMode(CORNER);
}

void loadMainImage(String inImageName) {
  //if (isInit) { return; }
  println("loadMainImage");
  //isInit = true;
  p1 = loadImage(inImageName);
  
  int tempheight = p1.height;
  if (tempheight < 720 + 120)
    tempheight = 720 + 120;
      
  surface.setSize(p1.width + 150, tempheight);

  // filter image
  p1.filter(GRAY);
  p1.filter(BLUR,2);
  if (invert) {
    p1.filter(INVERT);
  }
  
  needsReload = true;
  redrawImage();
}

void createSecondaryImage() {
  p2 = createImage(p1.width*imageScaleUp,p1.height*imageScaleUp,ALPHA);
  p2.copy(p1,0,0,p1.width,p1.height,0,0,p1.width*imageScaleUp,p1.height*imageScaleUp);
}

void draw() {
  if (isRunning) {
    if (isRecording) {
      // save to file
      // was: beginRecord(SVG, "squiggleImage_" + millis() + ".svg");
      String[] p = splitTokens(imageName, "."); // split by point to know path without suffix
      // save to dir where is opening file
      String savePath = p[p.length - 2] + "_" + day() + hour() + minute() +  second() + ".svg";           
      println(savePath);
      beginRecord(SVG, savePath);
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
    
    b = (int)alpha(p2.get(1,y));
    float z = 255.0-b;
    r = 5;
    starty = y + sin(a)*r;
    
    liner.vertex(startx,starty);
    
    for (int x = 1;x<p2.width;x+=xstep) {
      b = (int)alpha(p2.get(x,y));
      b = max(minB,b);
      z = max(maxB-b,0);
      r = z/ystep*ymult;
      a += z/xsmooth;
      liner.vertex(x,y+sin(a)*r);
    }
    liner.endShape();
    s.addChild(liner);
  }
    
  background(255);
  s.scale(1.0/imageScaleUp);
  shape(s,isRecording ? 0 : 150,0);
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the cancel selected.");
  } else {
    String loadPath = selection.getAbsolutePath();

    // If a file was selected, print path to file 
    println("Selected file: " + loadPath); 

    String[] p = splitTokens(loadPath, ".");
    boolean fileOK = false;

    if ( p[p.length - 1].equals("GIF"))
      fileOK = true;
    if ( p[p.length - 1].equals("gif"))
      fileOK = true;      
    if ( p[p.length - 1].equals("JPG"))
      fileOK = true;
    if ( p[p.length - 1].equals("jpg"))
      fileOK = true;   
    if ( p[p.length - 1].equals("TGA"))
      fileOK = true;
    if ( p[p.length - 1].equals("tga"))
      fileOK = true;   
    if ( p[p.length - 1].equals("PNG"))
      fileOK = true;
    if ( p[p.length - 1].equals("png"))
      fileOK = true;   

    if (fileOK) {
      println("File type OK."); 
      imageName = loadPath;
      //isInit = false;
      loadMainImage(imageName);
      createSecondaryImage();
      redrawImage();
  } else {
      // Can't load file
      println("ERROR: BAD FILE TYPE");
    }
  }
}

// removed arg: float theValue
void bangLoad() {  
  println(":::LOAD JPG, GIF or PNG FILE:::");

  selectInput("Select an image file to open:", "fileSelected");  // Opens file chooser
} //End Load File


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

void maxBrightness(int value) {
  maxB = value;
  redrawImage();
}

void minBrightness(int value) {
  minB = value;
  redrawImage();
}

void bangSave() {
  isRecording = true;
  isRunning = true;
  redraw();
}

void sldXFrequency(float value) {
  xsmooth = 257.0 - value;
  needsReload = false;
  redrawImage();
}

void sldImgScale(int value) {
  imageScaleUp = value;
  needsReload = true;
  redrawImage();
}

void redrawImage() {
  isRunning = true;
  isRecording = false;
}

void keyPressed() {
 if (key == ' ') {
    // nothing here
  } else if (key == 's') { // save
    isRecording = true;
    isRunning = true;
    redraw();
  } 
}

void bangDefault() {
  gui.getController("sldLines").setValue(120);
  gui.getController("tglInvert").setValue(0);
  gui.getController("sldAmplitude").setValue(13);
  gui.getController("sldXSpacing").setValue(28);
  gui.getController("sldXFrequency").setValue(128);
  gui.getController("sldImgScale").setValue(3);
  gui.getController("lineWidth").setValue(5);
  gui.getController("minBrightness").setValue(0);
  gui.getController("maxBrightness").setValue(255);
}

//void bangFit() {    
//  println("Fit");
//  p1.resize(0, height);
//  needsReload = true;
//  redrawImage();
//}

//void bangFull() {
//  println("Full");
//  isInit = false;
//  loadMainImage(imageName);
//}
