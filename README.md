# MIPS Arcade

Three graphical games implemented in MIPS assembly: Tic-Tac-Toe, Blackjack, and T-Rex Runner.

## Files

- `games.asm` — MIPS source for all three games.
- `MIPSArcade.jar` — MARS 4.5 packaged with a custom display/input extension.
- `ArcadeDevice.java` — source for the extension’s memory-mapped input and display interface.
- `ArcadeDisplay.java` — source for the graphical window and mouse/keyboard event handling.

The Java source files are included for reference. No compilation is required to run the supplied JAR.

## Running the Games

Java must be installed.

1. Select **Code → Download ZIP** and extract the downloaded folder.
2. Open `MIPSArcade.jar`. If double-clicking does not launch it, open a terminal in the extracted folder and run:
3. 3. In MARS, select **File → Open** and open `games.asm`.
4. Enable extended/pseudo instructions, disable delayed branching, and set the run-speed slider to **unlimited**.
5. Select **Run → Assemble**.
6. Open **Tools → Arcade Display and Input**, then click **Connect to MIPS**.
7. Select **Run → Go**.
8. Click inside the graphical display to select a game.

Use the included custom display tool. No separate Bitmap Display configuration is needed.

## Controls and Rules

### Tic-Tac-Toe

Two players alternate clicking empty squares. X moves first. Three matching marks in a row, column, or diagonal wins. A full board without a winner is a draw. Occupied squares and clicks outside valid cells do not consume a turn.

### Blackjack

Click **Hit** to draw a card or **Stand** to finish your turn. Aces count as 1 or 11, face cards count as 10, and the dealer stands on all totals of 17 or higher, including soft 17. Exceeding 21 causes a bust.

### T-Rex Runner

Click **Start** to begin. Press **W** to jump over cacti and hold **S** to crouch under birds. Release S to stand. Clearing ten obstacles wins; hitting an obstacle ends the game.

### Navigation

Click **Menu** to return to game selection. After a round, click **Replay** to play again.

## Implementation

Game rules, button hit testing, drawing routines, and T-Rex movement and collision logic run in MIPS. Arrays and memory store the game state, and reusable procedures handle input, graphics, and game logic.

The custom Java extension displays the MIPS framebuffer and passes mouse and keyboard input to the assembly program. The display uses a 64 × 64 framebuffer at address `0x10008000`, shown at 512 × 512 pixels.

No C or C++ planning or reference code was used.

## Testing

Automated tests were run in MARS for normal gameplay and edge cases, including wins, draws, occupied cells, invalid input, ace values, jumping, crouching, collisions, and replay behavior. Representative test cases and screenshots are included in the assignment PDF.

## Sources and AI Assistance

This project uses the MARS 4.5 MIPS simulator. With AI assistance, this project adds a custom Java display/input extension, packaged with MARS as `MIPSArcade.jar`. The three games are implemented in the accompanying `games.asm` file.

MARS project: https://dpetersanderson.github.io/
