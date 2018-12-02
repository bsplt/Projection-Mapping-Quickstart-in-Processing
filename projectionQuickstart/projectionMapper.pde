/*
 *        ___         ___  
 *       /  /\       /__/\    
 *      /  /::\     |  |::\   
 *     /  /:/\:\    |  |:|:\  
 *    /  /:/-/:/  __|__|:|\:\ 
 *   /__/:/ /:/  /__/::::| \:\
 *   \  \:\/:/   \  \:\--\__\/
 *    \  \::/     \  \:\      
 *     \  \:\      \  \:\     
 *      \  \:\      \  \:\    
 *       \__\/       \__\/ 
 *
 *    Projection Mapper
 *
 *    by Alexander Lehmann
 *    github.com/bsplt
 *
 *    Send me your requests on github.
 *
 *
 * About:
 *   This file is a tool for creating projection mappings in Processing instantaneously.
 *   You can (almost) copy past your existing Processing code to a projection map. Easy!
 *   It will provide you with all the necessary features for projection mapping on rectangles.
 *
 * Instructions:
 * - Drop this file "projectionMapper.pde" into your sketch folder.
 * - Extend the Projection class like this:
 *   class Example extends Projection { ... }
 * - Inside the scope of this class you can write like a regular Processing sketch.
 *   You use setup() to initialize variables and draw() like you would normally.
 *   Drawing attributes (e.g. strokeWeight() or fill()) cannot be inside setup().
 *   They have to be inside draw().
 * - You can of course declare varibales globally (inside the scope)
 *   if you want to access them longer then one draw loop.
 * - Initialize your projections like this in your regular setup function:
 *   new Example().calibrate("1");
 *   You don't need to assign it to a variable.
 *   Using the calibrate("..") function saves your modifications
 *   to the projection transformation between runs of the sketch.
 *   The String inside the function (e.g. "1") has to be a unique id for
 *   loading the transformation in the next run of the sketch.
 * - When you move the mouse you enter calibration mode.
 *   Drag the corners to the desired position in the projection.
 *   The transformation will be saved automatically.
 * - The calibration file is saved as a CSV in the data folder of the sketch.
 * - Be aware that the width and height values (of your projection) change depeneding
 *   on the transformation so write your code accordingly (ie. adpatively).
 */


import java.util.*;

public abstract class Projection { 
  PVector[] planePoints;
  ArrayList<SmallQuad> smallQuads;
  PGraphics plane;
  boolean sizeChanged;
  String id;

  public Projection() {
    projectionManager.addProjection(this);
    projectionManager.loadCalibration();
    init();
  }

  private void init() {
    smallQuads = new ArrayList();
    id = "unnamed";
    sizeChanged = true;
    PApplet p = projectionManager.parent;

    planePoints = new PVector[] {
      new PVector(p.width * 0.3333, p.height * 0.3333), 
      new PVector(p.width * 0.6666, p.height * 0.3333), 
      new PVector(p.width * 0.6666, p.height * 0.6666), 
      new PVector(p.width * 0.3333, p.height * 0.6666)
    };
  }

  // ---

