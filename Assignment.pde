import java.util.Collections;

// Physic Parameters
float g = 9.81;
float dt;
float e = 0.3;
float mu = 0.5;

int subSteps = 4;

// Ball physic states
PVector ballPos;
PVector ballVel;
float ballRadius = 15;

// Board Parameters
float boardWidth = 900;
float boardHeight = 800;
float angleX = 0;      // tilt forward or backward
float angleZ = 0;      // tilt left or right
float maxAngle = PI/6;  // ±30°

// Walls
ArrayList<Wall> walls = new ArrayList<Wall>();
ArrayList<VerticalWall> verticalwalls = new ArrayList<VerticalWall>();

// Holes
ArrayList<Hole> holes = new ArrayList<Hole>();

// Game State
boolean gameWin = false;
PVector startPos;

// Goal
PVector goalPos;
float goalRadius = 25;
boolean goalReached = false;
float startTime;
float winTime;

// High Score System
ArrayList<ScoreEntry> highScores = new ArrayList<ScoreEntry>();
String scoreFile = "highscores.txt";
boolean gameJustWon = false;  // Avoid Save Repeatly

// Energy monitoring
float kineticEnergy = 0;
float lastEnergyLogTime = 0;
boolean useSymplectic = true;

void setup()
{
  size(800, 600, P3D);
  
   surface.setLocation(100, 100);
  
  // Initialize the ball's position
  ballPos = new PVector(-410, -360);
  ballVel = new PVector(0, 0);
  startPos = new PVector(-410, -360);
  
  // Initialize tilt angle
  angleX = 0;
  angleZ = 0;
  
  // Initialize goal
  goalPos = new PVector(390, 360);
  goalRadius = 25;
  gameWin = false;
  
  // Start timer
  startTime = millis();
  
  setupWalls();
  setupHoles();
  
  loadHighScores();
}

void draw()
{
  // Calculate time step
  dt = (1.0 / frameRate) * 2.0;
  if (dt > 0.05) dt = 0.05; //Limit time step
  
  // Update Physic
  for (int step = 0; step < subSteps; step++) 
  {
    if (!gameWin) 
    {
      if (useSymplectic) 
      {
        updatePhysics();
      } else 
      {
        updatePhysicsExplicitEuler();
      }
      checkCollisions();
      checkWinCondition();
      checkHoleReset();
    }
  }
  
  // Record energy behaviour every 2 second
  float currentTime = millis() / 1000.0;
  if (currentTime - lastEnergyLogTime >= 2.0) 
  {
    kineticEnergy = 0.5 * (ballVel.x * ballVel.x + ballVel.y * ballVel.y);
    String method = useSymplectic ? "Symplectic" : "Explicit";
    println(method + " | Time: " + nf(currentTime, 1, 1) + "s | Energy: " + nf(kineticEnergy, 1, 3));
    lastEnergyLogTime = currentTime;
  }
  
  background(50);
  
  // Set 3D view
  // eyeX, eyeY, eyeZ 
  // centerX, centerY, centerZ
  // upX, upY, upZ 
  camera
  (
    0, 80, 900, 0, 0, 0, 0, 1, 0
  );
  lights();
  
  // Draw the board (rotating around X and Z)
  pushMatrix();
  translate(0, 0, 0);
  rotateX(angleX);
  rotateY(angleZ);
  
  // Draw board plane
  fill(150, 100, 50);
  stroke(0);
  rectMode(CENTER);
  rect(0, 0, boardWidth, boardHeight);
  
  // Draw Wall
  drawWall();
  
  // Draw Hole
  drawHoles();
  
  // Draw Ball
  drawBall();
  
  // Draw Goal
  drawGoal();
  
  popMatrix();
  
  displayDebug();
}

