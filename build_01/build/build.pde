/*
 * Pen Plotter Design Generator (With Radiused Corners)
 *
 * Key Controls:
 * - 'T' or 't': Toggle the display of the parameters panel.
 * - 'G' or 'g': Generate a new design with random paths.
 * - 'E' or 'e': Export the current design to an SVG file.
 * - Arrow Up: Increase grid size (snapping resolution).
 * - Arrow Down: Decrease grid size (snapping resolution).
 * - Arrow Left: Decrease the number of layers.
 * - Arrow Right: Increase the number of layers.
 * - 'D' or 'd': Decrease plot density.
 * - 'I' or 'i': Increase plot density.
 * - 'L' or 'l': Toggle lead-in lines.
 * - '[', ']': Decrease or increase the direction change frequency.
 */

import processing.svg.*;

int gridSize = 20;
int directionChangeFrequency = 10; // Smaller values increase turns
int cornerRadius = 10;
int layerCount = 4;
int plotDensity = 10;
String uniqueID;
boolean displayParams = true;
boolean leadIn = true;

ArrayList<ArrayList<PVector>> paths;
color[] layerColors;

void setup() {
  size(800, 800);
  noLoop();
  generateDesign();
}

void draw() {
  background(255);
  // Draw the boundary box
  //stroke(0); // Set the stroke color to black
  //noFill(); // No fill for the rectangle
  //strokeWeight(2); // Set the stroke weight to 2
  //rect(0, 0, width, height); // Draw the rectangle at the canvas boundaries

  for (int i = 0; i < paths.size(); i++) {
    drawLayer(paths.get(i), layerColors[i]);
  }
  if (displayParams) {
    displayParameters();
  }
}

void keyPressed() {
  if (key == 'g' || key == 'G') {
    generateDesign();
    redraw();
  } else if (key == 't' || key == 'T') {
    displayParams = !displayParams;
    redraw();
  } else if (key == 'e' || key == 'E') {
    exportDesign();
  } else if (keyCode == UP) {
    gridSize = constrain(gridSize + 5, 5, 100);
    generateDesign();
    redraw();
  } else if (keyCode == DOWN) {
    gridSize = constrain(gridSize - 5, 5, 100);
    generateDesign();
    redraw();
  } else if (keyCode == LEFT) {
    layerCount = constrain(layerCount - 1, 1, 10);
    generateDesign();
    redraw();
  } else if (keyCode == RIGHT) {
    layerCount = constrain(layerCount + 1, 1, 10);
    generateDesign();
    redraw();
  } else if (key == 'd' || key == 'D') {
    plotDensity = constrain(plotDensity - 1, 1, 40);
    generateDesign();
    redraw();
  } else if (key == 'i' || key == 'I') {
    plotDensity = constrain(plotDensity + 1, 1, 40);
    generateDesign();
    redraw();
  } else if (key == 'l' || key == 'L') {
    leadIn = !leadIn;
    redraw();
  } else if (key == '[') {
    directionChangeFrequency = constrain(directionChangeFrequency - 1, 1, 10);
    generateDesign();
    redraw();
  } else if (key == ']') {
    directionChangeFrequency = constrain(directionChangeFrequency + 1, 1, 10);
    generateDesign();
    redraw();
  }
}

void generateDesign() {
  paths = new ArrayList<ArrayList<PVector>>();
  layerColors = new color[layerCount];
  uniqueID = nf((int)random(10000), 4); // Generate a unique ID

  for (int i = 0; i < layerCount; i++) {
    paths.add(generateLayer());
    layerColors[i] = color(random(50, 150), random(50, 150), random(50, 150)); // Dark, distinct colors
  }
}

