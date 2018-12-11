// TODO:
// Solo mode
// Clean up
// Write documentation

void setup() {
  fullScreen(P2D, 2);
  
  // Invoke your projection here:
  
  new ProjectionExample().calibrate("1");
}

void draw() {
  clear(); // ?
}


class ProjectionExample extends Projection {

  // Put your Code here:

  void setup() {
  }

  void draw() {
    clear();
    noStroke();
    fill(#FFFFFF);
    ellipse(width * 0.5, height * 0.5, height * 0.2, height * 0.2);
  }
}