void updatePhysics()
{
  // Compute the effective acceleration acting on the ball as projections of gravity onto the tilted plane
  float ax = g * sin(angleZ);
  float ay = -g * sin(angleX);
  
  // Symplectic (semi-implicit) Euler integration
  ballVel.x += ax * dt;
  ballVel.y += ay * dt;
  ballPos.x += ballVel.x * dt;
  ballPos.y += ballVel.y * dt;
  
  // Boundary constraints
  float limitX = boardWidth/2 - ballRadius;
  float limitY = boardHeight/2 - ballRadius;
  if (ballPos.x > limitX) 
  {
    ballPos.x = limitX;
    ballVel.x = -ballVel.x * e;   // border bounce
  }
  if (ballPos.x < -limitX) 
  {
    ballPos.x = -limitX;
    ballVel.x = -ballVel.x * e;
  }
  if (ballPos.y > limitY) 
  {
    ballPos.y = limitY;
    ballVel.y = -ballVel.y * e;
  }
  if (ballPos.y < -limitY) 
  {
    ballPos.y = -limitY;
    ballVel.y = -ballVel.y * e;
  }
}

// ============================================
void updatePhysicsExplicitEuler()
{
  float ax = g * sin(angleZ);
  float ay = -g * sin(angleX);
  
  // Update location first
  ballPos.x += ballVel.x * dt;
  ballPos.y += ballVel.y * dt;
  
  ballVel.x += ax * dt;
  ballVel.y += ay * dt;
  
  float limitX = boardWidth/2 - ballRadius;
  float limitY = boardHeight/2 - ballRadius;
  if (ballPos.x > limitX) 
  {
    ballPos.x = limitX;
    ballVel.x = -ballVel.x * e;
  }
  if (ballPos.x < -limitX) 
  {
    ballPos.x = -limitX;
    ballVel.x = -ballVel.x * e;
  }
  if (ballPos.y > limitY) 
  {
    ballPos.y = limitY;
    ballVel.y = -ballVel.y * e;
  }
  if (ballPos.y < -limitY) 
  {
    ballPos.y = -limitY;
    ballVel.y = -ballVel.y * e;
  }
}

// ============================================
// Save high scores to text file
void saveHighScores() 
{
  // Sort
  Collections.sort(highScores);
  
  // Just Keep rank 1-10
  while (highScores.size() > 10) {
    highScores.remove(highScores.size() - 1);
  }
  
  String[] lines = new String[highScores.size()];
  for (int i = 0; i < highScores.size(); i++) 
  {
    ScoreEntry s = highScores.get(i);
    lines[i] = s.name + "," + s.time + "," + s.date;
  }
  
  saveStrings(scoreFile, lines);
  println("High scores saved to " + scoreFile);
}

// ============================================
// Load high scores from text file
void loadHighScores() 
{
  File f = new File(sketchPath(scoreFile));
  if (!f.exists()) 
  {
    println("No high score file found, creating new one");
    saveHighScores();
    return;
  }
  
  String[] lines = loadStrings(scoreFile);
  if (lines != null) 
  {
    for (String line : lines) 
    {
      String[] parts = line.split(",");
      if (parts.length == 3) 
      {
        String name = parts[0];
        float time = float(parts[1]);
        String date = parts[2];
        highScores.add(new ScoreEntry(name, time, date));
      }
    }
  }
  println("Loaded " + highScores.size() + " high scores");
}

// ============================================
// Get current date string
String getCurrentDate() 
{
  return nf(day(), 2) + "/" + nf(month(), 2) + "/" + year();
}

// ============================================
// Check if time is a new high score
boolean isNewHighScore(float time) 
{
  if (highScores.size() < 10) return true;
  
  float worstTime = 0;
  for (ScoreEntry s : highScores) 
  {
    if (s.time > worstTime) worstTime = s.time;
  }
  return time < worstTime;
}

// ============================================
// Add new high score (called when player wins)
void addNewHighScore(float time) 
{
  if (!isNewHighScore(time)) 
  {
    println("Not a high score, current time: " + time);
    return;
  }
  

  String playerName = "Player" + (highScores.size() + 1);
  
  highScores.add(new ScoreEntry(playerName, time, getCurrentDate()));
  

  Collections.sort(highScores);
  saveHighScores();
  
  println("New high score! Rank: " + getRank(time));
}

// ============================================
// Get rank of a time
int getRank(float time) 
{
  int rank = 1;
  for (ScoreEntry s : highScores) 
  {
    if (time > s.time) rank++;
    else break;
  }
  return rank;
}

// ============================================

