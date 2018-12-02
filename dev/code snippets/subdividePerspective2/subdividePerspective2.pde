void setup() {
  size(800, 800);
  noLoop();
}

void draw() {
  background(#1e1e1e);
  noFill();
  stroke(#f5f5f5);

  PVector[] points = new PVector[] {
    new PVector(200, 350), 
    new PVector(600, 50), 
    new PVector(600, 750), 
    new PVector(200, 450)   
  };

  line(points[0].x, points[0].y, points[1].x, points[1].y);
  line(points[1].x, points[1].y, points[2].x, points[2].y);
  line(points[2].x, points[2].y, points[3].x, points[3].y);
  line(points[3].x, points[3].y, points[0].x, points[0].y);

  subdividePerspecitive(points, 4);
}

import java.util.*;

void subdividePerspecitive(PVector[] points, int recursionSteps) {
  ArrayList<Float> lerpsHorizontal = new ArrayList();
  getPerspectivicalSubdivisionLerps(
    new PVector[] {points[0], points[1]}, new PVector[] {points[3], points[2]}, 
    lerpsHorizontal, recursionSteps, 0.0, 1.0
    );
  Collections.sort(lerpsHorizontal);
  
  ArrayList<Float> lerpsVertical = new ArrayList();
  getPerspectivicalSubdivisionLerps(
    new PVector[] {points[0], points[3]}, new PVector[] {points[1], points[2]}, 
    lerpsVertical, recursionSteps, 0.0, 1.0
    );
  Collections.sort(lerpsVertical);

  for (float lerp : lerpsHorizontal) {
    PVector A = PVector.lerp(points[0], points[1], lerp);
    PVector B = PVector.lerp(points[3], points[2], lerp);
    line(A.x, A.y, B.x, B.y);
  }
  for (float lerp : lerpsVertical) {
    PVector A = PVector.lerp(points[0], points[3], lerp);
    PVector B = PVector.lerp(points[1], points[2], lerp);
    line(A.x, A.y, B.x, B.y);
  }
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
