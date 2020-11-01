import java.awt.Robot;
import java.awt.AWTException;
import java.awt.Point;
import java.awt.MouseInfo;

float fov = PI/3.1f;
float depthOfView = 32.0f; //because we have 15 in width,buut if there is no wall bounderies, we can limit the compute cost.


int rayTestX;
int rayTestY;

//CONST
float SPEED = 0.65f;
float INTEPSILON = 0.01f;

//Mouse support
int oldMouseX=0;
float oldAcceleration;
boolean wasOut=false;
int windowX, windowY, absMouseX, absMouseY;

//Multiple key support
boolean bLeft, bRight, bForward, bBackward;

boolean bIsFiring;


//Texture

PImage texture;
PImage[] textureList = new PImage[4];

//Maps
String map= 
"###############################...#...#...#....#.#.........##...#...#...#....#.#.........##...##-###-#######.############.............#........#.....##.............|........|.....##.............#........#.....##...##.###.#######.#######-####...#...#.....#..#.#.........##...#...#.....#..#.#.........################..#.#.........#####################.........##.....#.......#..............##.....#.......#..............##.....#.......|..............##.....#.......#..............####-####################.######......................W.W...##......................W.W...##......................M.M...##......................M.M...##............................##............................##............................##............................##............................##............................##............................##............................###############################";



/*
 ##############################
 #...#...#...#....#.#.........#
 #...#...#...#....#.#.........#
 #...##-###-#######.###########
 #.............#........#.....#
 #.............|........|.....#
 #.............#........#.....#
 #...##.###.#######.#######-###
 #...#...#.....#..#.#.........#
 #...#...#.....#..#.#.........#
 ###############..#.#.........#
 ####################.........#
 #.....#.......#..............#
 #.....#.......#..............#
 #.....#.......|..............#
 #.....#.......#..............#
 ###-####################.#####
 #......................W.W...#
 #......................W.W...#
 #......................M.M...#
 #......................M.M...#
 #............................#
 #............................#
 #............................#
 #............................#
 #............................#
 #............................#
 #............................#
 #............................#
 ##############################
 */
int largeur, hauteur;//width and height in french. Cant use those words because they are reserved for Processing

//Debug
int frame;
float lagMultiplier=1;



Player p1 = new Player(2,2,0);

//Base functions

int clamp(int a, int b, int c) {
  if (a<b)return b;
  if (a>c)return c;
  return a;
}

void setBoolMove(int keyNumb, boolean b) {
  switch(keyNumb) {
    case 'z':
    case 'w':
      bForward=b;
      break;
    case 's':
      bBackward=b;
      break;
    case 'q':
    case 'a':
      bLeft=b;
      break;
    case 'd':
      bRight=b;
      break;
  }
}


void setup() {
  frameRate(48); //Doom works in 35 tics
  size(1280, 720);
  //fullScreen();
  //noCursor();
  background(0, 0, 0);
  largeur=30;
  hauteur=30;
  texture = loadImage("WOLF9.png");//Default
  textureList[0] = loadImage("WOLF9.png");
  textureList[1] = loadImage("WOLF1.png");
  textureList[2] = loadImage("WOLF5.png");
  textureList[3] = loadImage("WOLF10.png");
}

//We can consider this as the  gameloop
void draw() { 


  ScreenDraw();
  mouseCatcher();
  playerMovement();
}