void drawBall() 
{
  pushMatrix();
  translate(ballPos.x, ballPos.y, ballRadius);
  fill(200, 50, 50);
  sphere(ballRadius);
  popMatrix();
}

// ============================================
// Horizontal Wall
class Wall 
{
  float x, y;      
  float w, h;      
  
  Wall(float x, float y, float w, float h) 
  {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  void draw() 
  {
    pushMatrix();
    translate(x, y, 0);
    fill(255, 255, 255);
    box(w, 10, h);
    popMatrix();
  }
  
  // AABB
  float left()   { return x - w/2; }
  float right()  { return x + w/2; }
  float top()    { return y - h/2; }
  float bottom() { return y + h/2; }
}

// ============================================
// Vertical Wall
class VerticalWall 
{
  float x, y;      
  float w, h;
  
  VerticalWall(float x, float y, float w, float h) 
  {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  void draw() 
  {
    pushMatrix();
    translate(x, y, 0);
    fill(255, 255, 255);
    box(10, h, w);
    popMatrix();
  }
  
  // AABB
  float left()   { return x - w/2; }
  float right()  { return x + w/2; }
  float top()    { return y - h/2; }
  float bottom() { return y + h/2; }
}

// ============================================
class Hole 
{
  float x, y;      // Central Position
  float r;         // Radius
  
  Hole(float x, float y, float r) 
  {
    this.x = x;
    this.y = y;
    this.r = r;
  }
  
  void draw() 
  {
    pushMatrix();
    translate(x, y, -5);
    fill(0, 0, 0);        
    noStroke();
    sphere(r);
    popMatrix();
  }
  
