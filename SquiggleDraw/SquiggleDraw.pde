// SquiggleDraw
//
// A processing sketch by Gregg Wygonik
//
// https://github.com/gwygonik/SquiggleDraw


/* 
 
 Additional credits
 
 Contributions by Maksim Surguy 
 https://github.com/msurguy
 
 Contributions by Ivan Moroz (sNow)
 https://github.com/sNow32/a
 
 Contributions by Windell H. Oskay
 www.evilmadscientist.com
 https://github.com/evil-mad/
 
 */


import controlP5.*;
import processing.svg.*;

ControlP5 gui;

PShape s;
PShape liner;

PImage p1;
PImage p2;

// toggle button images to make UI less ambiguous
// note that the actual images are reversed due to a bug in controlP5
PImage toggleImage_ON;
PImage toggleImage_OFF;

int ystep = 160;
int ymult = 6;
int xstep = 3;
float xsmooth = 128.0;

int imageScaleUp = 3;

float r = 0.0;
float a = 0.0;
int strokeWidth = 1;

float startx, starty, z;

int b, oldb;
int maxB = 255;
int minB = 0;

boolean isRunning = true;
boolean isRecording = false;
boolean needsReload = true;

//boolean isInit = false;

boolean invert = false;

boolean connectEnds = false;

//! TODO: scroll bar for big images 


String imageName = "Rachel-Carson.jpg";

void setup() {
  size(300, 1000);
  
  toggleImage_ON = loadImage("tglOn.png");
  toggleImage_OFF = loadImage("tglOff.png");
  
  //surface.setResizable(true);
  loadMainImage(imageName);
  createSecondaryImage();

  gui = new ControlP5(this);
  gui.addSlider("sldLines").setSize(130, 30).setCaptionLabel("Number of Lines").setPosition(10, 20).setRange(10, 200).setValue(120).setColorCaptionLabel(color(0));
  gui.getController("sldLines").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addTextlabel("lblInvert").setText("INVERT COLORS").setPosition(7,68).setColor(color(0)).setFont(gui.BitFontStandard58);
  gui.addToggle("tglInvert").setPosition(10, 80).setValue(false).setImages(toggleImage_ON, toggleImage_OFF);

  gui.addTextlabel("lblConnect").setText("CONNECT ENDS").setPosition(77,68).setColor(color(0)).setFont(gui.BitFontStandard58);
  gui.addToggle("tglConnect").setPosition(80, 80).setValue(false).setImages(toggleImage_ON, toggleImage_OFF);


  gui.addSlider("sldAmplitude").setSize(130, 30).setCaptionLabel("Squiggle Strength").setPosition(10, 140).setRange(0, 20).setValue(13).setColorCaptionLabel(color(0));
  gui.getController("sldAmplitude").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("sldXSpacing").setSize(130, 30).setCaptionLabel("Detail").setPosition(10, 200).setRange(1, 30).setValue(28).setColorCaptionLabel(color(0));
  gui.getController("sldXSpacing").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("sldXFrequency").setSize(130, 30).setCaptionLabel("Frequency").setPosition(10, 260).setRange(5.0, 200.0).setValue(128.0).setColorCaptionLabel(color(0));
  gui.getController("sldXFrequency").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("sldImgScale").setSize(130, 30).setCaptionLabel("Resolution Scale").setPosition(10, 320).setRange(1, 3).setValue(3).setColorCaptionLabel(color(0));
  gui.getController("sldImgScale").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("lineWidth").setSize(130, 30).setCaptionLabel("Line Width").setPosition(10, 380).setRange(1, 10).setValue(5).setColorCaptionLabel(color(0));
  gui.getController("lineWidth").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("minBrightness").setSize(130, 30).setCaptionLabel("Black Point").setPosition(10, 440).setRange(0, 255).setValue(0).setColorCaptionLabel(color(0));
  gui.getController("minBrightness").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  gui.addSlider("maxBrightness").setSize(130, 30).setCaptionLabel("White Point").setPosition(10, 500).setRange(0, 255).setValue(255).setColorCaptionLabel(color(0));
  gui.getController("maxBrightness").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

  // added: .setTriggerEvent(Bang.RELEASE)
  // now you don't have to click 's' to save. save button work fine now. 
  gui.addBang("bangLoad").setSize(130, 30).setTriggerEvent(Bang.RELEASE).setCaptionLabel("Load image").setPosition(10, 600).setColorCaptionLabel(color(255));
  gui.getController("bangLoad").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addBang("bangSave").setSize(130, 30).setCaptionLabel("Save SVG").setPosition(10, 660).setColorCaptionLabel(color(255));
  gui.getController("bangSave").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);

  // add 'default' button
  gui.addBang("bangDefault").setSize(130, 30).setCaptionLabel("Default").setPosition(10, 720).setColorCaptionLabel(color(255));
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

  surface.setSize(p1.width + 165, tempheight);

  // filter image
  p1.filter(GRAY);
  p1.filter(BLUR, 2);
  if (invert) {
    p1.filter(INVERT);
  }

  needsReload = true;
  redrawImage();
}

