public class Projection { 
  PVector[] planePoints;
  ArrayList<SmallQuad> smallQuads;
  int[] size;
  PGraphics plane;
  boolean sizeChanged;

  public Projection() {
    sizeChanged = true;
    projectionManager.addProjection(this);
    smallQuads = new ArrayList();

    size = new int[] {
      500, 500
    };

    planePoints = new PVector[] {
      new PVector(width * 0.3333, height * 0.3333), 
      new PVector(width * 0.6666, height * 0.3333), 
      new PVector(width * 0.6666, height * 0.6666), 
      new PVector(width * 0.3333, height * 0.6666)
    };
  }

  public void projectionResize() {
    if (sizeChanged) {
      float ratio = 1.0;

      try {
        ratio = getRatio(planePoints);
      } 
      catch (Exception e) {
        println("something went wrong");
      }

      int resolution = 15;
      refreshSmallQuads(resolution);

      float maxDistance = 0;
      for (int i = 0; i < 3; i++) {
        for (int j = i+1; j < 4; j++) {
          maxDistance = max(PVector.dist(planePoints[i], planePoints[j]), maxDistance);
        }
      }

      ratio = max(ratio, 0.1);
      ratio = min(ratio, 10.0);

      size = new int[] {
        round(ratio > 1.0 ? maxDistance * ratio : maxDistance), 
        round(ratio > 1.0 ? maxDistance : maxDistance / ratio)
      };

      plane = createGraphics(size[0], size[1]);

      sizeChanged = false;
    }
  }