  // Check if the ball is inside the hole
  boolean contains(PVector pos, float ballR) 
  {
    return dist(pos.x, pos.y, x, y) < r + ballR * 0.5;
  }
}

// ============================================
// Draw Maze
void setupWalls() 
{
  // outer walls
  walls.add(new Wall(0, -400, 900, 30));
  walls.add(new Wall(0, 400, 900, 30));
  verticalwalls.add(new VerticalWall(-450, 0, 30, 800));
  verticalwalls.add(new VerticalWall(450, 0, 30, 800));
  
  // Maze Number Refer To Excel
  verticalwalls.add(new VerticalWall(-370, -355, 30, 80));  // 1
  
  verticalwalls.add(new VerticalWall(-210, -355, 30, 80));  // 2.1
  walls.add(new Wall(-165, -320, 80, 30));                  // 2.2
  verticalwalls.add(new VerticalWall(-130, -275, 30, 80));  // 2.3
  
  verticalwalls.add(new VerticalWall(-290, -280, 30, 90));  // 3.1
  walls.add(new Wall(-245, -240, 80, 30));                  // 3.2
  walls.add(new Wall(-335, -240, 80, 30));                  // 3.3

  verticalwalls.add(new VerticalWall(-50, -245, 30, 160));  // 4.1
  walls.add(new Wall(35, -240, 160, 30));                   // 4.2
  walls.add(new Wall(-55, -160, 160, 30));                  // 4.3
  verticalwalls.add(new VerticalWall(-50, -115, 30, 80));   // 4.4
  verticalwalls.add(new VerticalWall(30, -285, 30, 80));    // 4.5
  verticalwalls.add(new VerticalWall(30, -195, 30, 80));    // 4.6
  verticalwalls.add(new VerticalWall(110, -195, 30, 80));   // 4.7
  
  verticalwalls.add(new VerticalWall(110, -355, 30, 80));   // 5
  
  walls.add(new Wall(275, -320, 180, 30));                  // 6.1
  verticalwalls.add(new VerticalWall(190, -275, 30, 80));   // 6.2
  
  walls.add(new Wall(225, -160, 80, 30));                   // 7.1
  verticalwalls.add(new VerticalWall(270, -200, 30, 90));   // 7.2
  
  walls.add(new Wall(405, -240, 80, 30));                   // 8.1
  verticalwalls.add(new VerticalWall(370, -195, 30, 80));   // 8.2
  
  walls.add(new Wall(-405, -160, 80, 30));                  // 9
  
  walls.add(new Wall(-245, -160, 80, 30));                  // 10.1
  verticalwalls.add(new VerticalWall(-290, -120, 30, 90));  // 10.2
  walls.add(new Wall(-245, -80, 80, 30));                   // 10.3
  verticalwalls.add(new VerticalWall(-210, -35, 30, 80));   // 10.4
  walls.add(new Wall(-255, 0, 80, 30));                     // 10.5
  
  verticalwalls.add(new VerticalWall(-370, 0, 30, 180));    // 11
  
  verticalwalls.add(new VerticalWall(-130, -45, 30, 80));   // 12.1
  walls.add(new Wall(-50, 0, 170, 30));                     // 12.2
  verticalwalls.add(new VerticalWall(30, -45, 30, 80));     // 12.3
  walls.add(new Wall(75, -80, 80, 30));                     // 12.4
  verticalwalls.add(new VerticalWall(30, 45, 30, 80));      // 12.5
  walls.add(new Wall(-55, 80, 160, 30));                    // 12.6
  verticalwalls.add(new VerticalWall(-130, 125, 30, 80));   // 12.7
  verticalwalls.add(new VerticalWall(-50, 125, 30, 80));    // 12.8
  //walls.add(new Wall(75, 80, 80, 30));                    // 12.9
  verticalwalls.add(new VerticalWall(110, 125, 30, 80));    // 12.10
  walls.add(new Wall(65, 160, 80, 30));                     // 12.11
  verticalwalls.add(new VerticalWall(30, 205, 30, 80));     // 12.12
  walls.add(new Wall(-55, 240, 160, 30));                   // 12.13
  
  walls.add(new Wall(330, -80, 100, 30));                   // 13
  
  walls.add(new Wall(275, 0, 180, 30));                     // 14.1
  walls.add(new Wall(145, 0, 80, 30));                      // 14.2
  verticalwalls.add(new VerticalWall(190, -45, 30, 80));    // 14.3
  verticalwalls.add(new VerticalWall(190, 45, 30, 80));     // 14.4
  verticalwalls.add(new VerticalWall(270, 45, 30, 80));     // 14.5
  verticalwalls.add(new VerticalWall(270, 125, 30, 80));    // 14.6
  walls.add(new Wall(315, 80, 80, 30));                     // 14.7
  
  walls.add(new Wall(-255, 80, 80, 30));                    // 15.1
  verticalwalls.add(new VerticalWall(-210, 155, 30, 160));  // 15.2
  walls.add(new Wall(-245, 240, 80, 30));                   // 15.3
  verticalwalls.add(new VerticalWall(-290, 205, 30, 80));   // 15.4
  walls.add(new Wall(-325, 160, 80, 30));                   // 15.5
  verticalwalls.add(new VerticalWall(-370, 195, 30, 80));   // 15.6
  walls.add(new Wall(-405, 240, 80, 30));                   // 15.7
  
  verticalwalls.add(new VerticalWall(-370, 355, 30, 80));   // 16.1
  verticalwalls.add(new VerticalWall(-210, 355, 30, 80));   // 16.2
  verticalwalls.add(new VerticalWall(-130, 355, 30, 80));   // 16.3
  walls.add(new Wall(-290, 320, 150, 30));                  // 16.4
  walls.add(new Wall(-170, 320, 70, 30));                   // 16.5
  
  verticalwalls.add(new VerticalWall(-50, 355, 30, 80));    // 17
  
  verticalwalls.add(new VerticalWall(30, 355, 30, 80));     // 18
  
  verticalwalls.add(new VerticalWall(110, 280, 30, 90));    // 19
  
  verticalwalls.add(new VerticalWall(190, 200, 30, 90));    // 20
  
  walls.add(new Wall(225, 320, 80, 30));                    // 21.1
  verticalwalls.add(new VerticalWall(270, 355, 30, 80));    // 21.2
  
  verticalwalls.add(new VerticalWall(350, 280, 30, 90));    // 22.1
  walls.add(new Wall(305, 240, 80, 30));                    // 22.2
  
  walls.add(new Wall(405, 160, 80, 30));                   // 23
}

void drawWall() 
{
  for (Wall w : walls) 
  {
    w.draw();
  }
  
  for (VerticalWall w : verticalwalls) 
  {
    w.draw();
  }
}

// ============================================
void setupHoles()
{
  int r = int (random (0, 6));
  println(r);
  
  if ( r == 0)
  {
    holes.add(new Hole(-330,-200,22));
    holes.add(new Hole(-170,40,22));
  }
  else if ( r == 1)
  {
    holes.add(new Hole(190,-120,22));
    holes.add(new Hole(230,280,22));
  }
  else if ( r == 2)
  {
    holes.add(new Hole(390,280,22));
    holes.add(new Hole(-170,280,22));
  }
  else if ( r == 3)
  {
    holes.add(new Hole(150,-200,22));
    holes.add(new Hole(-170,40,22));
  }
  else if ( r == 4)
  {
    holes.add(new Hole(-170,-200,22));
    holes.add(new Hole(290,280,22));
  }
  else if ( r == 5)
  {
    holes.add(new Hole(310,280,22));
    holes.add(new Hole(310,-120,22));
  }
}

void drawHoles() 
{
  for (Hole h : holes) 
  {
    h.draw();
  }
}

// ============================================
// Draw Goal
void drawGoal() 
{
  pushMatrix();
  translate(goalPos.x, goalPos.y, 5); 
  fill(0, 255, 0, 180);                
  noStroke();
  sphere(goalRadius);
  
  pushMatrix();
  scale(1.2);
  fill(0, 255, 0, 80);
  sphere(goalRadius * 0.8);
  popMatrix();
  
  popMatrix();
}

// ============================================
// Collision detection between the ball and the AABB wall
void checkCollisions()
{
  for (Wall w : walls) 
  {
    //Obtain wall boundaries
    float wallLeft   = w.left();
    float wallRight  = w.right();
    float wallTop    = w.top();
    float wallBottom = w.bottom();
    
    // Find The Closet Point
    float closestX = constrain(ballPos.x, wallLeft, wallRight);
    float closestY = constrain(ballPos.y, wallTop, wallBottom);
    
    PVector closestPoint = new PVector(closestX, closestY);
    PVector diff = PVector.sub(ballPos, closestPoint);
    float dist = diff.mag();
    
    if (dist < ballRadius)
    {
      // Collision
      PVector normal = diff.copy();
      normal.normalize();
      
      PVector relVel = ballVel.copy();
      float velAlong = relVel.dot(normal);
      
      if (velAlong < 0) 
      {
        // Normal impulse
        float j = -(1 + e) * velAlong;
        ballVel.x += j * normal.x;
        ballVel.y += j * normal.y;
        
        // Friction
         PVector tangent = PVector.sub(ballVel, PVector.mult(normal, velAlong));
        float tangentMag = tangent.mag();
        
        if (tangentMag > 0.001)  // Avoid division by zero
        {
          tangent.normalize();
          // Frictional impulse magnitude = coefficient of friction × normal impulse
          float jt = -mu * j;
          ballVel.x += jt * tangent.x;
          ballVel.y += jt * tangent.y;
        }
      }
      
      // position correction
      float overlap = ballRadius - dist;
      ballPos.x += normal.x * overlap;
      ballPos.y += normal.y * overlap;
    }
  }
  
  for (VerticalWall verticalw : verticalwalls) 
  {
    //Obtain wall boundaries
    float verticalwallLeft   = verticalw.left();
    float verticalwallRight  = verticalw.right();
    float verticalwallTop    = verticalw.top();
    float verticalwallBottom = verticalw.bottom();
    
    // Find The Closet Point
    float verticalclosestX = constrain(ballPos.x, verticalwallLeft, verticalwallRight);
    float verticalclosestY = constrain(ballPos.y, verticalwallTop, verticalwallBottom);
    
    PVector verticalclosestPoint = new PVector(verticalclosestX, verticalclosestY);
    PVector diff = PVector.sub(ballPos, verticalclosestPoint);
    float dist = diff.mag();
    
    if (dist < ballRadius)
    {
      // Collision
      PVector normal = diff.copy();
      normal.normalize();
      
      PVector relVel = ballVel.copy();
      float velAlong = relVel.dot(normal);
      
      if (velAlong < 0) 
      {
        // Normal impulse
        float j = -(1 + e) * velAlong;
        ballVel.x += j * normal.x;
        ballVel.y += j * normal.y;
        
        // Friction
        PVector tangent = PVector.sub(ballVel, PVector.mult(normal, velAlong));
        float tangentMag = tangent.mag();
        
        if (tangentMag > 0.001)
        {
          tangent.normalize();
          // 摩擦冲量
          float jt = -mu * j;
          ballVel.x += jt * tangent.x;
          ballVel.y += jt * tangent.y;
        }
      }
      
      // position correction
      float overlap = ballRadius - dist;
      ballPos.x += normal.x * overlap;
      ballPos.y += normal.y * overlap;
    }
  }
}

// ============================================

void checkWinCondition() 
{
  if (!gameWin) 
  {
    float distToGoal = dist(ballPos.x, ballPos.y, goalPos.x, goalPos.y);
    
    if (distToGoal < goalRadius + ballRadius) 
    {
      gameWin = true;
      winTime = millis();
      float elapsedTime = (winTime - startTime) / 1000.0;
      println("YOU WIN! Time: " + nf(elapsedTime, 1, 2) + " seconds");
      
      // Save highscore
       if (isNewHighScore(elapsedTime)) 
       {
        addNewHighScore(elapsedTime);
        println("New high score!");
       }  
    }
  }
}

void checkHoleReset() 
{
  for (Hole h : holes) 
  {
    if (h.contains(ballPos, ballRadius)) 
    {
      // Reset to starting point when ball fall into hole
      ballPos.set(startPos);
      ballVel.set(0, 0);
      
      holes.clear();
      setupHoles();
      
      // Play a small feedback
      println("Fell into a hole! Reset to start.");
      
      break;
    }
  }
}

// Score Entry Class
class ScoreEntry implements Comparable<ScoreEntry> 
{
  String name;
  float time;
  String date;
  
