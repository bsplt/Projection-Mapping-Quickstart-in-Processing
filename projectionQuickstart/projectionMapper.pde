import java.util.*;

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

      int resolution = 1;
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

    ArrayList<ArrayList> lerps = subdividePerspecitive(planePoints, resolution);

    Float[] horizontalLerps = new Float[lerps.get(0).size()];
    horizontalLerps = (Float[]) lerps.get(0).toArray(horizontalLerps);
    Float[] verticalLerps = new Float[lerps.get(1).size()];
    verticalLerps = (Float[]) lerps.get(1).toArray(verticalLerps);

    for (int i = 0; i < horizontalLerps.length - 1; i++) {
      for (int j = 0; j < verticalLerps.length - 1; j++) {
        ArrayList<PVector> points = new ArrayList();
        for (int k = 0; k < 2; k++) {
          for (int l = 0; l < 2; l++) {
            PVector point = getLineIntersection(new PVector[] {
              PVector.lerp(planePoints[0], planePoints[1], horizontalLerps[i+k]), 
              PVector.lerp(planePoints[3], planePoints[2], horizontalLerps[i+k]), 
              PVector.lerp(planePoints[0], planePoints[3], verticalLerps[j+l]), 
              PVector.lerp(planePoints[1], planePoints[2], verticalLerps[j+l])
              });
            points.add(point);
          }
        }
        smallQuads.add(new SmallQuad(points.get(0), points.get(2), points.get(3), points.get(1), horizontalLerps[i], horizontalLerps[i+1], verticalLerps[j], verticalLerps[j+1]));
      }
    }
  }

  ArrayList<ArrayList> subdividePerspecitive(PVector[] points, int recursionSteps) {
    ArrayList<Float> lerpsHorizontal = new ArrayList();
    getPerspectivicalSubdivisionLerps(
      new PVector[] {points[0], points[1]}, new PVector[] {points[3], points[2]}, 
      lerpsHorizontal, recursionSteps, 0.0, 1.0
      );
    lerpsHorizontal.add(0.0);
    lerpsHorizontal.add(1.0);
    Collections.sort(lerpsHorizontal);

    ArrayList<Float> lerpsVertical = new ArrayList();
    getPerspectivicalSubdivisionLerps(
      new PVector[] {points[0], points[3]}, new PVector[] {points[1], points[2]}, 
      lerpsVertical, recursionSteps, 0.0, 1.0
      );
    lerpsVertical.add(0.0);
    lerpsVertical.add(1.0);
    Collections.sort(lerpsVertical);

    ArrayList<ArrayList> lerps = new ArrayList();
    lerps.add(lerpsHorizontal);
    lerps.add(lerpsVertical);

    return lerps;
  }

  void getPerspectivicalSubdivisionLerps(PVector[] line1, PVector[] line2, ArrayList<Float> lerps, int recursionSteps, float low, float high) {
    PVector middle = getLineIntersection(
      new PVector[] {
      line1[0], line2[1], line2[0], line1[1] 
      });

    int steps = 15;
    float lerp = 0.0;
    float increment = 0.5;

    for (int i = 0; i < steps; i++) {
      if (
        distanceFromLine(middle, 
        PVector.lerp(line1[0], line1[1], lerp + increment), 
        PVector.lerp(line2[0], line2[1], lerp + increment)) <
        distanceFromLine(middle, 
        PVector.lerp(line1[0], line1[1], lerp - increment), 
        PVector.lerp(line2[0], line2[1], lerp - increment)))
      {
        lerp += increment;
      } else {
        lerp -= increment;
      }
      increment *= 0.5;
    }

    lerps.add(map(lerp, 0.0, 1.0, low, high));
    recursionSteps--;

    if (recursionSteps > 0) {
      getPerspectivicalSubdivisionLerps(
        new PVector[] {line1[0], PVector.lerp(line1[0], line1[1], lerp)}, new PVector[] {line2[0], PVector.lerp(line2[0], line2[1], lerp)}, 
        lerps, recursionSteps, low, map(lerp, 0.0, 1.0, low, high)
        );

      getPerspectivicalSubdivisionLerps(
        new PVector[] { PVector.lerp(line1[0], line1[1], lerp), line1[1]}, new PVector[] {PVector.lerp(line2[0], line2[1], lerp), line2[1]}, 
        lerps, recursionSteps, map(lerp, 0.0, 1.0, low, high), high
        );
    }
  }

  PVector getLineIntersection(PVector[] lines) {
    float x12 = lines[0].x - lines[1].x;
    float x34 = lines[2].x - lines[3].x;
    float y12 = lines[0].y - lines[1].y;
    float y34 = lines[2].y - lines[3].y;

    float c = x12 * y34 - y12 * x34;
    float a = lines[0].x * lines[1].y - lines[0].y * lines[1].x;
    float b = lines[2].x * lines[3].y - lines[2].y * lines[3].x;

    float x = (a * x34 - b * x12) / c;
    float y = (a * y34 - b * y12) / c;

    return new PVector(x, y);
  }

  float distanceFromLine(PVector pos, PVector lineA, PVector lineB) {
    float a = pos.x - lineA.x;
    float b = pos.y - lineA.y;
    float c = lineB.x - lineA.x;
    float d = lineB.y - lineA.y;

    float dot = a * c + b * d;
    float lenSq = c * c + d * d;
    float  param = -1;
    if (lenSq != 0) //in case of 0 length line
      param = dot / lenSq;

    float xx, yy;

    if (param < 0) {
      xx = lineA.x;
      yy = lineA.y;
      ;
    } else if (param > 1) {
      xx = lineB.x;
      yy = lineB.y;
      ;
    } else {
      xx = lineA.x + param * c; 
      yy = lineA.y + param * d;
    }

    float dx = pos.x - xx;
    float dy = pos.y - yy;
    return sqrt(dx * dx + dy * dy);
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
        line(projection.planePoints[0].x, projection.planePoints[0].y, projection.planePoints[2].x, projection.planePoints[2].y);
        line(projection.planePoints[1].x, projection.planePoints[1].y, projection.planePoints[3].x, projection.planePoints[3].y);
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
