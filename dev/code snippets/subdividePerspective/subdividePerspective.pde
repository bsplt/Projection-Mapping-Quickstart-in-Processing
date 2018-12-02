void setup() {
  size(800, 800);
  noLoop();
}

void draw() {
  background(#1e1e1e);
  noFill();
  stroke(#f5f5f5);

  PVector[] points = new PVector[] {
    new PVector(200, 400), 
    new PVector(600, 50), 
    new PVector(750, 700), 
    new PVector(80, 650)   
  };

  line(points[0].x, points[0].y, points[1].x, points[1].y);
  line(points[1].x, points[1].y, points[2].x, points[2].y);
  line(points[2].x, points[2].y, points[3].x, points[3].y);
  line(points[3].x, points[3].y, points[0].x, points[0].y);

  subdividePerspecitive(points, 3);
}

void subdividePerspecitive(PVector[] points, int recursionSteps) {
  PVector middle = getLineIntersection(
    new PVector[] {
    points[0], points[2], points[1], points[3] 
    });

  ellipse(middle.x, middle.y, 10, 10);

  int steps = 15;
  float horizontalLerp = 0.0;
  float verticalLerp = 0.0;
  float horizontalIncrement = 0.5;
  float verticalIncrement = 0.5;

  for (int i = 0; i < steps; i++) {
    if (distanceFromLine(middle, 
      PVector.lerp(points[0], points[1], horizontalLerp + horizontalIncrement), 
      PVector.lerp(points[2], points[3], 1.0 - (horizontalLerp + horizontalIncrement))) 
      < distanceFromLine(middle, 
      PVector.lerp(points[0], points[1], horizontalLerp - horizontalIncrement), 
      PVector.lerp(points[2], points[3], 1.0 - (horizontalLerp - horizontalIncrement)))
      ) {
      horizontalLerp += horizontalIncrement;
    } else {
      horizontalLerp -= horizontalIncrement;
    }
    horizontalIncrement *= 0.5;

    if (distanceFromLine(middle, 
      PVector.lerp(points[1], points[2], verticalLerp + verticalIncrement), 
      PVector.lerp(points[3], points[0], 1.0 - (verticalLerp + verticalIncrement))) 
      < distanceFromLine(middle, 
      PVector.lerp(points[1], points[2], verticalLerp - verticalIncrement), 
      PVector.lerp(points[3], points[0], 1.0 - (verticalLerp - verticalIncrement)))
      ) {
      verticalLerp += verticalIncrement;
    } else {
      verticalLerp -= verticalIncrement;
    }
    verticalIncrement *= 0.5;
  }

  line(
    PVector.lerp(points[0], points[1], horizontalLerp).x, 
    PVector.lerp(points[0], points[1], horizontalLerp).y, 
    PVector.lerp(points[2], points[3], 1.0 - horizontalLerp).x, 
    PVector.lerp(points[2], points[3], 1.0 - horizontalLerp).y
    );

  line(
    PVector.lerp(points[1], points[2], verticalLerp).x, 
    PVector.lerp(points[1], points[2], verticalLerp).y, 
    PVector.lerp(points[3], points[0], 1.0 - verticalLerp).x, 
    PVector.lerp(points[3], points[0], 1.0 - verticalLerp).y
    );

  recursionSteps--;

  if (recursionSteps > 0) {
    {
      PVector[] newPoints = new PVector[] {
        points[0].copy(), 
        PVector.lerp(points[0], points[1], horizontalLerp), 
        middle.copy(), 
        PVector.lerp(points[3], points[0], 1.0 - verticalLerp)
      };
      subdividePerspecitive(newPoints, recursionSteps);
    }
    {
      PVector[] newPoints = new PVector[] { 
        PVector.lerp(points[0], points[1], horizontalLerp),
        points[1].copy(),
        PVector.lerp(points[1], points[2], verticalLerp),
        middle.copy()
      };
      subdividePerspecitive(newPoints, recursionSteps);
    }
    {
      PVector[] newPoints = new PVector[] {
        middle.copy(),
        PVector.lerp(points[1], points[2], verticalLerp),
        points[2].copy(),
        PVector.lerp(points[2], points[3], 1.0 - horizontalLerp)
      };
      subdividePerspecitive(newPoints, recursionSteps);
    }
    {
      PVector[] newPoints = new PVector[] {
        PVector.lerp(points[3], points[0], 1.0 - verticalLerp),
        middle.copy(),
        PVector.lerp(points[2], points[3], 1.0 - horizontalLerp),
        points[3].copy(),
      };
      subdividePerspecitive(newPoints, recursionSteps);
    }
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
