PImage img;

void setup() {
  size(800, 800, P2D);
  new Test();
  img = loadImage("test-bg2.jpg");
}

void draw() {
  image(img, 0, 0, width, height);
}

class Test extends Projection {
  void draw() {
    //background(#212121);
    line(0, 0, 1, 1);
    line(0, 1, 1, 0);
    //float x = map(frameCount % 120, 0, 120, 0, 1);
    //line(x, 0, x, 1);
    //line(0, 0.5, 1, 0.5);

    ellipse(0.5, 0.2, 0.2);
  }
}
