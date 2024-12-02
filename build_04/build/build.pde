/* * Pen Plotter Design Generator(With Radiused Corners) * * Key Controls: * - 'T' or 't': Toggle the display of the parameters panel. * - 'G' or 'g': Generate a new design with random paths. * - 'E' or 'e': Export the current design to an SVG file. * - Arrow Up: Increase grid size(snapping resolution). * - Arrow Down: Decrease grid size(snapping resolution). * - Arrow Left: Decrease the number of layers. * - Arrow Right: Increase the number of layers. * - 'D' or 'd': Decrease plot density. * - 'I' or 'i': Increase plot density. * - 'L' or 'l': Toggle lead-in lines. * - '[', ']': Decrease or increase the direction change frequency. * - 'S' or 's': Toggle snap to 90-degree angles. * - 'C' or 'c': Toggle inverted colors. * - 'Q' or 'q': Decrease draw point frequency. * - 'W' or 'w': Increase draw point frequency. * - 'P' or 'p': Toggle circle point display. * - '+' or '-': Increase or decrease the circle point draw frequency. * - 'X' or 'x': Toggle spirals instead of circles. */

import processing.svg.*;

int gridSize = 20;
int directionChangeFrequency = 10; // Smaller values increase turns
int layerCount = 4;
int plotDensity = 10;
int directions = 4;
String uniqueID;
boolean displayParams = true;
boolean leadIn = false;
boolean invertedColors = true;
boolean drawPoints = false;
float drawSkip = 1;
float circleDrawFrequency = 0.5;
int nodeShape = 0; // 0: Circle, 1: Spiral

ArrayList<ArrayList<PVector>> paths;
color[] layerColors;

void setup() {
  size(800, 800);
  noLoop();
  generateDesign();
}

void draw() {
  // Draw the background black if colors are inverted

  if (invertedColors) {
    background(0);
  } else {
    background(255);
  }
  // Draw the boundary box
  //stroke(0); // Set the stroke color to black
  //noFill(); // No fill for the rectangle
  //strokeWeight(2); // Set the stroke weight to 2
  //rect(0, 0, width, height); // Draw the rectangle at the canvas boundaries

  for(int i = 0;
  i < paths.size();
  i++) {
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
  }
  else if (key == 't' || key == 'T') {
    displayParams = !displayParams;
    redraw();
  }
  else if (key == 'e' || key == 'E') {
    exportDesign();
  }
  else if (keyCode == UP) {
    gridSize = constrain(gridSize + 5, 5, 100);
    generateDesign();
    redraw();
  }
  else if (keyCode == DOWN) {
    gridSize = constrain(gridSize - 5, 5, 100);
    generateDesign();
    redraw();
  }
  else if (keyCode == LEFT) {
    layerCount = constrain(layerCount - 1, 1, 10);
    generateDesign();
    redraw();
  }
  else if (keyCode == RIGHT) {
    layerCount = constrain(layerCount + 1, 1, 10);
    generateDesign();
    redraw();
  }
  else if (key == 'd' || key == 'D') {
    plotDensity = constrain(plotDensity - 1, 1, 40);
    generateDesign();
    redraw();
  }
  else if (key == 'i' || key == 'I') {
    plotDensity = constrain(plotDensity + 1, 1, 40);
    generateDesign();
    redraw();
  }
  else if (key == 'l' || key == 'L') {
    leadIn = !leadIn;
    redraw();
  }
  else if (key == '[') {
    directionChangeFrequency = constrain(directionChangeFrequency - 1, 1, 10);
    generateDesign();
    redraw();
  }
  else if (key == ']') {
    directionChangeFrequency = constrain(directionChangeFrequency + 1, 1, 10);
    generateDesign();
    redraw();
  }
  else if (key == 's' || key == 'S') {
    directions =(directions == 4) ? 8 : 4;
    generateDesign();
    redraw();
  }
  else if (key == 'c' || key == 'C') {
    invertedColors = !invertedColors;
    for(int i = 0;
    i < layerColors.length;
    i++) {
      layerColors[i] = color(255 - red(layerColors[i]), 255 - green(layerColors[i]), 255 - blue(layerColors[i]));
    }
    redraw();
  }
  else if (key == 'q' || key == 'Q') {
    drawSkip = constrain(drawSkip - 0.1, 0.1, 1);
    redraw();
  }
  else if (key == 'w' || key == 'W') {
    drawSkip = constrain(drawSkip + 0.1, 0.1, 1);
    redraw();
  }
  else if (key == 'p' || key == 'P') {
    drawPoints = !drawPoints;
    redraw();
  }
  else if (key == '+' || key == '=') {
    circleDrawFrequency = constrain(circleDrawFrequency + 0.1, 0.1, 1);
    redraw();
  }
  else if (key == '-') {
    circleDrawFrequency = constrain(circleDrawFrequency - 0.1, 0.1, 1);
    redraw();
  }
  else if (key == 'x' || key == 'X') {
    nodeShape =(nodeShape == 0) ? 1 : 0;
    redraw();
  }
}