ArrayList<PVector> generateLayer() {
  ArrayList<PVector> layerPaths = new ArrayList<PVector>();
  int steps = width / gridSize * plotDensity;

  // Randomly choose a starting edge (0: top, 1: right, 2: bottom, 3: left)
  int edge = (int)random(4);
  int startX, startY;

  switch (edge) {
    case 0: // Top edge
      startX = snapToGrid((int)random(gridSize, width - gridSize));
      startY = 0;
      //println("Starting at top edge: (" + startX + ", " + startY + ")");
      break;
    case 1: // Right edge
      startX = width;
      startY = snapToGrid((int)random(gridSize, height - gridSize));
      //println("Starting at right edge: (" + startX + ", " + startY + ")");
      break;
    case 2: // Bottom edge
      startX = snapToGrid((int)random(gridSize, width - gridSize));
      startY = height;
      //println("Starting at bottom edge: (" + startX + ", " + startY + ")");
      break;
    case 3: // Left edge
      startX = 0;
      startY = snapToGrid((int)random(gridSize, height - gridSize));
      //println("Starting at left edge: (" + startX + ", " + startY + ")");
      break;
    default:
      startX = 0;
      startY = 0;
      //println("Starting at default position: (" + startX + ", " + startY + ")");
      break;
  }

  int currentX = startX;
  int currentY = startY;

  // Set the initial direction to move away from the starting edge
  PVector prevDirection = getOppositeDirection(edge);
  layerPaths.add(new PVector(currentX, currentY));
  //println("Starting direction: " + getCardinalName(prevDirection));

  // First move toward the opposite edge
  currentX += prevDirection.x * gridSize;
  currentY += prevDirection.y * gridSize;
  //println("First move to: (" + currentX + ", " + currentY + ")");

  if (!isInsideCanvas(currentX, currentY)) {
    println("Stopped: Outside canvas at (" + currentX + ", " + currentY + ")");
    return layerPaths;
  }

  if (currentX == 0 || currentX == width || currentY == 0 || currentY == height) {
    //println("Stopped: Reached edge at (" + currentX + ", " + currentY + ")");
    layerPaths.add(new PVector(currentX, currentY));
    return layerPaths;
  }

  layerPaths.add(new PVector(currentX, currentY));
  int i = 0;
  // Main loop for generating the path
  while (true) {
    i++;
    ArrayList<PVector> directions = getValidDirections(prevDirection);
    PVector chosenDirection = null;
    //println("Step " + i + ": Valid directions: " + validDirectionstoString(directions));

    // Avoid running into an edge until i == steps
    if (i < steps) {
      for (int j = 0; j < directions.size(); j++) {
        PVector direction = directions.get(j);
        if (isEdge(currentX + direction.x * gridSize, currentY + direction.y * gridSize)) {
          directions.remove(j);
          j--;
        }
      }
    }

    // Try to find a non-overlapping direction
    ArrayList<PVector> nonOverlappingDirections = new ArrayList<PVector>();
    for (PVector direction : directions) {
      if (!isOverlapping(direction, layerPaths)) {
        nonOverlappingDirections.add(direction);
      }
    }
    //println("Step " + i + ": Non-overlapping directions: " + validDirectionstoString(nonOverlappingDirections));
    if (nonOverlappingDirections.size() > 0) {
      chosenDirection = nonOverlappingDirections.get(int(random(nonOverlappingDirections.size())));
    } else {
      chosenDirection = directions.get((int)random(directions.size()));
    }


    //println("Step " + i + ": Chosen direction: " + getCardinalName(chosenDirection));

    // Move in the chosen direction a number of steps chosen at random between 1 and 11 - directionChangeFrequency
    int stepsToMove = (int)random(1, 11 - directionChangeFrequency);
    for (int j = 0; j < stepsToMove; j++) {
      // If the next move would go outside the canvas or hit an edge before i == steps, stop and return the path
      if ((!isInsideCanvas(currentX + chosenDirection.x * gridSize, currentY + chosenDirection.y * gridSize) || isEdge(currentX + chosenDirection.x * gridSize, currentY + chosenDirection.y * gridSize)) && i < steps) {
        layerPaths.add(new PVector(currentX, currentY));
        return layerPaths;
      }
      currentX += chosenDirection.x * gridSize;
      currentY += chosenDirection.y * gridSize;
      //println("Moved to: (" + currentX + ", " + currentY + ")");

      if (!isInsideCanvas(currentX, currentY)) {
        println("Stopped: Outside canvas at (" + currentX + ", " + currentY + ")");
        // Add the last point to the path where it intersects the canvas boundary
        layerPaths.add(new PVector(currentX - chosenDirection.x * gridSize, currentY - chosenDirection.y * gridSize));
        return layerPaths;
      }

      if (currentX == 0 || currentX == width || currentY == 0 || currentY == height) {
        //println("Stopped: Reached edge at (" + currentX + ", " + currentY + ")");
        layerPaths.add(new PVector(currentX, currentY));
        return layerPaths;
      }

      layerPaths.add(new PVector(currentX, currentY));
    }
    prevDirection = chosenDirection;
  }
}

