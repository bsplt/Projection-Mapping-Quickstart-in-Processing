// TODO:
// Clean up
// Write documentation
// data loading

void setup() {
  fullScreen(P2D, 2);

  // Invoke your projection here:

  new ProjectionExample().calibrate("x");
}

void draw() {
}


class ProjectionExample extends Projection {

  // Put your Code here:

  void setup() {
  }

  void draw() {
    clear();
    stroke(#FFFFFF);
    for (int i = 0; i < 10; i++) {
      float x = (width / 10.0 * i + width / 1000.0 * frameCount) % width;
      line(x, 0, x, height);
    }
  }
}