//Drawing
void ScreenDraw() {
  loadPixels();
  //Raycast
  strokeWeight(1);
  for (int i=0; i<width; i++) { //Ray 
    float rayAngle = (p1.getPlayerAngle() - fov/2) + ( (float)i / (float)width) * fov;
    float distanceToTheWall = 0;
    boolean rayHitWall = false;
    float eyeX = sin(rayAngle);
    float eyeY = cos(rayAngle);
    float sampleX=0;
    float sampleY=0;
    //by default
    while (!rayHitWall && distanceToTheWall < depthOfView) {
      distanceToTheWall += 0.0075f;
      rayTestX = (int)(p1.getPlayerX() + eyeX * distanceToTheWall);
      rayTestY = (int)(p1.getPlayerY() + eyeY * distanceToTheWall);
      char wallType=map.charAt(rayTestY *  largeur + rayTestX);
      if (rayTestX < 0  || rayTestY < 0 || rayTestX >= largeur || rayTestY >=hauteur) {
        rayHitWall = true; //No need to continue, because there is no wall to hit  
        distanceToTheWall = depthOfView;
      } else {
        //If we hit something else than a .
        if (wallType != '.' && wallType != '-' && wallType != '|') {

          switch(wallType) {
            case '#':
              texture = textureList[0];
              break;
            case 'W':
              texture = textureList[1];
              break;
            case 'M':
              texture = textureList[2];
              break;
            case '-':
            case '|':
              texture = textureList[3];
              break;
            default:
              texture = textureList[0];
          }

          rayHitWall = true; 
          //if its a door, then we add 0.5f in the correct direction
          if(wallType=='-' || wallType=='|'){
            distanceToTheWall+=0.5f; 
          }
                    
          float posMidX = (float)rayTestX + 0.5f;
          float posMidY = (float)rayTestY + 0.5f;
          float fTestAngle = atan2((p1.getPlayerY() + eyeY * distanceToTheWall - posMidY), (p1.getPlayerX() + eyeX * distanceToTheWall - posMidX));

          if (fTestAngle >= -PI * 0.25f && fTestAngle < PI * 0.25f){
            sampleX = posMidY - (p1.getPlayerY() + eyeY * distanceToTheWall);
            sampleX*=-1;
          }
          if (fTestAngle >= PI * 0.25f && fTestAngle < PI * 0.75f){
            sampleX = posMidX - (p1.getPlayerX() + eyeX * distanceToTheWall);
          }
          if (fTestAngle < -PI * 0.25f && fTestAngle >= -PI * 0.75f){
            sampleX = posMidX - (p1.getPlayerX() + eyeX * distanceToTheWall);
            sampleX*=-1;
          }
          if (fTestAngle >= PI * 0.75f || fTestAngle < -PI * 0.75f){
            sampleX = posMidY - (p1.getPlayerY() + eyeY * distanceToTheWall);
          }

          sampleX=sampleX*texture.width+texture.width/2;
          sampleX=(int)sampleX;
          while (sampleX<0) {
            sampleX+=texture.width;
          }
        }
      }
    }
    distanceToTheWall*=cos(rayAngle-p1.getPlayerAngle()); //Tried to limit the fisheye effect

    int halfWallHeight = (int)((height/2.0) - height / distanceToTheWall);//THIS IS THE GOOD ALGORYTHM!!! OH FFS    

    for (int pixelY=0; pixelY<height; pixelY++) {
      if (pixelY<halfWallHeight) { //Ceiling drawing
        pixels[pixelY*width+i]=color(75, 75, 75);
      } else if (pixelY>halfWallHeight && pixelY<height-halfWallHeight) {
        sampleY = ((float)pixelY - (float)halfWallHeight) / ((float)height-halfWallHeight - (float)halfWallHeight);
        sampleY*=texture.height;
        sampleY=(int)sampleY;
        while (sampleY<0) {
          sampleY+=texture.height;
        }
        pixels[pixelY*width+i]=texture.pixels[(int)(sampleY*texture.width)+(int)sampleX];
      } else { //Floor drawing
        pixels[pixelY*width+i]=color(55, 55, 55);
      }
    }
  }
  updatePixels();
}




//Mouse support, only 1 axis 
void mouseCatcher() {  
  float mouseXAcceleration=0;
  MouseInfo.getPointerInfo();
  Point pt = MouseInfo.getPointerInfo().getLocation();
  absMouseX = (int)pt.getX();
  absMouseY = (int)pt.getY();
  if (mouseX > 50 && mouseX < width-50 && mouseY > 50 && mouseY < height-50
    && abs(mouseX-pmouseX) == 0 && abs(mouseY-pmouseY) == 0) {
    windowX = (int)(absMouseX-mouseX);
    windowY = (int)(absMouseY-mouseY);
  }
  int x = -1, y = -1;

  mouseXAcceleration = (absMouseX-oldMouseX)/448.0;//So what we have here, is the speed, or the current vector from point oldMouseX to the current mouseX

  if (absMouseX < windowX)
    x = windowX;
  else if (absMouseX > windowX+width)
    x = windowX + width;
  if (absMouseY < windowY)
    y = windowY;
  else if (absMouseY > windowY+height)
    y = windowY + height;
  if (!(x == -1 && y == -1))
  try {
    Robot bot = new Robot();
    bot.mouseMove(x == -1 ? absMouseX : x, y == -1 ? absMouseY : y);
    wasOut=true;
  }
  catch (AWTException e) {
  }

  if (!wasOut) {
    p1.moveYAxisCamera(mouseXAcceleration);
  } else {
    if (absMouseX<windowX) {
      p1.moveYAxisCamera((absMouseX-windowX)/448.0);
    } else if (absMouseX > windowX+width) {
      p1.moveYAxisCamera((absMouseX-(windowX+width))/448.0); //Here, thats some shitty trickery
    }
  }
  oldMouseX=absMouseX;
  wasOut=false;
}