  ScoreEntry(String name, float time, String date) 
  {
    this.name = name;
    this.time = time;
    this.date = date;
  }
  
  int compareTo(ScoreEntry other) 
  {
    // Shorter Time, higher rank
    if (this.time < other.time) return -1;
    if (this.time > other.time) return 1;
    return 0;
  }
}

// ============================================
void displayDebug() 
{
  // Change to 2D for UI
  pushMatrix();
  resetMatrix();
  
  camera();  // Reset Camera
  ortho();
  
  hint(DISABLE_DEPTH_TEST);
  
  // Calculate current time
  float currentTime;
  if (gameWin) 
  {
    currentTime = (winTime - startTime) / 1000;
  } else 
  {
    currentTime = (millis() - startTime) / 1000;
  }

  // Left Side: Debugging Info
  fill(0, 0, 0, 180);
  noStroke();
  rect(30, 30, 600, 500);
  
  fill(255);
  textSize(15);
  textAlign(LEFT, TOP);
  text("Angle X: " + nf(degrees(angleX), 1, 1) + "°", 20, 20);
  text("Angle Z: " + nf(degrees(angleZ), 1, 1) + "°", 20, 45);
  text("Ball Pos: (" + nf(ballPos.x, 1, 1) + ", " + nf(ballPos.y, 1, 1) + ")", 20, 70);
  text("Ball Vel: (" + nf(ballVel.x, 1, 2) + ", " + nf(ballVel.y, 1, 2) + ")", 20, 95);
  text("e (restitution): " + nf(e, 1, 2), 20, 120);
  text("mu (friction): " + nf(mu,1, 2), 20, 145);
  text("Time: " + nf(currentTime, 1, 2) + " s", 20, 170);
  text("Use WASD / Arrows to tilt", 20, 195);
  text("R: reset ball | BACKSPACE: reset game", 20, 220);
  text("Integrator: " + (useSymplectic ? "Symplectic Euler" : "Explicit Euler"), 20, 245);
  text("Press 0 to switch integrator", 20, 270);
  
  // Right side: Highsocre
   fill(0, 0, 0, 200);
  rect(width - 150, 100, 240, 250);
  
  fill(255, 215, 0);
  textSize(28);
  textAlign(CENTER, TOP);
  text("HIGH SCORES", width - 150, 20);
  
  textSize(20);
  fill(200);
  textAlign(LEFT, TOP);
  text("Rank   Name        Time", width - 260, 50);
  text("─────────────────────", width - 260, 60);
  
  // Show Top 5
  for (int i = 0; i < min(5, highScores.size()); i++) 
  {
    ScoreEntry s = highScores.get(i);
    fill(255);
    text((i+1) + ".", width - 260, 70 + i * 22);
    text(s.name, width - 205, 70 + i * 22);
    textAlign(RIGHT, TOP);
    text(nf(s.time, 1, 2) + " s", width - 70, 70 + i * 22);
    textAlign(LEFT, TOP);
  }
  
  
  if (gameWin) 
  {
    textAlign(CENTER, CENTER);
    fill(0, 0, 0, 200);
    rect(width/2, height/2, 500, 200);
    
    textSize(48);
    fill(0, 255, 0);
    text("YOU WIN!", width/2, height/2 - 50);
    textSize(24);
    text("Time: " + nf(currentTime, 1, 2) + " seconds", width/2, height/2 - 5);
    
    // 显示排名
    int rank = getRank(currentTime);
    if (rank <= 10) {
      fill(255, 215, 0);
      text("Rank #" + rank + " on High Score Board!", width/2, height/2 + 40);
    }
    
    textSize(16);
    fill(200);
    text("Press BACKSPACE to reset game", width/2, height/2 + 85);
  }
  
  hint(ENABLE_DEPTH_TEST);
  
  popMatrix();
}

// ============================================
// Keyboard control panel tilted
void keyPressed()
{
  handleKeyboard();
}

void handleKeyboard()
{
  float step = 0.10;
  
  boolean isTiltControl = false;
  
  // 箭头键
  if (keyCode == UP) 
  {
    angleX += step;
    isTiltControl = true;
  } 
  else if (keyCode == DOWN) 
  {
    angleX -= step;
    isTiltControl = true;
  } 
  else if (keyCode == LEFT) 
  {
    angleZ -= step;
    isTiltControl = true;
  } 
  else if (keyCode == RIGHT) 
  {
    angleZ += step;
    isTiltControl = true;
  }
  
  // WASD
  if (key == 'w' || key == 'W') 
  {
    angleX += step;
    isTiltControl = true;
  } 
  else if (key == 's' || key == 'S') 
  {
    angleX -= step;
    isTiltControl = true;
  } 
  else if (key == 'a' || key == 'A') 
  {
    angleZ -= step;
    isTiltControl = true;
  } 
  else if (key == 'd' || key == 'D') 
  {
    angleZ += step;
    isTiltControl = true;
  }
  
  // Restitution Coefficient e Adjustment
   if (key == '1') 
  {
    e = min(1.0, e + 0.05);
  }
  else if (key == '2') 
  {
    e = max(0.0, e - 0.05);
  }
  
  // Friction Coefficient μ Adjustment
   if (key == '3') 
  {
    mu = min(1.0, mu + 0.05);
  }
  else if (key == '4') 
  {
    mu = max(0.0, mu - 0.05);
  }
  
  // Change Euler integration
  if (key == '0') 
  {
    useSymplectic = !useSymplectic;
    String method = useSymplectic ? "Symplectic Euler" : "Explicit Euler";
    println("=== Switched to " + method + " ===");
    
    //
    ballPos.set(startPos);
    ballVel.set(0, 0);
    lastEnergyLogTime = millis() / 1000.0;
  }
  
  if (isTiltControl) 
  {
    angleX = constrain(angleX, -maxAngle, maxAngle);
    angleZ = constrain(angleZ, -maxAngle, maxAngle);
  }
  
  if (key == 'r' || key == 'R') 
  {
    ballPos.set(startPos);
    ballVel.set(0, 0);
  }
  
  if (key == BACKSPACE || key == DELETE) 
  {
    resetGame();
  }
}

void resetGame()
{
  ballPos.set(startPos);
  ballVel.set(0, 0);
  
  angleX = 0;
  angleZ = 0;
  
  gameWin = false;
  
  startTime = millis();
  
  holes.clear();
  setupHoles();
  
  println("Game reset!");
}
