# Projection Mapping Quickstart in Processing

**Transform you Processing code easily and instantly into a mapped projection.**

## Documentation

More soon.

## Introduction

Projection Mapping can require a non-linear work flow, if you want your projection to be data-driven or interactive. Using code and open source software libraries for the programming language of your choice would be an obvious choice. Problem: The usage seems to be unnecessarily complicated. Plus a lot of them are abandoned Github repositories.

If you are in need of a library or just pieces of code, that will help you to instantly have results with your non-linear projection idea, this Processing sketch will be the right for you because I try to solve these problems.

My intention behind this project is to enable people (like my students), who are just learning their first lines of code, to instantly transfer their Processing sketches to a perfect projection mapping. The goal is simplicity, not limitation. More advanced users might want to take a look too. This code will dramatically speed up your progress.

You might be surprised how easy it is.

## What you need

* The great free software [Processing](https://processing.org/)
* A Processing sketch you want to project with perspective distortion (*mapping*)
* A projector - simple ones are enough to start
* The code from this repository (mainly Projection Mapper `projectionMapper.pde`)
* 2 minutes of time.

That's all.

## What it does

Once you have set up your sketch correctly, you can press play in Processing. Projection Mapper `projectionMapper.pde` will configure the rest for you. You are now able to distort the Processing sketch you want to project on the projector. It is of course not limited to one sketch - you can make use of as much sketches and projections as you like to.

To enter calibration mode just move your mouse over the projection. The necessary tools will appear. To leave calibration mode just don't move the mouse for five seconds. All changes will be saved automatically while calibration. When you re-run the sketch, the projection will just look like before.

You are able to move the corner points for distortion with your mouse by clicking and dragging. If you hold the `shift` key you can even move it more precisely. The big circle in the middle is a solo button. Press it if you have multiple corner points overlaying to only show the projection you want to work on.

### More advanced knowledge

Projection Mapper used two algorithms that will help you with projection mapping.

First there is an algorithm implemented from a paper about finding the ratio of a rectangle in a photograph. I reversed it to find the ratio of the surface you are projecting on. This automatically sets the `width` and `height` of your sketch.

Second there is an algorithm (wildly written by myself) that enables homographic interpolation. The obvious way, that I have seen in other open source projects, is to use bilinear interpolation to distort the imagery. This will look wrong though, if you don't project perpendicular to the surface. I fixed it.

## Usage

So, imagine you have a Processing sketch like this:

```java
void setup() {
    size(800, 800);
  }

  void draw() {
    background(#000000);
    stroke(#FFFFFF);
    for (int i = 0; i < 10; i++) {
      float x = (width / 10.0 * i + width / 1000.0 * frameCount) % width;
      line(x, 0, x, height);
    }
  }
```

This example is very basic and will show lines running from left to right.

To project this, you can easily copy and past your code into the `projectionQuickstart.pdf` example file. The basic requirement is Projection Mapper.

With some additional lines you will have a working projection:

```java
void setup() {
  fullScreen(P2D, 2);
  new ProjectionExample().calibrate("1");
}

void draw() {
}

// ---

class ProjectionExample extends Projection {
  void setup() {
    // size(800, 800);
  }

  void draw() {
    background(#000000);
    stroke(#FFFFFF);
    for (int i = 0; i < 10; i++) {
      float x = (width / 10.0 * i + width / 1000.0 * frameCount) % width;
      line(x, 0, x, height);
    }
  }
}

```

I pasted my sketch into the scope of a class called `ProjectionExample`. Inside this sketch everything is the same as in the example above. A minor difference: I uncommented the `size()` method because Projection Mapper will take care of this on its own. If I run this, I will be able to distort the imagery as I want to for the projection.

This is the work flow you need to do to test your sketch as a mapped projection.

### Adaptive Layout

Please note that you should write you code adaptively to the screen size. Because the width and height parameters of your sketch change dynamically, you should use them to to determine positions and dimensions.

As an example, this means you should write `float x = width / 10.0;` instead of `float x = 100.0;`.

### More advanced knowledge

The `ProjectionExample` class extends an abstract class of Projection Mapper called `Projection`. So to invoke your own class, let's say `OceanWaves`, you just have to write `class OceanWaves extends Projection { ... }`. Inside the scope you can paste your code.

To actually show the projection, you have to register it. The happens in the `setup()` method of the main sketch. You just call the class with the `new` keyword and add a unique identifier.

```java
new ProjectionExample().calibrate("1");
new OceanWaves().calibrate("2");
new OceanWaves().calibrate("3");
```

The code above would create three instances in your projection. Once the Example, two times your own sketch called `OceanWaves`. So you will see three planes that you can distort in your projection.

The unique identifier is necessary for Processing to remember the positions of the corners of your distortions. It enables the auto-saving functionality in the calibration process. It can be anything from `1`,  `2` over `left`, `right` to whatever you can imagine.

It the main `setup()` method you see `fullScreen(P2D, 2);` Full screen is necessary so that you don't see your OS interface in the projection. The `P2D` renderer parameter is necessary for the functionalities of Projection Mapper. With the additional `2` you ensure that the full screen is show on the second monitor output, which might be your projector.

Please note, that you still need to call the `draw()` method as above, even though it is empty. This is required by Projection Mapper.

## Examples

More soon.

## Future Development

As soon as I have finished development, I will only continue implementing features by request. So if you have ideas, found bugs or need a feature, feel free to contact me.

Sames applies for the documentation. If questions remain unanswered for you, please reach out and write for example an issue. I am happy to help.