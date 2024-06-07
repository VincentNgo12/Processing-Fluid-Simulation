class Balls {
  float x, y;      // Position
  float vx, vy;    // Velocity
  float ax, ay;    // Acceleration
  float radius;    // Radius of the circle
  color c; //color

  Balls(float x, float y, float radius) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.vx = 0;
    this.vy = 0;
    this.ax = 0;
    this.ay = 0;
    this.c = color(random(255), random(255), random(255)); //random color
  }


  void updateAcceleration(Fluid fluid) {
    //Convert position to grid position
    float mass = this.radius / 100;
    float posX = this.x/SCALE * fluid.h;
    float posY = this.y/SCALE * fluid.h;
    // Use fluid vector field to update acceleration
    this.ax = fluid.sampleField(posX, posY, fluid.X_FIELD) / mass;
    this.ay = fluid.sampleField(posX, posY, fluid.Y_FIELD) / mass;

    // Apply fluid drag force
    float fluidDensity = fluid.sampleField(this.x, this.y, fluid.S_FIELD);
    float dragForceX = -this.vx * dragCof * (1.0 - fluidDensity);
    float dragForceY = -this.vy * dragCof * (1.0 - fluidDensity);

    // Update acceleration based on drag force
    this.ax += dragForceX / mass;
    this.ay += dragForceY / mass;
  }

  void update(float dt) {
    // Update velocity
    this.vx += this.ax * dt;
    this.vy += this.ay * dt;
    //Update position
    this.x += this.vx * dt;
    this.y += this.vy * dt;

    //Bonce off if touch borders
    if(x - this.radius < 0 || x + this.radius > width) this.vx *= -2.0;
    if(y - this.radius < 0 || y + this.radius > height) this.vy *= -2.0;
  }


  void display() {
    // Draw the ball
    fill(this.c);
    ellipse(this.x, this.y, this.radius * 2, this.radius * 2);
  }


  //simulation method
  void simulate(Fluid fluid, float dt){
    updateAcceleration(fluid);
    update(dt);
    display();
  }
}
