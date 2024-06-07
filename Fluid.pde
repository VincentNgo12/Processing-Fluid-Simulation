class Fluid{ //Our main class!
  // Constants
  int SCALE;
  final float OVERRELAXATION = 1.9;
  final int X_FIELD = 0;
  final int Y_FIELD = 1;
  final int S_FIELD = 2;
  
  // These are the class properties, we will explain what they are below
  int numX, numY;
  float density, h, numCells;
  float[][] Vx, Vy, newVx, newVy, p, s, m, newM;  
  
  
  Fluid(float density, int numX, int numY, float h, int SCALE){
    this.density = density; //the physical density of the fluid(water is 1000)
    numX += 2; //the + 2 is taking account of the outer layer
    numY += 2;
    this.numX = numX; 
    this.numY = numY;
    this.numCells = this.numX * numY; //the total number of grid cells
    this.h = h;//the spacing of the grid's velocities
    this.Vx = Helper.create_2D_Float_Array(numX, numY, 0.0); //velocities of the grid
    this.Vy = Helper.create_2D_Float_Array(numX, numY, 0.0);
    this.newVx = Helper.create_2D_Float_Array(numX, numY, 0.0); //Another velocities array for computing purposes.
    this.newVy = Helper.create_2D_Float_Array(numX, numY, 0.0);
    this.p = Helper.create_2D_Float_Array(numX, numY, 0.0); //pressure array(not neccesary)
    this.s = Helper.create_2D_Float_Array(numX, numY, 1.0); //array 
    this.m = Helper.create_2D_Float_Array(numX, numY, 0.0);
    this.newM = Helper.create_2D_Float_Array(numX, numY, 0.0);

    // Set the boundaries
    for (int row=0; row<this.numY; row++) {
      for (int col=0; col<this.numX; col++) {
        float s = 1.0;  // fluid
        if (col == 0 || col == this.numX-3 || row == 0 || row == this.numY-3)
          s = 0.0;  // solid
        this.s[row][col] = s;
      }
    }

    this.SCALE = SCALE; //Scale to render the fluid on screen
  }
  

  // Simulate the fluid dynamics for a time step (main method)
  void simulate(float dt, int numIters){
    this.p = Helper.create_2D_Float_Array(numX, numY, 0.0); //Reinitialize the pressure array
    this.project(numIters, dt); //Force the fluid to be incompressible

    this.set_bnd(); //Set the properties of the boundary
    //Addvections!!!
    this.advectVel(dt);
    this.advectDensity(dt);
  }
  

  // Method to solve and enforces incompressibility on the fluid
  void project(int numIterations, float dt){
    float cp = this.density * this.h / dt; //Coefficient for pressure calculation
    
    /* This is the Gauss-seidel alogrithm to solve systems of equations. We repeatedly calculate the divergence
    (tje inflow and outflow of each grid) over and over again (numIterations) to make the values converges. That will
    be our solutions for the systems of equations!!! Short-story, the more iteration the more accurate (but it gets slow)*/
    for (int iter = 0; iter < numIterations; iter++) {
      for (int row = 1; row < this.numY-1; row++) {
        for (int col = 1; col < this.numX-1; col++) {
          
          if (this.s[row][col] == 0.0f) //Skip of current cell is not fluid cell
            continue;

          float sx0 = this.s[row][col-1];
          float sx1 = this.s[row][col+1];
          float sy0 = this.s[row-1][col];
          float sy1 = this.s[row+1][col];
          float s = sx0 + sx1 + sy0 + sy1;
          if (s == 0.0f) //skip
            continue;

          // Calculate divergence
          float div = this.Vx[row][col+1] - this.Vx[row][col] + 
            this.Vy[row+1][col] - this.Vy[row][col];

          float p = -div / s;
          p *= OVERRELAXATION; //Over relaxation (to make the values converges faster)
          this.p[row][col] += cp * p; //Calculate the pressure according to the formula
          
          //The rest will enforce incompressibility with the formula!
          this.Vx[row][col] -= sx0 * p;
          this.Vx[row][col+1] += sx1 * p;
          this.Vy[row][col] -= sy0 * p;
          this.Vy[row+1][col] += sy1 * p;
        }
      }
    }
  }


  // Method to set the boundary conditions
  void set_bnd(){
    //For the borders, we want them to have the same velocity as their neighboring grids
    for (int col=1; col<this.numX-1;col++) {
      this.Vx[0][col] = -this.Vx[1][col];
      this.Vx[this.numY-1][col] = -this.Vx[this.numY-2][col]; 
    }
    for (int row=1; row<this.numY-1; row++) {
      this.Vy[row][0] = -this.Vy[row][1];
      this.Vy[row][this.numX-1] = -this.Vy[row][this.numX-2];
    }
  }


  /*This is most troublesome method. This method is just use to get the interpolated values of four grids surrounding
   the given coordinate (x and y)*/
  float sampleField(float x, float y, int field){
    float h = this.h; //grid spacing
    float h1 = 1.0 / h; //reciprocal of grid spacing (we can also divide by h)
    float h2 = 0.5 * h; //half-grid offset
    
    //Clamp the values to fit within the grid
    x = constrain(x, h, this.numX * h);
    y = constrain(y, h, this.numY * h);

    float dx = 0.0;
    float dy = 0.0;

    float[][] f = new float[1][1];

    //The switch case to determine which what value is being interpolated
    switch (field) {
      case X_FIELD: f = this.Vx; dy = h2; break; //x velocity, offset the y grid (dy)
      case Y_FIELD: f = this.Vy; dx = h2; break; //y velocity, offset the x grid (dx)
      case S_FIELD: f = this.m; dx = h2; dy = h2; break; //the density, offset both x and y
    }
    
    // Calculate the grid indices and interpolation factors
    // x-axis
    int x0 = constrain(int((x-dx)*h1), 0, this.numX-1); //the grid index to the left of the coordinate
    float tx = ((x-dx) - x0*h) * h1; //The interpolation factor
    int x1 = constrain(x0 + 1, 0, this.numX-1);; //the grid index to the right
    
    //y-axis
    int y0 = constrain(int((y-dy)*h1), 0, this.numY-1); //The grid index to the top
    float ty = ((y-dy) - y0*h) * h1;//Another interpolation factor
    int y1 = constrain(y0 + 1, 0, this.numY-1); //the grid index to the bottom


    float sx = 1.0 - tx;//These are also interpolation factors but like... backwards
    float sy = 1.0 - ty;
    
    //finally!! calculate the interpolated value based on the formula
    float value = sx*sy * f[y0][x0] +
      tx*sy * f[y0][x1] +
      tx*ty * f[y1][x1] +
      sx*ty * f[y1][x0];
    
    return value;
  }


  // Get average velocities of 4 adjacent grids (X component)
  float avgVx(int x, int y) {
    float Vx = (this.Vx[y-1][x] + this.Vx[y][x] +
      this.Vx[y-1][x+1] + this.Vx[y][x+1]) * 0.25;
    return Vx;
  }
  
  // Get average velocities of 4 adjacent grids (Y component)
  float avgVy(int x, int y) {
    float Vy = (this.Vy[y][x-1] + this.Vy[y][x] +
      this.Vy[y+1][x-1] + this.Vy[y+1][x]) * 0.25;
    return Vy;
  }


  // Advect Velocities (move the velocity values over the vector field of the fluid over time)
  void advectVel(float dt){
    // Store the copy of the current velocities using Helper method
    this.newVx = Helper.copy_2D_Float_Array(this.Vx);
    this.newVy = Helper.copy_2D_Float_Array(this.Vy);

    float h = this.h; //grid spacing
    float h2 = 0.5 * h; //half-grid offset

    for (int row=1; row<this.numY-1; row++) {
      for (int col=1; col<this.numX-1; col++) {

        // x component
        if (this.s[row][col] != 0.0f && this.s[row][col-1] != 0.0f && row<this.numY - 1) {
          //We time the indicies by h to scale it down to the grid positions for calculations.
          //This scaled positions will be convert back to integer index in the sampleField method.
          float x = col*h;
          float y = row*h + h2;
          float Vx = this.Vx[row][col]; //the x velocity
          float Vy = this.avgVy(col, row); //the average of the y velocity
          //Trace backward (move in the opposite way of the velocities)
          x = x - dt*Vx;
          y = y - dt*Vy;
          Vx = this.sampleField(x,y, X_FIELD); //get the interpolated values
          this.newVx[row][col] = Vx; //we have our new X velocities!!!
        }
        // y component
        //same as above but we switch up a little bit
        if (this.s[row][col] != 0.0f && this.s[row-1][col] != 0.0f && col<this.numX - 1) {
          float x = col*h + h2;
          float y = row*h;
          float Vx = this.avgVx(col, row);
          float Vy = this.Vy[row][col];
          x = x - dt*Vx;
          y = y - dt*Vy;
          Vy = this.sampleField(x,y, Y_FIELD);
          this.newVy[row][col] = Vy;
        }
      }  
    }
    
    //Assign the calculated velocities, yay!!!
    this.Vx = Helper.copy_2D_Float_Array(this.newVx);
    this.Vy = Helper.copy_2D_Float_Array(this.newVy);
    return;
  }


  // same as advecting velocities but for fluid (the density)
  void advectDensity(float dt){
    // Copy the density array to newM using my Helper method
    this.newM = Helper.copy_2D_Float_Array(this.m);

    float h = this.h; //grid spacing
    float h2 = 0.5 * h; //half grid offset

    // Iterate through the array (ignore the outermost layer)
    for(int row=1; row<this.numY-1; row++) {
      for(int col=1; col<this.numX-1; col++) {

        if (this.s[row][col] != 0.0) { //if grid isn't a wall
          // Get average velocity components of the grid
          float Vx = (this.Vx[row][col] + this.Vx[row][col+1]) * 0.5;
          float Vy = (this.Vy[row][col] + this.Vy[row+1][col]) * 0.5;
          //Scaled the coordinate to grid, offset it, and then trace backward (go opposite velocities)
          float x = col*h + h2 - dt*Vx;
          float y = row*h + h2 - dt*Vy;

          this.newM[row][col] = this.sampleField(x,y, S_FIELD); //get the interolated value, which is our addvected density
        }
      }
    }

    // assign the new density array using my Helper method
    this.m = Helper.copy_2D_Float_Array(this.newM);
    return;
  }


  // Method to render Fluid
  void render(){
    noStroke();
    for ( int row=0 ; row<this.numY ; row++ ) {
      for ( int col=0 ; col<this.numX ; col++ ) {
        float x = col * SCALE;
        float y = row * SCALE;
        float d =  this.m[row][col];
        color dye = getCoolColor(d, 0.0f, 1.0f);
        fill(dye);
        if(this.s[row][col] == 0) fill(100);
        square(x, y, SCALE);
      }
    }
  }


  // Add velocities
  void addVelocity(int x, int y, float amountX, float amountY){
    this.Vx[y][x] = amountX;
    this.Vy[y][x] = amountY;
    return;
  }

  // Method to add (Dye) density
  void addDensity(int x, int y, float amount){
    this.m[y][x] = amount;
    return;
  }
  
  
    // Side method to get cool colors!
  color getCoolColor(float val, float minVal, float maxVal) {
    // Clamp the input value within the specified range
    val = constrain(val, minVal, maxVal-0.1);

    // Calculate the normalized value within the range [0, 1]
    float d = maxVal - minVal;
    val = (d == 0.0) ? 0.5 : (val - minVal) / d;

    // Define a multiplier and calculate the color index
    float m = 0.25f;
    int num = int(val / m);
    float s = (val - num * m) / m; // interpolation factor
    float r=0, g=0, b=0;
    float a = maxVal - val/1.1; //Transparency

    // Map the color based on the color index
    switch (num) {
        case 0: r = 0.0; g = s; b = 1.0; break;
        case 1: r = 0.0; g = 1.0; b = 1.0 - s; break;
        case 2: r = s; g = 1.0; b = 0.0; break;
        case 3: r = 1.0; g = 1.0 - s; b = 0.0; break;
    }

    // Scale and return the RGB color values with full alpha (255)
    return color(255*r, 255*g, 255*b, a*255);
  }
}