void createSecondaryImage() {
  p2 = createImage(p1.width*imageScaleUp, p1.height*imageScaleUp, ALPHA);
  p2.copy(p1, 0, 0, p1.width, p1.height, 0, 0, p1.width*imageScaleUp, p1.height*imageScaleUp);
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

  if (!isRecording)
    background(255);

  float scaleFactor = 1.0/imageScaleUp;
  float xOffset = isRecording ? 0 : 150;

  float deltaPhase;
  float deltaX;
  float deltaAmpl;

  /*
   The minimum phase increment should give about 40 vertices minimum
   across x. 40 vertices -> 10 * 2 pi. 
   */
  float minPhaseIncr = 10 * TWO_PI / (p2.width / xstep);

  /*
    Maximum phase increment (frequency cap) is based on line thickness and x step size.
   
   A full period of oscillation needn't be less than 
   2 * strokeWidth in total width.
   
   The maximum number of full cycles that should be permitted in a 
   horizontal distance of xstep should be:
   N = total width/width per cycle =  xstep / (2 * strokeWidth)
   
   The maximum phase increment in distance xstep should then be:
   
   maxPhaseIncr = 2 Pi * N = 2 * Pi *  xstep / (2 * strokeWidth) 
   = 2Pi *  xstep / strokeWidth
   
   We do not need to include the scaling factors, since
   both the step size and stroke width are scaled the same way.
   */


  float maxPhaseIncr =  TWO_PI * xstep / strokeWidth;

  strokeWeight(strokeWidth * scaleFactor);

  if (connectEnds)
  {    
    beginShape();
  }

  boolean oddRow = false;
  boolean finalRow = false;
  boolean reverseRow;
  float lastX;
  float scaledYstep = p2.height/ystep;

  for (int y=0; y<p2.height; y+=scaledYstep) {

    if (!connectEnds)
    {    
      beginShape();
    }

    oddRow = !oddRow;
    if (y + (scaledYstep ) >= p2.height)
      finalRow = true;

    if (connectEnds && !oddRow)
      reverseRow = true;
    else
      reverseRow = false;

    a = 0.0;

    // Add initial "extra" point to give splines a consistent visual endpoint,
    // IF we are not connecting rows.

    if (reverseRow)
    {
      if (!connectEnds || y == 0)    
      {
        // Always add the extra initial point if we're not connecting the ends, or if this is the first row.
        curveVertex(xOffset + scaleFactor * (p2.width + 0.1 * xstep), scaleFactor * y);
      }
      curveVertex(xOffset + scaleFactor * (p2.width), scaleFactor * y);
    } else
    {
      if (!connectEnds || y == 0)    
      {
        // Always add the extra initial point if we're not connecting the ends, or if this is the first row.
        curveVertex(xOffset - scaleFactor * ( 0.1 * xstep), y * scaleFactor);
      }
      curveVertex(xOffset, y * scaleFactor);
    }


    /*
    Step along width of image.
     
     For each step, get the image brightness for that XY position,
     and constrain it to our bright/dark cutoff window.
     
     Accumulated phase: increment by scaled brightness, so that the frequency
     increases in certain areas of the image.  Phase only advances with pigment,
     not simply by traversing across the image in X.
     
     Amplitude: A simple multiplier based on local brightness.
     
     To have high quality generated curves for display and plotting, we would like to:
     
     (1) Avoid aliasing. Aliasing happens when we plot a signal at a poorly
     representative set of points. By undersampling -- e.g., less than once per
     period -- you can very easily see what appears to be a sine wave, but does
     not actually represent the actual function being sampled.
     
     Two potential methods to avoid aliasing:
     (A) Increase the number of points, to ensure that some minimum number
     of points are sampeled per period, or 
     (B) Plot the function at specific points {x_i} that are determined by
     the value of the function f(x) at those points, e.g., at every crest, 
     trough, and zero crossing.
     
     (2) Place relatively few control points. 
     CNC software tends to follow simply defined curves more easily than 
     paths with a great many closely-spaced points. 
     Side benefit: Potentially smaller file size.
     
     (3) Place an upper bound on the maximum frequency.
     Above a certain frequency, with a finite-width pen, increasing the frequency
     does not make the plot any darker. 
     
     
     To achieve these goals, we will try: 
     
     (1) Putting x-points (vertices) at every crest, trough, and zero crossing. 
     Point x-positions may be approximated as necessary by interpolation.
     
     (2) Using Processing's curveVertex method, to create curvy lines
     (Catmull–Rom splines). These will only approximate sine waves, but 
     should work well for this particular application.
     
     (3) Using the GUI line-width control to control the maximum frequency.
     
     */

    float phase = 0.0;
    float lastPhase = 0; // accumulated phase at previous vertex
    float lastAmpl = 0; // amplitude at previous vertex
    boolean finalStep = false;

    int x;

    x = 1;
    lastX = 1;

    float[] xPoints = new float[0]; 
    float[] yPoints = new float[0]; 

    while (finalStep == false) { // Iterate over each each x-step in the row

      // Moving right to left:
      x += xstep;
      if (x + xstep >= p2.width)
        finalStep = true;
      else
        finalStep = false;


      b = (int)alpha(p2.get(x, y));
      b = max(minB, b);
      z = max(maxB-b, 0);        // Brightness trimmed to range.

      r = z/ystep*ymult;        // ymult: Amplitude

      /*
       Enforce a minimum phase increment, to prevent large gaps in splines 
       This will add extra vertices in flat regions, but the amplitude remains
       unaffected (near-zero amplitude), so it does not cause a significant
       visual effect.
       */

      float df = z/xsmooth;
      if (df < minPhaseIncr)
        df = minPhaseIncr;

      /*
       Enforce a maximum phase increment -- a frequency cap -- to prevent 
       unnecessary plotting time. Once the frequency is so high that the line widths
       of neighboring crests overlap, there is no added benefit to having higher
       frequency; it's just wasting memory (and ink + time, if plotting).
       */

      if (df > maxPhaseIncr)
        df = maxPhaseIncr;

      phase += df;  // xsmooth: Frequency

      deltaX = x - lastX; // Distance between image sample location x and previous vertex

      deltaAmpl = r - lastAmpl;

      deltaPhase = phase - lastPhase; // Change in phase since last *vertex*
      // (Vertices do not fall along the x "grid", but where they need to.)

      if (!finalStep)  // Skip to end points if this is the last point in the row.
        if (deltaPhase > HALF_PI) // Only add vertices if true.
        {
          /* 
           Linearly interpolate phase and amplitude since last vertex added.
           This treats the frequency as constant
           between subsequent x-samples of the source image.
           */

          int vertexCount = floor( deltaPhase / HALF_PI); //  Add this many vertices

          float integerPart = ((vertexCount * HALF_PI) / deltaPhase);
          // "Integer" fraction (in terms of pi/2 phase segments) of deltaX.

          float deltaX_truncate = deltaX * integerPart;
          // deltaX_truncate: "Integer" part (in terms of pi/2 segments) of deltaX.

          float xPerVertex =  deltaX_truncate / vertexCount;
          float amplPerVertex = (integerPart * deltaAmpl) / vertexCount;

          // Add the vertices:
          for (int i = 0; i < vertexCount; i = i+1) {

            lastX = lastX + xPerVertex;
            lastPhase = lastPhase + HALF_PI;
            lastAmpl = lastAmpl + amplPerVertex;

            xPoints =  append(xPoints, xOffset + scaleFactor * lastX); 
            yPoints =  append(yPoints, scaleFactor *(y+sin(lastPhase)*lastAmpl));
          }
        }
    }

    if (reverseRow)
    {
      xPoints = reverse(xPoints);
      yPoints = reverse(yPoints);
    }

    for (int i = 0; i < xPoints.length; i++) {
      curveVertex(xPoints[i], yPoints[i]);
    }


    // Add final "extra" point to give splines a consistent visual endpoint:
    if (reverseRow)
    {
      curveVertex(xOffset, y * scaleFactor);
      if (!connectEnds || finalRow)    
      {
        // Always add the extra final point if we're not connecting the ends, or if this is the first row.
        curveVertex(xOffset - scaleFactor * ( 0.1 * xstep), y * scaleFactor);
      }
    } else
    {
      curveVertex(xOffset + scaleFactor * (p2.width), scaleFactor * y);
      if (!connectEnds || finalRow)    
      {
        // Always add the extra final point if we're not connecting the ends, or if this is the first row.
        curveVertex(xOffset + scaleFactor * (p2.width + 0.1 * xstep), scaleFactor * y);
      }
    }


    if (connectEnds && !finalRow)  // Add curvy end connectors
      if (reverseRow)
      {
        curveVertex(xOffset - scaleFactor * ( 0.1 * xstep + scaledYstep/3), (y + scaledYstep/2) * scaleFactor );
      } else
      {
        curveVertex(xOffset + scaleFactor * (p2.width + 0.1 * xstep + scaledYstep/3), (y + scaledYstep/2) * scaleFactor );
      }


    if (!connectEnds)
    {    
      endShape();
    }
  }

  if (connectEnds)
  {    
    endShape();
  }
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

void tglConnect(boolean value) {
  connectEnds = value;
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
  gui.getController("tglConnect").setValue(0);
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
