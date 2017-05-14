attribute vec4 Position; // 1
attribute vec4 SourceColor; // 2

varying vec4 DestinationColor; // 3

uniform mat4 Projection;
// Add right after the Projection uniform
uniform mat4 Modelview;

void main(void) { // 4
    DestinationColor = SourceColor; // 5
    // Modify the gl_Position line
    gl_Position = Projection * Modelview * Position;
}