void generateDesign() {
  paths = new ArrayList<ArrayList<PVector>>();
  layerColors = new color[layerCount];
  uniqueID = nf((int)random(10000), 4); // Generate a unique ID

  for (int i=0; i<layerCount; i++) {
    paths.add(generateLayer());
    layerColors[i] = color(random(50, 150), random(50, 150), random(50, 150)); // Dark, distinct colors
  }
}

ArrayList<PVector> generateLayer() {
  ArrayList<PVector> layerPaths = new ArrayList<PVector>();
  int steps = width / gridSize * plotDensity;

  // Randomly choose a starting edge(0: top, 1: right, 2: bottom, 3: left)
  int edge =(int)random(4);
  int startX, startY;

  switch(edge) {
    case 0: // Top edge
    startX = snapToGrid((int)random(gridSize, width - gridSize));
    startY = 0;
    //println("Starting at top edge:(" + startX + ", " + startY + ")");
    break;
    case 1: // Right edge
    startX = width;
    startY = snapToGrid((int)random(gridSize, height - gridSize));
    //println("Starting at right edge:(" + startX + ", " + startY + ")");
    break;
    case 2: // Bottom edge
    startX = snapToGrid((int)random(gridSize, width - gridSize));
    startY = height;
    //println("Starting at bottom edge:(" + startX + ", " + startY + ")");
    break;
    case 3: // Left edge
    startX = 0;
    startY = snapToGrid((int)random(gridSize, height - gridSize));
    //println("Starting at left edge:(" + startX + ", " + startY + ")");
    break;
    default: startX = 0;
    startY = 0;
    //println("Starting at default position:(" + startX + ", " + startY + ")");
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
  //println("First move to:(" + currentX + ", " + currentY + ")");

  if (!isInsideCanvas(currentX, currentY)) {
    println("Stopped: Outside canvas at(" + currentX + ", " + currentY + ")");
    return layerPaths;
  }
  if (currentX == 0 || currentX == width || currentY == 0 || currentY == height) {
    //println("Stopped: Reached edge at(" + currentX + ", " + currentY + ")");
    layerPaths.add(new PVector(currentX, currentY));
    return layerPaths;
  }
  layerPaths.add(new PVector(currentX, currentY));
  int i = 0;
  // Main loop for generating the path

  while(true) {
    i++;
    ArrayList<PVector> directions = getValidDirections(prevDirection);
    PVector chosenDirection = null;
    //println("Step " + i + ": Valid directions: " + validDirectionstoString(directions));

    // Avoid running into an edge until i == steps
    if (i < steps) {
      for(int j = 0;
      j < directions.size();
      j++) {
        PVector direction = directions.get(j);
        if (isEdge(snapToGrid(currentX + direction.x * gridSize), snapToGrid(currentY + direction.y * gridSize))) {
          directions.remove(j);
          j--;
        }
      }
    }
    // Try to find a non-overlapping direction
    ArrayList<PVector> nonOverlappingDirections = new ArrayList<PVector>();
    for(PVector direction : directions) {
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
    int stepsToMove =(int)random(1, 11 - directionChangeFrequency);
    for (int j=0; j<stepsToMove; j++) {
      // If the next move would go outside the canvas or hit an edge before i == steps, stop and return the path
      if ((!isInsideCanvas(currentX + chosenDirection.x * gridSize, currentY + chosenDirection.y * gridSize) || isEdge(snapToGrid(currentX + chosenDirection.x * gridSize), snapToGrid(currentY + chosenDirection.y * gridSize))) && i < steps) {
        layerPaths.add(new PVector(snapToGrid(currentX), snapToGrid(currentY)));
        return layerPaths;
      }
      currentX = snapToGrid(currentX +(chosenDirection.x * gridSize));
      currentY = snapToGrid(currentY +(chosenDirection.y * gridSize));
      //println("Moved to:(" + currentX + ", " + currentY + ")");

      if (!isInsideCanvas(currentX, currentY)) {
        println("Stopped: Outside canvas at(" + currentX + ", " + currentY + ")");
        // Add the last point to the path where it intersects the canvas boundary
        layerPaths.add(new PVector(currentX - chosenDirection.x * gridSize, currentY - chosenDirection.y * gridSize));
        return layerPaths;
      }
      if (currentX == 0 || currentX == width || currentY == 0 || currentY == height) {
        //println("Stopped: Reached edge at(" + currentX + ", " + currentY + ")");
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
  for(PVector point : path) {
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
  if (direction.x == 1 && direction.y == 1) return "Down-Right";
  if (direction.x == -1 && direction.y == 1) return "Down-Left";
  if (direction.x == 1 && direction.y == -1) return "Up-Right";
  if (direction.x == -1 && direction.y == -1) return "Up-Left";
  return "None";
}
String validDirectionstoString(ArrayList<PVector> directions) {
  String result = "";
  for(PVector direction : directions) {
    result += getCardinalName(direction) + " ";
  }
  return result;
}

ArrayList<PVector> getValidDirections(PVector prevDirection) {
  ArrayList<PVector> validDirections = new ArrayList<PVector>();
  if (directions == 4) {
    if (prevDirection.x != 1) validDirections.add(new PVector(-1, 0)); // Left
    if (prevDirection.x != -1) validDirections.add(new PVector(1, 0)); // Right
    if (prevDirection.y != 1) validDirections.add(new PVector(0, -1)); // Up
    if (prevDirection.y != -1) validDirections.add(new PVector(0, 1)); // Down
  } else {
    if (prevDirection.x != 1) validDirections.add(new PVector(-1, 0)); // Left
    if (prevDirection.x != -1) validDirections.add(new PVector(1, 0)); // Right
    if (prevDirection.y != 1) validDirections.add(new PVector(0, -1)); // Up
    if (prevDirection.y != -1) validDirections.add(new PVector(0, 1)); // Down
    if (prevDirection.x != 1 && prevDirection.y != 1) validDirections.add(new PVector(1, 1)); // Down-Right
    if (prevDirection.x != -1 && prevDirection.y != 1) validDirections.add(new PVector(-1, 1)); // Down-Left
    if (prevDirection.x != 1 && prevDirection.y != -1) validDirections.add(new PVector(1, -1)); // Up-Right
    if (prevDirection.x != -1 && prevDirection.y != -1) validDirections.add(new PVector(-1, -1)); // Up-Left
  }
  return validDirections;
}

PVector getOppositeDirection(int edge) {

  switch(edge) {
    case 0: // Top edge
    return new PVector(0, 1); // Down
    case 1: // Right edge
    return new PVector(-1, 0); // Left
    case 2: // Bottom edge
    return new PVector(0, -1); // Up
    case 3: // Left edge
    return new PVector(1, 0); // Right
    default: return new PVector(0, 0); // No movement
  }
}
void drawLayer(ArrayList<PVector> path, color layerColor) {
  stroke(layerColor);
  strokeWeight(2);
  noFill();

  beginShape();

  if (leadIn) {
    curveVertex(path.get(0).x, path.get(0).y);
  }
  for(PVector point : path) {
    // Skip points to reduce the number of vertices randomly, using the value of drawSkip, where 1 is no skipping and 0.1 is skipping 90% of points
    if (random(1) > drawSkip) {
      continue;
    }
    curveVertex(point.x, point.y);
  }

  if (leadIn) {
    curveVertex(path.get(path.size() - 1).x, path.get(path.size() - 1).y);
  }
  endShape();

  for(int p = 1; p < path.size(); p++) {
    PVector point = path.get(p);
    // Randomly draw a circle at some points with random size and weight proportional to the grid size
    // Can also draw a spiral if nodeShape is set to 1
    // Don't draw circles or spirals on edges
    if ((random(1) < circleDrawFrequency) && drawPoints && nodeShape == 0) {
      int diameter =(int)random(1, 5) * gridSize / 10;
      ellipse(point.x, point.y, diameter, diameter);
    }
    else if ((random(1) < circleDrawFrequency) && drawPoints && nodeShape == 1) {
      int diameter =(int)random(1, 5) * gridSize / 10;
      spiral(point.x, point.y, diameter);
    }
  }
}

void spiral(float x, float y, float diameter) {
  float angle = 0;
  float radius = 0;
  pushMatrix();
  translate(x, y);
  beginShape();
  while(radius <= diameter / 2) {
    vertex(cos(angle) * radius, sin(angle) * radius);
    angle += TWO_PI / 4000;
    radius += .00075;
  }
  endShape();
  popMatrix();
}

void exportDesign() {
  String fileName = "doodleplot_" + uniqueID + ".svg";
  beginRecord(SVG, fileName);

  for(int i = 0;
  i < paths.size();
  i++) {
    drawLayer(paths.get(i), layerColors[i]);
  }
  endRecord();
  println("Design exported as: " + sketchPath(fileName));
}

void displayParameters() {
  fill(0);
  noStroke();
  rect(0, height - 60, width, 50); // Black background for text
  fill(255);
  textSize(13);
  StringBuilder sb = new StringBuilder();
  sb.append("Grid(UP/DOWN): ").append(gridSize) .append(" | Layers(LEFT/RIGHT): ").append(layerCount) .append(" | Density(D/I): ").append(plotDensity) .append(" | Turn Freq([/]): ").append(directionChangeFrequency) .append(" | Snap to 90(S): ").append(directions == 4 ? "On" : "Off") .append("\n") .append("Draw Freq(Q/W): ").append(nf(drawSkip, 1, 1)) .append(" | Circles(P): ").append(drawPoints ? "On" : "Off") .append(" | Shape(X): ").append(nodeShape == 0 ? "Circle" : "Spiral") .append(" | Circle Freq(+/-): ").append(nf(circleDrawFrequency, 1, 1)) .append(" | Lead-in(L): ").append(leadIn ? "On" : "Off") .append(" | Colors(C): ").append(invertedColors ? "Inverted" : "Normal") .append("\n") .append("Toggle Overlay(t) | Generate(g) | Export(e)");
  text(sb.toString(), 10, height - 40);
}

int snapToGrid(float value) {
  return(int)(round(value / gridSize) * gridSize);
}

boolean isInsideCanvas(float x, float y) {
  return x >= 0 && x <= width && y >= 0 && y <= height;
}

boolean isEdge(float x, float y) {
  return x == 0 || x == width || y == 0 || y == height;
}
