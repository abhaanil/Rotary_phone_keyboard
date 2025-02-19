import processing.serial.*;
PFont customFont;
PShape scribble;
PImage backgroundImage;

Serial myPort;  // The serial port
String inString;  // Input string from serial port
StringBuilder outputText = new StringBuilder();  // Stores the text being written
ArrayList<Integer> overlayIndices = new ArrayList<>();  // Tracks indices to overlay scribble
int currentDigit = -1;  // The last digit pressed
long lastInputTime = 0;  // Time when the last input was received
int pressCount = 0;  // Counts the number of presses for the same digit

// Key mappings
String[] keyMap = {
  " ",        // 0: Space
  "\b",       // 1: Backspace
  "ABC",      // 2: A, B, C
  "DEF",      // 3: D, E, F
  "GHI",      // 4: G, H, I
  "JKL",      // 5: J, K, L
  "MNO",      // 6: M, N, O
  "PQRS",     // 7: P, Q, R, S
  "TUV",      // 8: T, U, V
  "WXYZ"      // 9: W, X, Y, Z
};

// Timeout mapping for each digit (milliseconds)
int[] timeoutMap = {
  10, // 0: Space
  10,  // 1: Backspace
  1000,  // 2
  1200,  // 3
  1600,  // 4
  2000,  // 5
  2400, // 6
  2800, // 7
  3200, // 8
  3600  // 9
};

void setup() {
  size(1920, 1080);  // Set up the canvas
  backgroundImage = loadImage("notebook.jpg");
  println(Serial.list());  // List available serial ports
  myPort = new Serial(this, "/dev/cu.usbmodem311401", 9600);  // Update port name
  customFont = createFont("Pia.otf", 107);  // Font name and size
  textFont(customFont);  // Set it as the active font
  textSize(107);  // Set uniform font size
  scribble = loadShape("scribble.svg");  // Load the scribble SVG
  
}

void draw() {
  image(backgroundImage, 0, 0, width, height); 
  fill(102);  // Set text color to grey

  float x = 210;  // Horizontal starting position
  float y = 300;  // Vertical starting position
  float lineSpacing = textAscent() + textDescent() + 10;  // Line height with padding

  for (int i = 0; i < outputText.length(); i++) {
    char currentChar = outputText.charAt(i);
    float charWidth = textWidth(currentChar);

    // Check if the current character exceeds the canvas width
    if (x + charWidth > width - 210) {  // Adjust padding if needed
      x = 210;  // Reset x to the start of the line
      y += lineSpacing;  // Move to the next line
    }

    text(currentChar, x, y);  // Draw the character

    // If the character needs an overlay, draw the SVG
    if (overlayIndices.contains(i)) {
      float charHeight = textAscent() + textDescent();
      scribble.disableStyle();  // Disable SVG's internal styles
      fill(102);  // Set fill color to grey
      stroke(102);
      shape(scribble, x, y - charHeight, charWidth, charHeight);  // Adjusted for y-position
    }

    x += charWidth + 2;  // Move x to the next character position
  }

  // Check if timeout has occurred
  if (currentDigit != -1 && millis() - lastInputTime > timeoutMap[currentDigit]) {
    finalizeCharacter();
  }
}



void serialEvent(Serial myPort) {
  inString = myPort.readStringUntil('\n');  // Read until newline
  if (inString != null) {
    int digit = int(trim(inString));  // Parse the digit
    handleDigit(digit);
  }
}

void handleDigit(int digit) {
  long currentTime = millis();

  if (digit == currentDigit) {
    // Same digit pressed, increment press count
    pressCount++;
  } else {
    // New digit pressed, finalize the previous character if any
    finalizeCharacter();

    // Start a new input cycle
    currentDigit = digit;
    pressCount = 1;
  }

  lastInputTime = currentTime;
}

void finalizeCharacter() {
  if (currentDigit == 0) {
    outputText.append(" ");  // Append space
  } else if (currentDigit == 1) {
    // Handle multiple backspaces by overlaying SVG on the last unmarked character
    if (outputText.length() > 0) {
      int indexToMark = outputText.length() - 1;
      
      // Ensure we don't mark the same character multiple times
      while (overlayIndices.contains(indexToMark) && indexToMark >= 0) {
        indexToMark--;
      }

      if (indexToMark >= 0) {
        overlayIndices.add(indexToMark);  // Mark this character for overlay
      }
    }
  } else if (currentDigit >= 2 && currentDigit <= 9) {
    // Determine the letter based on the press count
    String chars = keyMap[currentDigit];
    int charIndex = (pressCount - 1) % chars.length();
    outputText.append(chars.charAt(charIndex));  // Append the selected character
  }

  // Reset input tracking
  currentDigit = -1;
  pressCount = 0;
}
