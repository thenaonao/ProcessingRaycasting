import java.awt.Robot;
import java.awt.AWTException;
import java.awt.Point;
import java.awt.MouseInfo;
 
 
 
float px,py,pz,playerAngle;
float fov = PI/4.0f;
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
boolean bLeft,bRight,bForward,bBackward;

boolean bIsFiring;


//Texture

PImage texture;

//Maps
String map = "###############################...#...#...#....#.#.........##...#...#...#....#.#.........##...##.###.#######.############.............#........#.....##............................##.............#........#.....##...##.###.#######.#######.####...#...#.....#..#.#.........##...#...#.....#..#.#.........################..#.#.........##................###.........##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................##............................###############################";
/*################.............##.............##.............##.............##.............##.............##.............##.............################*/
/*
##############################
#...#...#...#....#.#.........#
#...#...#...#....#.#.........#
#...##.###.#######.###########
#.............#........#.....#
#............................#
#.............#........#.....#
#...##.###.#######.#######.###
#...#...#.....#..#.#.........#
#...#...#.....#..#.#.........#
###############..#.#.........#
####################.........#
#.....#.......#..............#
#.....#.......#..............#
#.....#......................#
#.....#.......#..............#
###.####################.#####
#............................#
#............................#
#............................#
#............................#
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
int largeur,hauteur;//width and height in french. Cant use those words because they are reserved for Processing

//Debug
int frame;
float lagMultiplier=1;





//Base functions

int clamp(int a,int b,int c){
  if(a<b)return b;
  if(a>c)return c;
  return a;
}

void setBoolMove(int keyNumb, boolean b){
  switch(keyNumb){
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


void setup(){
  frameRate(35); //Like Doom, doom works in 35 tics
  size(1280,720);
  //fullScreen();
  //noCursor();
  background(0,0,0);
  px=5;
  py=2;
  pz=0;
  largeur=30;
  hauteur=30;
  texture = loadImage("WOLF9.png");
}

void draw(){ //Let's draw floor and ceiling first, so we just have to cast the rails to do the walls
  
  //DRAWING
  //
  //
  //
  //
  //
  //
  
  
  loadPixels();
  for(int j=0;j<width;j++){
    for(int k=0;k<(height/2-1);k++){
      pixels[k*width+j]=color(8,16,(height/2-k)*240/(height/2));
      pixels[(k+height/2)*width+j]=color( 255-(height/2-k)*240/(height/2)   ,0,0);
    }
  }
  //Raycast
  strokeWeight(1);
  for(int i=0;i<width;i++){
    float rayAngle = (playerAngle - fov/2) + ( (float)i / (float)width) * fov;
    float distanceToTheWall = 0;
    boolean rayHitWall = false;
    boolean isAnEdge=false;
    //float recti=0;
    float eyeX = sin(rayAngle);
    float eyeY = cos(rayAngle);
    
    while(!rayHitWall && distanceToTheWall < depthOfView){
      distanceToTheWall += 0.0075f;
      rayTestX = (int)(px + eyeX * distanceToTheWall);
      rayTestY = (int)(py + eyeY * distanceToTheWall);
      
      if(rayTestX < 0  || rayTestY < 0 || rayTestX >= largeur || rayTestY >=hauteur){
          rayHitWall = true; //No need to continue, because there is no wall to hit  
          distanceToTheWall = depthOfView;
      }else{
        if(map.charAt(rayTestY *  largeur + rayTestX) == '#'){
            rayHitWall = true;
            
            if(  (rayTestX-INTEPSILON <= px+eyeX*distanceToTheWall && px+eyeX*distanceToTheWall <= rayTestX+INTEPSILON) || ((rayTestX+1)-INTEPSILON <= px+eyeX*distanceToTheWall && px+eyeX*distanceToTheWall <= (rayTestX+1)+INTEPSILON)  ){
              if(!(rayTestY-INTEPSILON <= py+eyeY*distanceToTheWall && py+eyeY*distanceToTheWall <= rayTestY+INTEPSILON) || !((rayTestY+1)-INTEPSILON <= py+eyeY*distanceToTheWall && py+eyeY*distanceToTheWall <= (rayTestY+1)+INTEPSILON)  ){     
                  isAnEdge=true;
              }
            }
           
        }
      }
    }
    distanceToTheWall*=cos(rayAngle-playerAngle); //Tried to limit the fisheye effect
    /*
    if(distanceToTheWall<=1.0f){ //So because of the way I render the wall, when you are near the wall, its very heavy on the compute, so we dont hit 35tics per seconds, so a quick fix I did is to multiply the rotate by 4 when its lagging so we can get the view out of there faster.
      lagMultiplier=4.0f;
    }else{
      lagMultiplier=1.0f;
    }*/
    
    //We draw the ray (the wall in fact)
    int halfWallHeight = (int)((height/2.0) - height / distanceToTheWall);//THIS IS THE GOOD ALGORYTHM!!! OH FFS    
    halfWallHeight=clamp(halfWallHeight,0,height);

    for(int m=halfWallHeight;m<height-halfWallHeight;m++){ //So, for each column, we draw pixel column of the wall
        int n=m-halfWallHeight;

        //println(abs((px + eyeX * distanceToTheWall)-floor(px + eyeX * distanceToTheWall))*128);
        //println(abs((py + eyeY * distanceToTheWall)-floor(py + eyeY * distanceToTheWall))*128);
        int pixelToAccessY=n*texture.height/(height-2*halfWallHeight);
        
        //pixelToAccessY=clamp(pixelToAccessY,0,127);
        
        int pixelToAccessX=(int) ( (ceil(py + eyeY * distanceToTheWall)-(py + eyeY * distanceToTheWall) ) *127);
        if(pixelToAccessX<0){
          exit();
          pixelToAccessX=+127;
        }
        int pixelToAccessX2=(int) ( (ceil(px + eyeX * distanceToTheWall)-(px + eyeX * distanceToTheWall) ) *127);
        //println(pixelToAccessX+ "  ;  " +pixelToAccessX2);
        int pixelToAccess=0;

        if( isAnEdge ){
          pixelToAccess=pixelToAccessY*texture.width+pixelToAccessX;
          //println(pixelToAccessX);
        }else{
          pixelToAccess=pixelToAccessY*texture.width+pixelToAccessX2;
        }
        pixels[m*width+i]=texture.pixels[pixelToAccess];
    }   
  }
  updatePixels();  

  
  
  //Mouse support, only 1 axis 
  //
  //
  //
  //
  //
  
  
  float mouseXAcceleration=0;
  MouseInfo.getPointerInfo();
  Point pt = MouseInfo.getPointerInfo().getLocation();
  absMouseX = (int)pt.getX();
  absMouseY = (int)pt.getY();
  if(mouseX > 50 && mouseX < width-50 && mouseY > 50 && mouseY < height-50
                  && abs(mouseX-pmouseX) == 0 && abs(mouseY-pmouseY) == 0) {
    windowX = (int)(absMouseX-mouseX);
    windowY = (int)(absMouseY-mouseY);
  }
  int x = -1, y = -1;
  
  mouseXAcceleration = (absMouseX-oldMouseX)/448.0;//So what we have here, is the speed, or the current vector from point oldMouseX to the current mouseX
  
  if(absMouseX < windowX)
    x = windowX;
  else if(absMouseX > windowX+width)
    x = windowX + width;
  if(absMouseY < windowY)
    y = windowY;
  else if(absMouseY > windowY+height)
    y = windowY + height;
  if(!(x == -1 && y == -1))
    try {
      Robot bot = new Robot();
      bot.mouseMove(x == -1 ? absMouseX : x, y == -1 ? absMouseY : y);
      wasOut=true;
      
    }
  catch (AWTException e) {}
  
  if(!wasOut){
    //if((mouseXAcceleration < 0 && oldAcceleration < 0) || (mouseXAcceleration > 0 && oldAcceleration > 0))
      playerAngle+=mouseXAcceleration;
  }else{
    if(absMouseX<windowX){
      playerAngle+=(absMouseX-windowX)/448.0;
    }else if(absMouseX > windowX+width){
      playerAngle+=(absMouseX-(windowX+width))/448.0; //Here, thats some shitty trickery
    }
  }
  oldMouseX=absMouseX;
  oldAcceleration=mouseXAcceleration;
  wasOut=false;
  
  
  //PLAYER MOVEMENTS
  //
  //
  //
  //
  //
  
  if(bLeft){
      px-= 0.2f*sin(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
      py-= 0.2f*cos(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
      if(map.charAt((int)py*largeur+ (int)px) == '#'){
        px+= 0.2f*sin(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
        py+= 0.2f*cos(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
      }
  }
  if(bRight){
      px+= 0.2f*sin(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
      py+= 0.2f*cos(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
      if(map.charAt((int)py*largeur+ (int)px) == '#'){
        px-= 0.2f*sin(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
        py-= 0.2f*cos(playerAngle+(90.0f*3.14159f/180.0))*SPEED;
      }
  }
  if(bForward){
    px+= 0.2f*sin(playerAngle)*SPEED;
    py+= 0.2f*cos(playerAngle)*SPEED;
    if(map.charAt((int)py*largeur+ (int)px) == '#'){
      px-= 0.2f*sin(playerAngle)*SPEED;
      py-= 0.2f*cos(playerAngle)*SPEED;
    }
  }
  if(bBackward){
    px-= 0.2f*sin(playerAngle)*SPEED;
    py-= 0.2f*cos(playerAngle)*SPEED;
    if(map.charAt((int)py*largeur+ (int)px) == '#'){
      px+= 0.2f*sin(playerAngle)*SPEED;
      py+= 0.2f*cos(playerAngle)*SPEED;
    }
  }
}

void keyPressed() {
  if (key == CODED) {
    if(keyCode == ESC){
      exit();
    }
  }else{
    setBoolMove(key,true);    
  }
}

void keyReleased() {
  if(key!=CODED){
    setBoolMove(key,false);
  }
}

void mousePressed(){
  bIsFiring=true;
}

void mouseReleased(){
  bIsFiring=false;
}
