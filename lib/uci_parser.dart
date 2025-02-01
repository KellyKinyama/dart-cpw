import 'board.dart';

class UCIParser {
  static void parsePosition(Board board, String command) {
    List<String> tokens = command.split(' ');
    if (tokens.length < 2 || tokens[0] != 'position') return;

    // Handle "position startpos"
    if (tokens[1] == 'startpos') {
      board.init();
    }

    // Check if moves exist
    int movesIndex = tokens.indexOf('moves');
    if (movesIndex != -1 && movesIndex + 1 < tokens.length) {
      List<String> moveList = tokens.sublist(movesIndex + 1);
      for (String move in moveList) {
        // int? from = Board0x88.algebraicTo0x88(move.substring(0, 2));
        // int? to = Board0x88.algebraicTo0x88(move.substring(2, 4));
        // if (from != null && to != null) {
        //   board.makeMove(from, to);
        // }

        int? fromSq = board.algebraicTo0x88("${move[0]}${move[1]}");

        int? fromTosSq = board.algebraicTo0x88("${move[2]}${move[3]}");
        print("Parsed move: ${move[0]}${move[1]}${move[2]}${move[3]}");
        if (fromSq != null && fromTosSq != null) {
          board.makeMove(fromSq, fromTosSq);
          board.printBoard();
          print("");
        } else {
          throw "invalid move: $move";
        }
      }
    }
  }

  static void parseGoCommand(Board board, String command) {
    List<String> tokens = command.split(' ');
    int? wtime, btime, winc, binc;

    for (int i = 0; i < tokens.length; i++) {
      switch (tokens[i]) {
        case 'wtime':
          wtime = int.tryParse(tokens[i + 1]);
          break;
        case 'btime':
          btime = int.tryParse(tokens[i + 1]);
          break;
        case 'winc':
          winc = int.tryParse(tokens[i + 1]);
          break;
        case 'binc':
          binc = int.tryParse(tokens[i + 1]);
          break;
      }
    }
    print(
        'White Time: $wtime ms, Black Time: $btime ms, White Increment: $winc ms, Black Increment: $binc ms');
  }
}

void main() {
  Board board = Board();
  String uciCommand =
      "position startpos moves e2e4 c7c6 d2d4 d7d5 e4e5 c8f5 f2f4 e7e6 g1f3 c6c5 c2c3 g8h6 f1d3 b8c6 e1g1 c5d4 c3d4 d8b6 g1h1 f5g4 b1c3 a7a6 c1e3 b6b2 c3a4 b2a3 a1b1 c6b4 b1b3";
  UCIParser.parsePosition(board, uciCommand);
  board.printBoard();
}