  public void setReady() {
    projectionResize();
    plane.beginDraw();
    plane.clear();
    plane.noFill();
    plane.stroke(#FFFFFF);
  }

  public void setFinished() {
    plane.endDraw();
  }

  public void applyProjection() {
    noStroke();
    beginShape(QUAD);
    textureMode(NORMAL);
    texture(plane);
    for (SmallQuad sq : smallQuads) {
      vertex(sq.e.x, sq.e.y, sq.uLow, sq.vLow);
      vertex(sq.f.x, sq.f.y, sq.uHigh, sq.vLow);
      vertex(sq.g.x, sq.g.y, sq.uHigh, sq.vHigh);
      vertex(sq.h.x, sq.h.y, sq.uLow, sq.vHigh);
    }
    endShape();
  }

  void refreshSmallQuads(int resolution) {
    smallQuads = new ArrayList();

    for (int i = 0; i < resolution; i++) {
      for (int j = 0; j < resolution; j++) {
        PVector ab0 = getQuadHeightPoints(planePoints[0].x, planePoints[0].y, planePoints[1].x, planePoints[1].y, float(i), resolution);
        PVector bc0 = getQuadHeightPoints(planePoints[1].x, planePoints[1].y, planePoints[2].x, planePoints[2].y, float(j), resolution); 
        PVector cd0 = getQuadHeightPoints(planePoints[3].x, planePoints[3].y, planePoints[2].x, planePoints[2].y, float(i), resolution);
        PVector da0 = getQuadHeightPoints(planePoints[0].x, planePoints[0].y, planePoints[3].x, planePoints[3].y, float(j), resolution);
        PVector ab1 = getQuadHeightPoints(planePoints[0].x, planePoints[0].y, planePoints[1].x, planePoints[1].y, float(i + 1), resolution);
        PVector bc1 = getQuadHeightPoints(planePoints[1].x, planePoints[1].y, planePoints[2].x, planePoints[2].y, float(j + 1), resolution); 
        PVector cd1 = getQuadHeightPoints(planePoints[3].x, planePoints[3].y, planePoints[2].x, planePoints[2].y, float(i + 1), resolution);
        PVector da1 = getQuadHeightPoints(planePoints[0].x, planePoints[0].y, planePoints[3].x, planePoints[3].y, float(j + 1), resolution);

        PVector e = getHeightIntersection(ab0, cd0, da0, bc0);
        PVector f = getHeightIntersection(ab1, cd1, da0, bc0);
        PVector g = getHeightIntersection(ab1, cd1, da1, bc1);
        PVector h = getHeightIntersection(ab0, cd0, da1, bc1);

        float uLow = (float) i / resolution;
        float uHigh = (float) (i + 1) / resolution;
        float vLow = (float) j / resolution;
        float vHigh = (float) (j + 1) / resolution;

        smallQuads.add(new SmallQuad(e, f, g, h, uLow, uHigh, vLow, vHigh));
      }
    }
  }

  PVector getQuadHeightPoints(float x0, float y0, float x1, float y1, float step, int resolution) {
    return new PVector((x1 - x0) * (step / resolution) + x0, (y1 - y0) * (step / resolution) + y0);
  }

  PVector getHeightIntersection(PVector p1, PVector p2, PVector p3, PVector p4) {
    PVector b = PVector.sub(p2, p1);
    PVector d = PVector.sub(p4, p3);
    float b_dot_d_perp = b.x * d.y - b.y * d.x;
    PVector c = PVector.sub(p3, p1);
    float t = (c.x * d.y - c.y * d.x) / b_dot_d_perp;
    float u = (c.x * b.y - c.y * b.x) / b_dot_d_perp;
    return new PVector(p1.x+t*b.x, p1.y+t*b.y);
  }

  float getRatio(PVector[] planePoints)
  // https://stackoverflow.com/questions/1194352/proportions-of-a-perspective-deformed-rectangle
  // https://stackoverflow.com/questions/38285229/calculating-aspect-ratio-of-perspective-transform-destination-image
  {
    PVector principalPoint = new PVector(width * 0.5, height * 0.5);

    float m1x = planePoints[3].x - principalPoint.x;
    float m1y = planePoints[3].y - principalPoint.y;
    float m2x = planePoints[2].x - principalPoint.x;
    float m2y = planePoints[2].y - principalPoint.y;
    float m3x = planePoints[0].x - principalPoint.x;
    float m3y = planePoints[0].y - principalPoint.y;
    float m4x = planePoints[1].x - principalPoint.x;
    float m4y = planePoints[1].y - principalPoint.y;

    float k2 = ((m1y - m4y)*m3x - (m1x - m4x)*m3y + m1x*m4y - m1y*m4x) /
      ((m2y - m4y)*m3x - (m2x - m4x)*m3y + m2x*m4y - m2y*m4x) ;

    float k3 = ((m1y - m4y)*m2x - (m1x - m4x)*m2y + m1x*m4y - m1y*m4x) /
      ((m3y - m4y)*m2x - (m3x - m4x)*m2y + m3x*m4y - m3y*m4x) ;

    float f_squared =
      -((k3*m3y - m1y)*(k2*m2y - m1y) + (k3*m3x - m1x)*(k2*m2x - m1x)) /
      ((k3 - 1)*(k2 - 1)) ;

    float whRatio = sqrt(
      (pow((k2 - 1), 2) + pow((k2*m2y - m1y), 2)/f_squared + pow((k2*m2x - m1x), 2)/f_squared) /
      (pow((k3 - 1), 2) + pow((k3*m3y - m1y), 2)/f_squared + pow((k3*m3x - m1x), 2)/f_squared)
      );

    if (abs(k2 - 1.0) < 0.001 && abs(k3 - 1.0) < 0.001) {
      whRatio = sqrt(
        (pow((m2y-m1y), 2) + pow((m2x-m1x), 2)) /
        (pow((m3y-m1y), 2) + pow((m3x-m1x), 2)));
    }

    return whRatio;
  }



  // ---

  public void setup() {
  }

  public void draw() {
  }

  public void size() {
  }

  public void background(color col) {
    plane.background(col);
  }

  public void line(float a, float b, float c, float d) {
    plane.line(a * size[0], b * size[1], c * size[0], d * size[1]);
  }

  public void rect(float a, float b, float c, float d) {
    plane.rect(a * size[0], b * size[1], c * size[0], d * size[1]);
  }

  public void ellipse(float a, float b, float c, float d) {
    plane.ellipse(a * size[0], b * size[1], c * size[0], d * size[1]);
  }

  public void ellipse(float a, float b, float c) {
    plane.ellipse(a * size[0], b * size[1], c * min(size[0], size[1]), c * min(size[0], size[1]));
  }

  public void noStroke() {
    plane.noStroke();
  }

  public void noFill() {
    plane.noFill();
  }

  public void fill(color col) {
    plane.fill(col);
  }

  public void stroke(color col) {
    plane.stroke(col);
  }

  public void strokeWeight(int thickness) {
    plane.strokeWeight(thickness);
  }
}

class SmallQuad {
  /* This class stores the coordinates and UV coordinates of a grid unit of a Plane depending on the resolution.
   It's a wrapper without functions for convenience. */