  public void calibrate(String id) {
    this.id = id;
    PVector[] calibration = projectionManager.getCalibration(id);
    if (calibration == null) {
      return;
    }
    for (int i = 0; i < 4; i++) {
      planePoints[i] = calibration[i];
    }
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

      int resolution = 5;
      refreshSmallQuads(resolution);

      float maxDistance = 0;
      for (int i = 0; i < 3; i++) {
        for (int j = i+1; j < 4; j++) {
          maxDistance = max(PVector.dist(planePoints[i], planePoints[j]), maxDistance);
        }
      }

      ratio = max(ratio, 0.1);
      ratio = min(ratio, 10.0);

      width = round(ratio > 1.0 ? maxDistance * ratio : maxDistance); 
      height = round(ratio > 1.0 ? maxDistance : maxDistance / ratio);
      plane = createGraphics(width, height);
      setup();

      println("Set projection \"" + id + "\" to a ratio of 1:" + ratio + " with the dimensions of " + width + " by " + height + ".");

      sizeChanged = false;
    }
  }

  public void setReady() {
    projectionResize();
    plane.beginDraw();
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

  // ---

  void refreshSmallQuads(int resolution) {
    smallQuads = new ArrayList();

    ArrayList<ArrayList> lerps = subdividePerspecitive(planePoints, resolution);

    Float[] lerpsHorizontal = new Float[lerps.get(0).size()];
    lerpsHorizontal = (Float[]) lerps.get(0).toArray(lerpsHorizontal);
    Float[] lerpsVertical = new Float[lerps.get(1).size()];
    lerpsVertical = (Float[]) lerps.get(1).toArray(lerpsVertical);

    for (int i = 0; i < lerpsHorizontal.length - 1; i++) {
      for (int j = 0; j < lerpsVertical.length - 1; j++) {
        ArrayList<PVector> points = new ArrayList();
        for (int k = 0; k < 2; k++) {
          for (int l = 0; l < 2; l++) {
            PVector point = getLineIntersection(new PVector[] {
              PVector.lerp(planePoints[0], planePoints[1], lerpsHorizontal[i+k]), 
              PVector.lerp(planePoints[3], planePoints[2], lerpsHorizontal[i+k]), 
              PVector.lerp(planePoints[0], planePoints[3], lerpsVertical[j+l]), 
              PVector.lerp(planePoints[1], planePoints[2], lerpsVertical[j+l])
              });
            points.add(point);
          }
        }

        float uLow = (float) i / (lerpsHorizontal.length-1);
        float uHigh = (float) (i + 1) / (lerpsHorizontal.length-1);
        float vLow = (float) j / (lerpsVertical.length-1);
        float vHigh = (float) (j + 1) / (lerpsVertical.length-1);

        smallQuads.add(new SmallQuad(points.get(0), points.get(2), points.get(3), points.get(1), uLow, uHigh, vLow, vHigh));
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
    } else if (param > 1) {
      xx = lineB.x;
      yy = lineB.y;
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
    PApplet p = projectionManager.parent;
    PVector principalPoint = new PVector(p.width * 0.5, p.height * 0.5);

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
  
  /* TODO:
  save
  saveFrame
  
  
  
  applyMatrix
  popMatrix
  printMatrix
  pushMatrix
  resetMatrix
  rotate
  scale
  shearX
  shearY
  translate
  
  arc
  point
  quad
  triangle
  
  shape
  image
  imageMode
  tint
  
  bezier
  bezierDetail
  curve
  curveDetail
  curveTightness
  
  beginContour
  beginShape
  bezierVertex
  curveVertex
  endContour
  endShape
  quadraticVertex
  vertex
  texture
  textureMode
  textureWrap
  
  clip
  
  text
  textFont
  textAlign
  textLeading
  textMode
  textSize
  textWidth
  textAscent
  textDescent
  
  */

  int width, height;

  public void setup() {
    // Override this!
  }

  public void draw() {
    // Override this!
  }

  public void size() {
    println("Size is set automatically. Don't use size().");
  }

  public void background(color col) {
    plane.background(col);
  }

  public void clear() {
    plane.clear();
  }

  public void line(float a, float b, float c, float d) {
    plane.line(a, b, c, d);
  }

  public void rect(float a, float b, float c, float d) {
    plane.rect(a, b, c, d);
  }

  public void ellipse(float a, float b, float c, float d) {
    plane.ellipse(a, b, c, d);
  }

  public void colorMode(int mode) {
    plane.colorMode(mode);
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

  public void strokeJoin(int mode) {
    plane.strokeJoin(mode);
  }

  public void strokeCap(int mode) {
    plane.strokeCap(mode);
  }

  public void rectMode(int mode) {
    plane.rectMode(mode);
  }

  public void ellipseMode(int mode) {
    plane.ellipseMode(mode);
  }

  public void blendMode(int mode) {
    plane.blendMode(mode);
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

  public PApplet parent;
  private Table calibrationData;
  public boolean hasLoadedCalibrationData; 

  public ProjectionManager(PApplet parent) {
    this.parent = parent;
    parent.registerMethod("draw", this);
    parent.registerMethod("pre", this);

    projections = new ArrayList();
    lastMouseCheck = millis();
    lastMouseActive = millis();
    mouseTravel = 0;
    calibrating = false;
    pmousePressed = false;
    changedSomething = false;
    hasLoadedCalibrationData = false;
  }

  public void addProjection(Projection projection) {
    projections.add(projection);
  }

  public void pre() {
    clear();
  }

  public void draw() {
    showProjections();
    calibrate();
  }

  private void showProjections() {
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
          saveCalibration(changedProjection);
        }
      }
    }
  }

  public PVector[] getCalibration(String id) {
    if (!hasLoadedCalibrationData) {
      loadCalibration();
    }

    TableRow current = calibrationData.findRow(id, 0);
    if (current == null) {
      return null;
    }

    PVector[] points = new PVector[] {
      new PVector(current.getFloat("ax"), current.getFloat("ay")), 
      new PVector(current.getFloat("bx"), current.getFloat("by")), 
      new PVector(current.getFloat("cx"), current.getFloat("cy")), 
      new PVector(current.getFloat("dx"), current.getFloat("dy")), 
    };

    return points;
  }

  private void loadCalibration() {
    calibrationData = null;
    try {
      calibrationData = loadTable("data/calibration.csv", "header");
    } 
    catch (Exception e) {
    }

    if (calibrationData == null) {
      println("The sketch is not calibrated yet. The calibration will be saved automatically.");
      calibrationData = new Table();
      calibrationData.addColumn("ID", Table.STRING);
      calibrationData.addColumn("ax", Table.FLOAT);
      calibrationData.addColumn("ay", Table.FLOAT);
      calibrationData.addColumn("bx", Table.FLOAT);
      calibrationData.addColumn("by", Table.FLOAT);
      calibrationData.addColumn("cx", Table.FLOAT);
      calibrationData.addColumn("cy", Table.FLOAT);
      calibrationData.addColumn("dx", Table.FLOAT);
      calibrationData.addColumn("dy", Table.FLOAT);
    }

    hasLoadedCalibrationData = true;
  }

  private void saveCalibration(Projection projection) {
    TableRow current = calibrationData.findRow(projection.id, 0);
    if (current == null) {
      current = calibrationData.addRow();
      current.setString("ID", projection.id);
    }
    current.setFloat("ax", projection.planePoints[0].x);
    current.setFloat("ay", projection.planePoints[0].y);
    current.setFloat("bx", projection.planePoints[1].x);
    current.setFloat("by", projection.planePoints[1].y);
    current.setFloat("cx", projection.planePoints[2].x);
    current.setFloat("cy", projection.planePoints[2].y);
    current.setFloat("dx", projection.planePoints[3].x);
    current.setFloat("dy", projection.planePoints[3].y);

    saveTable(calibrationData, "data/calibration.csv");
  }
}

ProjectionManager projectionManager = new ProjectionManager(this); 
