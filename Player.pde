class Player{
  Fluid fluid;
  float posX, posY; // Position of the player
  float speed, acceleration; // Speed of the player
  float angle; // Angle of the player's orientation (in radians)
  
  Player(Fluid fluid, float posX, float posY) {
    this.fluid = fluid; // Reference to the fluid object
    this.posX = posX; // Initial x position
    this.posY = posY; // Initial y position
    this.speed = 0;
    this.angle = 0.0f;
  }

  // Method to update the fluid grid based on the character's position
  void display() {
    Fluid fluid = this.fluid;
    float posX = this.posX;
    float posY = this.posY;
    
    this.move();
    
    // Draw the player as a triangle
    pushMatrix();
    translate(posX, posY);
    rotate(angle-PI/2);
    fill(255); // White color
    triangle(-15,-10,15,-10,0,30); // Triangle shape
    popMatrix();
  }
  
  
  // handle movements
  void move(){
    this.acceleration = 0;
    PVector movement = new PVector(0, 0); //movement vector
    if(pressedKeys[Helper.char_to_index('a')]) this.angle -= 0.1;
    if(pressedKeys[Helper.char_to_index('d')]) this.angle += 0.1;
    if(pressedKeys[Helper.char_to_index('w')]) this.acceleration = 1;
    if(pressedKeys[Helper.char_to_index('s')]) this.acceleration = -1;
    
    
    float x = this.posX/SCALE * fluid.h;//get position on the fluid grid
    float y = this.posY/SCALE * fluid.h;
    // Use fluid vector field to get surrounding velocity
    float vX = fluid.sampleField(x, y, fluid.X_FIELD);
    float vY = fluid.sampleField(x, y, fluid.Y_FIELD);
    
    // Apply fluid drag force
    float fluidDensity = this.fluid.sampleField(this.posX, this.posY, fluid.S_FIELD);
    float dragForce = -this.speed * dragCof * (1.0 - fluidDensity);
    
    this.acceleration += dragForce;//Apple drag force
    this.speed += this.acceleration; //update speed
    
    movement.x = cos(angle);
    movement.y = sin(angle);
    movement.setMag(this.speed); //set magnitude to speed
    
    //Update position
    this.posX += movement.x + vX*5;
    this.posY += movement.y + vY*5;
  }
}