  PVector e, f, g, h;
  float uLow, uHigh, vLow, vHigh;

  SmallQuad(PVector eIn, PVector fIn, PVector gIn, PVector hIn, float uLowIn, float uHighIn, float vLowIn, float vHighIn) {
    e = eIn;
    f = fIn;
    g = gIn;
    h = hIn;
    uLow = uLowIn;
    uHigh = uHighIn;
    vLow = vLowIn;
    vHigh = vHighIn;
  }
}

public class ProjectionManager {
  private ArrayList<Projection> projections;

  private int lastMouseCheck, lastMouseActive, mouseTravel;
  private boolean calibrating, pmousePressed, changedSomething;
  private PVector calibrationPoint, mouseClickPoint, mouseClickOffset;
  private Projection changedProjection;

  public ProjectionManager(PApplet parent) {
    parent.registerMethod("draw", this);
    projections = new ArrayList();

    lastMouseCheck = millis();
    lastMouseActive = millis();
    mouseTravel = 0;
    calibrating = false;
    pmousePressed = false;
    changedSomething = false;
  }

  public void addProjection(Projection projection) {
    projections.add(projection);
  }

  public void draw() {
    showProjections();
    calibrate();
  }

  private void showProjections() {
    //clear();
    noStroke();

    for (Projection projection : projections) {
      projection.setReady();
      projection.draw();
      projection.setFinished();
      projection.applyProjection();
    }
  }

  private void calibrate() {
    int activateThreshold = 5;
    int activateTime = 500;
    int deactivateTime = 5000;
    float size = min(width, height) * 0.02;

    mouseTravel += dist(pmouseX, pmouseY, mouseX, mouseY);

    if (lastMouseCheck < millis() - activateTime) {
      if (mouseTravel > activateThreshold) {
        lastMouseActive = millis();

        if (!calibrating) {
          calibrating = true;
          cursor();
        }
      }
      lastMouseCheck = millis();
      mouseTravel = 0;
    }

    if (calibrating) {
      if (lastMouseActive < millis() - deactivateTime) {
        calibrating = false;
        noCursor();
      }
    }

    if (calibrating) {      
      noFill();
      stroke(#FFFFFF);
      strokeWeight(1);

      for (Projection projection : projections) {
        beginShape(QUAD);
        for (PVector corner : projection.planePoints) {
          vertex(corner.x, corner.y);
        }
        endShape(CLOSE);

        for (PVector corner : projection.planePoints) {
          ellipse(corner.x, corner.y, size * 2, size * 2);
          line(corner.x - size, corner.y, corner.x + size, corner.y);
          line(corner.x, corner.y - size, corner.x, corner.y + size);
        }
      }

      if (mousePressed && !pmousePressed) {
        pmousePressed = true;
        calibrationPoint = null;
        changedProjection = null;
        changedSomething = false;
        mouseClickPoint = new PVector(mouseX, mouseY);

        for (Projection projection : projections) {
          for (PVector corner : projection.planePoints) {
            if (dist(mouseX, mouseY, corner.x, corner.y) < size) {
              calibrationPoint = corner;
              mouseClickOffset = PVector.sub(calibrationPoint, mouseClickPoint);
              changedSomething = true;
              changedProjection = projection;
              break;
            }
          }
        }
      }

      if (mousePressed && pmousePressed) {
        if (calibrationPoint != null) {
          float lerp = 1.0;
          if (keyPressed && keyCode == SHIFT) {
            lerp = 0.2;
          }
          calibrationPoint.x = lerp(mouseClickPoint.x + mouseClickOffset.x, mouseX + mouseClickOffset.x, lerp);
          calibrationPoint.y = lerp(mouseClickPoint.y + mouseClickOffset.y, mouseY + mouseClickOffset.y, lerp);
        }
      }

      if (!mousePressed && pmousePressed) {
        pmousePressed = false;
        calibrationPoint = null;
        if (changedSomething) {
          changedProjection.sizeChanged = true;
        }
      }
    }
  }
}

ProjectionManager projectionManager = new ProjectionManager(this); 
