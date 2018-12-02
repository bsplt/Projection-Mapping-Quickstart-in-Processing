PImage img;

void setup() {
  size(800, 800, P2D);
  new Test().calibrate("1");
  new Test().calibrate("2");
  new Test().calibrate("3");
  
  img = loadImage("test-bg2.jpg");
}

void draw() {
  image(img, 0, 0, width, height);
}

class Test extends Projection {
  PVector ball, velocity;
  float radius;

  void setup() {
    ball = new PVector();
    radius = min(width, height) * 0.1;
    velocity = PVector.random2D().mult(radius * 0.1);
  }

  void draw() {
    clear();
    ball.add(velocity);
    if (ball.x < radius) {
      ball.x = radius;
      velocity.x *= -1;
    }
    if (ball.y < radius) {
      ball.y = radius;
      velocity.y *= -1;
    }
    if (ball.x > width - radius) {
      ball.x = width - radius;
      velocity.x *= -1;
    }
    if (ball.y > height - radius) {
      ball.y = height - radius;
      velocity.y *= -1;
    }
    strokeWeight(2);
    ellipseMode(RADIUS);
    fill(#FF0000);
    ellipse(ball.x, ball.y, radius, radius);
  }
}
