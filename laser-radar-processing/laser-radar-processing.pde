import processing.serial.*;
import java.awt.event.KeyEvent;
import java.io.IOException;


Serial myPort;
String port = "COM7";
String angle="";
String distance="";
String data="";
String noObject;
float pixelsDistance;
int iAngle,iDistance;
int index1=0,index2=0;
int maxCm = 100;
int oorDist = 819; // out of range distance
int radiusPadding = 60;
int paddingBottom = 20;
int radius;
float screenScalar; // ss aka screen scalar
int historyCount = 100;
Circular pings = new Circular(historyCount);
ArrayList<Ping> pingsToPush;
int blipRadius = 20;
PImage blip;

void setup()
{
  fullScreen();
  //size(1600,900);
  frameRate(30);
  try {
    myPort=new Serial(this,port,9600);
    myPort.bufferUntil('.');
  } catch (Exception e) {
    println("Error connecting to serial port " + port);
  }
  radius = width/2 - radiusPadding;
  screenScalar = (float)width/1500;
  blipRadius = (int)(screenScalar * blipRadius);
  pingsToPush = new ArrayList<Ping>();
  // make blip image via mask
  PImage mask;
  PGraphics pm = createGraphics(blipRadius*4,blipRadius*4,JAVA2D);
  pm.beginDraw();
  pm.background(0,0,0);
  pm.fill(255,255,255);
  pm.noStroke();
  pm.ellipse(blipRadius*2,blipRadius*2,blipRadius,blipRadius);
  pm.filter(BLUR,3);
  pm.endDraw();
  mask = pm.get();
  
  PGraphics pg = createGraphics(blipRadius*4,blipRadius*4,JAVA2D);
  pg.beginDraw();
  pg.background(100,255,100);
  pg.endDraw();
  blip = pg.get();
  blip.mask(mask);
  imageMode(CENTER);
}

void draw()
{
  background(0); //<>//
  if (myPort == null) {
    try {
      myPort=new Serial(this,port,9600);
      myPort.bufferUntil('.');
    } catch (Exception e) {
      textSize(screenScalar*30);
      text("Error connecting to " + port, 13,50);
    }
  } else {
    for (int i = 0; i < pingsToPush.size(); i++) {
      pings.push(pingsToPush.get(i));
    }
    pingsToPush.clear();
    
    fill(98,245,31);
    
    drawRadar();
    drawPings();
    drawText();
  }
}

void serialEvent(Serial myPort)
{
  try {
    data=myPort.readStringUntil('.'); //<>//
    data=data.substring(0,data.length()-1);
    
    index1=data.indexOf(",");
    angle=data.substring(0,index1);
    distance=data.substring(index1+1,data.length()); // mm
    
    iAngle=int(angle);
    iDistance=int(distance)/10; // cm
    
    pingsToPush.add(new Ping(iDistance,iAngle));
    
  } catch (Exception e) {
    println("Serial read exception");
  }
}
class Ping {
  int distance;
  int angle;
  Ping(int dist, int ang) {
    distance = dist;
    angle = ang;
  }
}
class Circular {
  private ArrayList<Ping> arr;
  private int offset;
  private int size;
  int getSize() { return size; }
  Ping get(int i) {
    int index = (offset+i)%size;
    //println(index + ", " + offset);
    return arr.get(index);
  }
  void push(Ping p) {
    offset = (offset+1)%size;
    arr.set(offset, p);
  }
  Circular(int sizeTmp) {
    size = sizeTmp;
    offset = 0;
    arr = new ArrayList<Ping>();
    while (arr.size() < size) {
      arr.add(new Ping(0,0));
    }
  }
}
void drawRadar(){ // background
  pushMatrix();
  translate(width/2,height-paddingBottom);
  noFill();
  strokeWeight(screenScalar * 2.0f);
  stroke(98,200,31);
  arc(0,0,radius*2,radius*2,PI,TWO_PI);
  arc(0,0,radius*3/2,radius*3/2,PI,TWO_PI);
  arc(0,0,radius,radius,PI,TWO_PI);
  arc(0,0,radius/2,radius/2,PI,TWO_PI);
  line(-radius,0,radius,0);
  line(0,0,-radius*cos(radians(30)),-radius*sin(radians(30)));
  line(0,0,-radius*cos(radians(60)),-radius*sin(radians(60)));
  line(0,0,-radius*cos(radians(90)),-radius*sin(radians(90)));
  line(0,0,-radius*cos(radians(120)),-radius*sin(radians(120)));
  line(0,0,-radius*cos(radians(150)),-radius*sin(radians(150)));
  line(-radius*cos(radians(30)),0,radius,0);
  popMatrix();
}


void drawPings() {
  Ping p;
  int blipOpacity;
  int beamOpacity;
  pushMatrix();
  strokeWeight(screenScalar * 9.0f);
  translate(width/2,height-paddingBottom);
  
  for(int i = 0; i < historyCount; i++) {
    p = pings.get(i);
    blipOpacity = i * 255 / historyCount;
    beamOpacity = i * 255 / historyCount - 180;
    //println(p.distance + ", " + p.angle + ", " + opacity);
    // green line
    stroke(0,255,0,beamOpacity);
    line(0,0,radius*cos(radians(p.angle)),-radius*sin(radians(p.angle)));
    
    // ping
    pixelsDistance = p.distance * radius / maxCm; // covers the distance from the sensor from cm to pixels
    if (p.distance < maxCm){
      tint(255, blipOpacity);
      image( blip, pixelsDistance*cos(radians(p.angle)), -pixelsDistance*sin(radians(p.angle)));
    }
  }
  popMatrix();
}

void drawText()
{
  pushMatrix();
  noStroke();
  fill(98,245,31);
  textSize(screenScalar * 25);
  pushMatrix();
  translate(width/2,height-paddingBottom);
  int textHeight = -10;
  text(maxCm/4 + "cm",radius/4,textHeight);
  text(maxCm/2 + "cm",radius/2,textHeight);
  text(maxCm*3/4 + "cm",radius*3/4,textHeight);
  text(maxCm + "cm",radius,textHeight);
  popMatrix();
  textSize(screenScalar*30);
  text("Angle: " + iAngle +"°",screenScalar*400, screenScalar*50);
  text("Distance: " + (iDistance < oorDist ? iDistance + "cm" : "Out of Range"), screenScalar*13,screenScalar*50);
  popMatrix();
}
