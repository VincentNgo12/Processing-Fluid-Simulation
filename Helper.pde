static class Helper{
  static float[][] copy_2D_Float_Array(float[][] originalArray){
    // Get the dimensions of the original array
    int rows = originalArray.length;
    int columns = originalArray[0].length;

    // Create a new array with the same dimensions
    float[][] array = new float[rows][columns];

    // Copy the values from the original array to the new array
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
          array[row][col] = originalArray[row][col];
      }
    }

    return array;
  }
  
  
  static float[][] create_2D_Float_Array(int numX, int numY, float value){
    float[][] array = new float[numY][numX];
    
    for (int row = 0; row < numY; row++) {
      for (int col = 0; col < numX; col++) {
        array[row][col] = value;
      }
    }

    return array;
  }
  
  
 //This side method will assign a unique index to a char (key pressed)
  static int char_to_index(char key){
    int index = -1; //initialize variable
    //switch case to assign index
    switch(key){
      case 'a': index=0; break;
      case 'd': index=1; break;
      case 'w': index=2; break;
      case 's': index=3; break;
    }
    
    return index; //return index
  }
}
