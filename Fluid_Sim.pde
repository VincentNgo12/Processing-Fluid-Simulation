PImage img;//background image

// Initialize global variables
Fluid fluid;
Player player;
ArrayList<Balls> balls; //My Balls
int SCALE;
float domainHeight = 1.0; //Aspect ratio of the screen height
float domainWidth;
float h;
float res = 100;
int numX, numY;
float dt = 1e-2;

float dragCof = 0.05; //Drag coefficient
//Array to keep track of currently keys pressed
boolean[] pressedKeys = new boolean[4];

//Choose your screen size
 void settings() {
  size(1600,800);
}


void setup(){
  img = get_random_image();//assign random image
  frameRate(100); //fps master race
  domainWidth = width/height * domainHeight; //Get the aspect ratio of the screen width
  h = domainHeight/res; //Get the grid spacing
  // Number of Grids
  numX = int(domainWidth / h);
  numY = int(domainHeight / h);

  SCALE = int(height/numY); //scaling for rendering the simulation
  fluid = new Fluid(000, numX, numY, h, SCALE); //initialize our Fluid object
  player = new Player(fluid, fluid.numX/2, fluid.numY/2);
  
  //adding random balls
  balls = new ArrayList<>(); //initialize the arraylist
  for (int i = 0; i < 10; i++) {
    float radius = random(20, 60); //raidus
    float x = random(0+radius, width-radius); //positions
    float y = random(0+ radius, height-radius);
    Balls ball = new Balls(x, y, radius); //new ball
    balls.add(ball); //add to array list
  }
}

//Simple loop for draw()
void draw() {
  image(img, 0, 0);
  fluid.simulate(dt, 200); //simulate what's on the grid
  fluid.addDensity(5,5,1.0); //Add more stuff if neccesary
  fluid.addVelocity(5,5,5,5);
  fluid.render(); //Render the fluid!
  
  player.display();
  
  // Update and render them juicy balls
  for (Balls ball : balls) {
    ball.simulate(fluid, 1);
  }
  
  
  if(second()%10 == 0){ //get random image every 10 seconds
    img = get_random_image();
  }
}


//Mouse drag interaction
void mouseDragged(){
  //Get the mouse coordinates
  int x = int(constrain(mouseX/SCALE,0,numX-1));
  int y = int(constrain(mouseY/SCALE,0,numY-1));
  //grid.addDensity(x,y,100);
  
  //Get the mouse velocity base on the previous location
  float vX = mouseX - pmouseX;
  float vY = mouseY - pmouseY;
  //Do whatever you what from here.
  for(int row=y-2; row<y+3; row++){
    for(int col=x-2; col<x+3; col++){
      row = int(constrain(row,0,fluid.numY-1));
      col = int(constrain(col,0,fluid.numX-1));
      fluid.addVelocity(col,row,vX,vY);
      fluid.addDensity(col,row,1.0);
    }
  }
}


//Method to catch any keys pressed
void keyPressed(){
  int index = Helper.char_to_index(key); //get the index from helper method
  pressedKeys[index] = true;
}

//Opposite of key pressed
void keyReleased(){
  int index = Helper.char_to_index(key); //get the index from helper method
  pressedKeys[index] = false;
}


//Method to get random image
PImage get_random_image(){
  String folderpath = "images"; //path to the images folder
  File folder = dataFile(folderpath); //get the folder
  int num_images = folder.list().length; //get the number of images inside folder
  int image = (int) (1 + Math.random()*(num_images-1)); //get one random image number
  
  String imageName = folderpath + "/cat" + image + ".jpg"; //the image file name
  PImage img = loadImage(imageName);//load the image
  img.resize(width, height);//resize the img
  return img; //return the image
}