boolean isOverlapping(PVector direction, ArrayList<PVector> path) {
  float currentX = path.get(path.size() - 1).x;
  float currentY = path.get(path.size() - 1).y;
  for (PVector point : path) {
    if (point.x == currentX + direction.x * gridSize && point.y == currentY + direction.y * gridSize) {
      return true;
    }
  }
  return false;
}

String getCardinalName(PVector direction) {
  if (direction.x == 1) return "Right";
  if (direction.x == -1) return "Left";
  if (direction.y == 1) return "Down";
  if (direction.y == -1) return "Up";
  return "None";
}

String validDirectionstoString(ArrayList<PVector> directions) {
  String result = "";
  for (PVector direction : directions) {
    result += getCardinalName(direction) + " ";
  }
  return result;
}

ArrayList<PVector> getValidDirections(PVector prevDirection) {
  ArrayList<PVector> directions = new ArrayList<PVector>();
  if (prevDirection.x != 1) directions.add(new PVector(-1, 0)); // Left
  if (prevDirection.x != -1) directions.add(new PVector(1, 0)); // Right
  if (prevDirection.y != 1) directions.add(new PVector(0, -1)); // Up
  if (prevDirection.y != -1) directions.add(new PVector(0, 1)); // Down
  return directions;
}

PVector getOppositeDirection(int edge) {
  switch (edge) {
    case 0: // Top edge
      return new PVector(0, 1); // Down
    case 1: // Right edge
      return new PVector(-1, 0); // Left
    case 2: // Bottom edge
      return new PVector(0, -1); // Up
    case 3: // Left edge
      return new PVector(1, 0); // Right
    default:
      return new PVector(0, 0); // No movement
  }
}

void drawLayer(ArrayList<PVector> path, color layerColor) {
  stroke(layerColor);
  strokeWeight(2);
  noFill();
  beginShape();
  if (leadIn){
    curveVertex(path.get(0).x, path.get(0).y);
  }
  for (PVector point : path) {
    curveVertex(point.x, point.y);
  }
  if (leadIn) {
    curveVertex(path.get(path.size() - 1).x, path.get(path.size() - 1).y);
  }
  endShape();
}

void exportDesign() {
  String fileName = "doodleplot_" + uniqueID + ".svg";
  beginRecord(SVG, fileName);

  for (int i = 0; i < paths.size(); i++) {
    drawLayer(paths.get(i), layerColors[i]);
  }

  endRecord();
  println("Design exported as: " + sketchPath(fileName));
}

void displayParameters() {
  fill(0);
  noStroke();
  rect(0, height - 50, width, 50); // Black background for text
  fill(255);
  textSize(14);
  StringBuilder sb = new StringBuilder();
  sb.append("Grid (UP/DOWN): ").append(gridSize)
    .append(" | Layers (LEFT/RIGHT): ").append(layerCount)
    .append(" | Density (D/I): ").append(plotDensity)
    .append(" | Turn Freq ([/]): ").append(directionChangeFrequency)
    //.append(" | Radius ([/]): ").append(cornerRadius)
    .append(" | (t) Toggle Overlay | (g) Generate | (e) Export");
  text(sb.toString(), 10, height - 20);
}

int snapToGrid(int value) {
  return (int)(round(value / gridSize) * gridSize);
}

boolean isInsideCanvas(float x, float y) {
  return x >= 0 && x <= width && y >= 0 && y <= height;
}

boolean isEdge(float x, float y) {
  return x == 0 || x == width || y == 0 || y == height;
}