void playerMovement(){
  float mx=0,my=0,mz=0;
  if (bLeft) {
    mx = -0.2f*sin(p1.getPlayerAngle()+(90.0f*3.14159f/180.0))*SPEED;
    my = -0.2f*cos(p1.getPlayerAngle()+(90.0f*3.14159f/180.0))*SPEED;
    p1.move(mx,my,mz);
  }
  if (bRight) {
    mx = 0.2f*sin(p1.getPlayerAngle()+(90.0f*3.14159f/180.0))*SPEED;
    my = 0.2f*cos(p1.getPlayerAngle()+(90.0f*3.14159f/180.0))*SPEED;
    p1.move(mx,my,mz);
  }
  if (bForward) {
    mx = 0.2f*sin(p1.getPlayerAngle())*SPEED;
    my = 0.2f*cos(p1.getPlayerAngle())*SPEED;
    p1.move(mx,my,mz);
  }
  if (bBackward) {
    mx = -0.2f*sin(p1.getPlayerAngle())*SPEED;
    my = -0.2f*cos(p1.getPlayerAngle())*SPEED;
    p1.move(mx,my,mz);
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == ESC) {
      exit();
    }
    if (keyCode == LEFT) {
      p1.moveYAxisCamera(-1.0f/16.0);
    }
    if (keyCode == RIGHT) {
      p1.moveYAxisCamera(1.0f/16.0);
    }
  } else {
    setBoolMove(key, true);
  }
}

void keyReleased() {
  if (key!=CODED) {
    setBoolMove(key, false);
  }
}

void mousePressed() {
  bIsFiring=true;
}

void mouseReleased() {
  bIsFiring=false;
}







class Player {
  private float playerX,playerY,playerZ,playerAngle;
  
  Player(){
    playerX=0;
    playerY=0;
    playerZ=0;
    playerAngle=0;
  }
  Player(int x, int y,int z){
    playerX=x;
    playerY=y;
    playerZ=z;
    playerAngle=0;
  }
  Player(int x, int y,int z, float angle){
    playerX=x;
    playerY=y;
    playerZ=z;
    playerAngle=angle;
  }
  void move(float x,float y,float z){
    playerX+=x;
    playerY+=y;
    playerZ+=z;
    char currentTest =map.charAt((int)playerY*largeur+ (int)playerX);
    if(currentTest != '.' && (currentTest != '-' && currentTest != '|')){ //if its just a block/wall
      playerX-=x;
      playerY-=y;
      playerZ-=z;
    }else if(currentTest == '-' || currentTest == '|'){ //if its a door
      
    }
  }
  
  void moveYAxisCamera(float angle){
    playerAngle+= angle;
  }
  
  float getPlayerX(){
    return playerX;
  }
  
  float getPlayerY(){
    return playerY;
  }
  float getPlayerZ(){
    return playerZ;
  }
  float getPlayerAngle(){
    return playerAngle;
  }
}

class Level {
  String currentLevel = "";
  int mapWidth;
  int mapHeight;
  int mapDepth;
  
  void changeLevel(int numb){
    currentLevel="a";
  }
  
}

class Block {
  boolean isSolid;
  Block(boolean solid){
    isSolid=solid;
  }
  boolean getSolidState(){
    return isSolid;
  }
}

class Wall extends Block {
  Wall(){
    super(true);
  }
}
class Door extends Block {
  int dir;
  Door(int orientation){
    super(false);
    dir=orientation;
  }
}
