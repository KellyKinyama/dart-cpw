import 'dart:io';

class ChessEngine {
  bool isStarted = false;

  // To handle the position and set the board state
  void setPosition(String command) {
    if (command == 'startpos') {
      print('Position: Start Position');
      // Here you can set the initial position of the chess board
      // Initialize the board
      resetBoard();
    } else if (command.startsWith('fen')) {
      String fen = command.substring(4); // Get the FEN string after "fen "
      print('Position: FEN: $fen');
      // Parse the FEN string and update the board
      // You need to implement a FEN parser
      parseFen(fen);
    } else {
      print('Unknown position format: $command');
    }
  }

  void resetBoard() {
    // Set the initial chess board here
    print("Setting to the initial board state.");
    isStarted = true;
  }

  void parseFen(String fen) {
    // Implement FEN parsing logic here to set up the board
    print("Parsing FEN: $fen");
  }

  void uciLoop() {
    print("id name DartChess");
    print("id author YourName");
    print("uciok");

    while (true) {
      stdout.write("> ");
      String? input = stdin.readLineSync()?.trim();

      if (input == null) continue;

      if (input == "uci") {
        print("id name DartChess");
        print("id author YourName");
        print("uciok");
      } else if (input == "isready") {
        print("readyok");
      } else if (input == "quit") {
        print("Exiting...");
        exit(0);
      } else if (input.startsWith("position")) {
        // Parse position command
        String positionCommand = input.substring(9).trim();
        setPosition(positionCommand);
      } else if (input.startsWith("go")) {
        print("Go command received: $input");
        // Add your move generation logic here
      } else {
        print("Unknown command: $input");
      }
    }
  }
}

void main() {
  ChessEngine engine = ChessEngine();
  engine.uciLoop();
}
