float px,py,pz;
float playerAngle;
float fov = 3.14159f/4.0f;
float depthOfView = 16.0f; //car on a 15 de longueur, mais si jamais il n'y a pas de bordure exterieur, ca permet de limiter et d'eviter une boucle infinie
float oldMouseY,diffY; //J'ai essayé de faire ca avec la souris pour bouger la camera juste sur un axe Y, mais ca marche pas trop, car je prends des valeurs en 2 points, et il me faudrait l'acceleration de la souris sur l'axe Y
float yAdder; //Pour le clavier du coup

String map = "################.............##.............##.............##.............##.............##.............##.............##.............################";
/*
###############
#.............#
#.............#
#.............#
#.............#
#.............#
#.............#
#.............#
#.............#
###############
*/
int largeur,hauteur;
int rayTestX;
int rayTestY;
//boolean collision=false; //oui j'ai pas d'autre idée car ce n'est pas dans la fonction draw, du coup j'ai pas access a certaines variables nécessaires pour faire le test de collision, du coup, on va mettre un flag sur le ray du milieu et si c'est inferieur a 1.0f alors ce sera true et donc collision vu dans la fonction keypressed
int frame;
float lagMultiplier=1;
void setup(){
  frameRate(35); //un peu comme doom XD
  size(1280,720);
  background(0,0,0);
  px=2;
  py=2;
  pz=0;
  largeur=15;
  hauteur=10;
}

void draw(){
  //Let's draw floor and ceiling first, so we just have to cast the rails to do the walls
  /*fill(32,48,232);//Ceiling will be blue colored
  rect(0,0,width,(height/2)-1);//First rectangle for ceiling
  fill(203,65,84);
  rect(0,(height/2)-1,width,height-1); //We have some minus 1 because we draw outside of the screen..
  */
  loadPixels();
  for(int j=0;j<width;j++){
    for(int k=0;k<(height/2-1);k++){
      pixels[k*width+j]=color(8,16,(height/2-k)*255/(height/2));
      pixels[(k+height/2)*width+j]=color( 255-(height/2-k)*255/(height/2)   ,0,0);
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
      distanceToTheWall += 0.01f;
      
      rayTestX = (int)(px + eyeX * distanceToTheWall);
      rayTestY = (int)(py + eyeY * distanceToTheWall);
      
      if(rayTestX < 0 || rayTestX >= largeur+1 || rayTestY < 0 || rayTestY >=hauteur+1){
          rayHitWall =true; // ca sert a rien de continuer, car y'a rien a dessiner
          distanceToTheWall = depthOfView;
      }else{
        if(map.charAt(rayTestY *  largeur + rayTestX) == '#'){
            rayHitWall = true;
        }
      }
      
    }
    println(distanceToTheWall);
      //distanceToTheWall*=cos(distanceToTheWall); //On essaie de limiter l'effect eyefish
 
      distanceToTheWall*=cos(rayAngle-playerAngle);

    /* non utilisé
    if(i==width/2){ //Donc si c'est la ray du milieu et que distanceToTheWall< 1.0f alors collision == true, on fait 2 if, car si on le fait check en 1 seul fois, ce sera false pour les ray d'apres... 1.0f semble etre trop grand, donc 0.25f semble meilleur
      if(distanceToTheWall<0.25f){
        collision = true;
      }else{
        collision = false;
      }
    }*/
    
    
    if(distanceToTheWall<=1.0f){
      lagMultiplier=4.0f;
    }else{
      lagMultiplier=1.0f;
    }
    
    //On dessine la ray
    int halfWallHeight =(int) ((16-(distanceToTheWall-1))*height)/32; //32 car 16*2 on divise par 16 car regle de 3 pour scale a l'ecran et 2 car on en veut la moitié
    int restantPixel = 360-halfWallHeight;
    int nuance = (int) (16-distanceToTheWall)*255/16; 
    stroke(nuance);
    //line(i,(height/2)-1-halfWallHeight,      i,(height/2)-1+halfWallHeight);
    line(i, restantPixel,    i, height-restantPixel);
    //println(i);
  }
  
  //playerAngle+=diffY/10;
}


void keyPressed() {
  if (key == CODED) {
    if (keyCode == RIGHT) {
      playerAngle+= 0.02f*lagMultiplier;
    } else if (keyCode == LEFT) {
      playerAngle+= -0.02f*lagMultiplier;
    } else if (keyCode == UP){ //On utilise les angles d'euler pour bouger dans l'espace 2D car l'angle differe, on veut bouger dans la direction de l'angle et non pas de l'array
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

void keyReleased() {
  yAdder = 0.0f;
}


void mouseMoved(){
  diffY = mouseY - oldMouseY;
  oldMouseY = mouseY;
}
