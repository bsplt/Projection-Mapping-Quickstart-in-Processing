void setup() {
  size(800, 800, P2D);
  new Test();
}

void draw() {
  PImage img = loadImage("test-bg.jpg");
  image(img, 0, 0, width, height);
}

class Test extends Projection {
  void draw() {
    background(#212121);
    line(0, 0, 1, 1);
    line(0, 1, 1, 0);
    line(0.5, 0, 0.5, 1);
    line(0, 0.5, 1, 0.5);

    ellipse(0.5, 0.5, 0.2);
  }
}
