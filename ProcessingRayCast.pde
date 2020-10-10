float px,py,pz;
float playerAngle;
float fov = 3.14159f/4.0f;
float depthOfView = 16.0f; //because we have 15 in width,buut if there is no wall bounderies, we can limit the compute cost.
float oldMouseY,diffY; //Well I tried to use the mouse to move the cameray in the y axis, but I need the acceleration on y axis of  the mouse instead of a substraction between 2 points, so its unused
float yAdder; //For the keyboard, Unused

String map = "################.............##.............##.....#.......##.....#.......##.....###.....##.............##.............##.............################";
/*################.............##.............##.............##.............##.............##.............##.............##.............################*/
int largeur,hauteur;//width and height in french. Cant use those words because they are reserved for Processing
int rayTestX;
int rayTestY;
int frame;
float lagMultiplier=1;
void setup(){
  frameRate(35); //Like Doom, doom works in 35 tics
  size(1280,720);
  background(0,0,0);
  px=8;
  py=1;
  pz=0;
  largeur=15;
  hauteur=10;
}
float clamp(float a, float b, float c){
  if(a < b){
    return b;
  }else if(a>c){
    return c;
  }else{
    return a;
  }
}

void draw(){
  //Let's draw floor and ceiling first, so we just have to cast the rails to do the walls
  loadPixels();
  for(int j=0;j<width;j++){
    for(int k=0;k<(height/2-1);k++){
      pixels[k*width+j]=color(8,16,(height/2-k)*240/(height/2));
      pixels[(k+height/2)*width+j]=color( 255-(height/2-k)*240/(height/2)   ,0,0);
    }
  }
  updatePixels();
  //Raycast
  strokeWeight(1);
  for(int i=0;i<width-1;i++){
    float rayAngle = (playerAngle - fov/2) + ( (float)i / (float)width) * fov;
    float distanceToTheWall = 0;
    boolean rayHitWall = false;
    //float recti=0;
    float eyeX = sin(rayAngle);
    float eyeY = cos(rayAngle);
    
    while(!rayHitWall && distanceToTheWall < depthOfView){
      distanceToTheWall += 0.001f;
      
      rayTestX = (int)(px + eyeX * distanceToTheWall);
      rayTestY = (int)(py + eyeY * distanceToTheWall);
      
      if(rayTestX < 0  || rayTestY < 0 || rayTestX >= largeur || rayTestY >=hauteur){
          rayHitWall =true; //No need to continue, because there is no wall to hit  
          distanceToTheWall = depthOfView;
          println("A");
      }else{
        if(map.charAt(rayTestY *  largeur + rayTestX) == '#'){
            rayHitWall = true;
        }
      }
    }
   //distanceToTheWall*=cos(distanceToTheWall); //Tried to limit the fisheye effect, so one under this line is the good one.
     distanceToTheWall*=cos(rayAngle-playerAngle); 
    
    if(distanceToTheWall<=1.0f){ //So because of the way I render the wall, when you are near the wall, its very heavy on the compute, so we dont hit 35tics per seconds, so a quick fix I did is to multiplie the rotate by 4 when its lagging so we can get the view out of there faster.
      lagMultiplier=4.0f;
    }else{
      lagMultiplier=1.0f;
    }
    
    //We draw the ray (the wall in fact)
    int halfWallHeight = (int)((height/2.0) - height / distanceToTheWall);//THIS IS THE GOOD ALGORYTHM!!! OH FFS
    if(i==0){
      println(distanceToTheWall);
    }
    
    float nuance =(15-distanceToTheWall-2)*255/15; 
    stroke(nuance);
    line(i, halfWallHeight,    i, height-halfWallHeight);
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == RIGHT) {
      playerAngle+= 0.02f*lagMultiplier;
    } else if (keyCode == LEFT) {
      playerAngle+= -0.02f*lagMultiplier;
    } else if (keyCode == UP){ //We use Euler angle to move in the false 3D space, in fact its just a 2D space... But we want to move in the direction of the player, not based on the axis of the array of the map....
      px+= 0.2f*sin(playerAngle);
      py+= 0.2f*cos(playerAngle);
      if(map.charAt((int)py*largeur+ (int)px) == '#'){
        px-= 0.2f*sin(playerAngle);
        py-= 0.2f*cos(playerAngle);
      }
    } else if(keyCode == DOWN){
      px-= 0.2f*sin(playerAngle);
      py-= 0.2f*cos(playerAngle);
      if(map.charAt((int)py*largeur+ (int)px) == '#'){
        px+= 0.2f*sin(playerAngle);
        py+= 0.2f*cos(playerAngle);
      }
    }
  } 
}
