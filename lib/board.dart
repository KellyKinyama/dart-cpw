import 'dart:io';

import 'package:dart_cpw/piece.dart';

class Board {
  bool whiteKingsideCastle = true;
  bool whiteQueensideCastle = true;
  bool blackKingsideCastle = true;
  bool blackQueensideCastle = true;

  bool whiteCanEnPassant = false; // White's en passant opportunity
  bool blackCanEnPassant = false; // Black's en passant opportunity

  List<Piece?> pieces = List.filled(128, null); // 128 squares (null = empty)
  List<bool> squares = List.filled(128, false); // False = illegal, True = legal

  static const int boardSize = 128;
  static const int rankMask = 0x70;
  static const int fileMask = 0x07;
  static const String files = "abcdefgh";

  // Checks if a square is off the board
  bool isOffBoard(int sq0x88) {
    return (sq0x88 & 0x88) != 0;
  }

  Board() {
    _initializeBoard();
    _setupInitialPieces();
  }

  void _initializeBoard() {
    for (int index = 0; index < 128; index++) {
      if ((index & 0x88) == 0) {
        squares[index] = true; // Legal squares
      }
    }
  }

  void _setupInitialPieces() {
    // White pieces (bottom)
    placePiece(0x00, Piece(1, PieceType.ROOK, Color.WHITE));
    placePiece(0x01, Piece(2, PieceType.KNIGHT, Color.WHITE));
    placePiece(0x02, Piece(3, PieceType.BISHOP, Color.WHITE));
    placePiece(0x03, Piece(4, PieceType.QUEEN, Color.WHITE));
    placePiece(0x04, Piece(5, PieceType.KING, Color.WHITE));
    placePiece(0x05, Piece(6, PieceType.BISHOP, Color.WHITE));
    placePiece(0x06, Piece(7, PieceType.KNIGHT, Color.WHITE));
    placePiece(0x07, Piece(8, PieceType.ROOK, Color.WHITE));

    // White pawns
    for (int i = 0; i < 8; i++) {
      placePiece(0x10 + i, Piece(9 + i, PieceType.PAWN, Color.WHITE));
    }

    // Black pieces (top)
    placePiece(0x70, Piece(17, PieceType.ROOK, Color.BLACK));
    placePiece(0x71, Piece(18, PieceType.KNIGHT, Color.BLACK));
    placePiece(0x72, Piece(19, PieceType.BISHOP, Color.BLACK));
    placePiece(0x73, Piece(20, PieceType.QUEEN, Color.BLACK));
    placePiece(0x74, Piece(21, PieceType.KING, Color.BLACK));
    placePiece(0x75, Piece(22, PieceType.BISHOP, Color.BLACK));
    placePiece(0x76, Piece(23, PieceType.KNIGHT, Color.BLACK));
    placePiece(0x77, Piece(24, PieceType.ROOK, Color.BLACK));

    // Black pawns
    for (int i = 0; i < 8; i++) {
      placePiece(0x60 + i, Piece(25 + i, PieceType.PAWN, Color.BLACK));
    }
  }

  void placePiece(int index, Piece piece) {
    if (index >= 0 && index < 128 && squares[index]) {
      pieces[index] = piece;
    }
  }

  void printBoard() {
    for (int row = 7; row >= 0; row--) {
      String line = "";
      for (int col = 0; col < 16; col++) {
        int index = (row * 16) + col;
        String cell;
        if (!squares[index]) {
          cell = "X"; // Illegal square
        } else if (pieces[index] != null) {
          cell = pieces[index]!.symbol; // Piece symbol
        } else {
          cell = "."; // Empty square
        }
        line += cell.padRight(3);
      }
      print(line);
    }
  }

  // Converts algebraic notation (e.g., "e6") to 0x88 index
  int? algebraicTo0x88(String notation) {
    if (notation.length != 2) return null;

    int file = files.indexOf(notation[0]);
    int rank = int.tryParse(notation[1]) ?? -1;

    if (file == -1 || rank < 1 || rank > 8) return null; // Invalid notation

    return to0x88(file, rank - 1); // Convert 1-based rank to 0-based
  }

  // Converts rank and file (0-based) to 0x88 index
  static int to0x88(int file, int rank) {
    return (rank << 4) | file;
  }

  // Extracts file (0-7) from 0x88 index
  int fileFrom0x88(int sq0x88) {
    return sq0x88 & fileMask;
  }

  // Extracts rank (0-7) from 0x88 index
  int rankFrom0x88(int sq0x88) {
    return (sq0x88 & rankMask) >> 4;
  }

  List<int> generateMoves(int index) {
    List<int> moves = [];
    Piece? piece = pieces[index];

    if (piece == null) return moves; // No piece at this square

    switch (piece.type) {
      case PieceType.PAWN:
        moves.addAll(_generatePawnMoves(index, piece.color));
        break;
      case PieceType.KNIGHT:
        moves.addAll(_generateKnightMoves(index, piece.color));
        break;
      case PieceType.BISHOP:
        moves.addAll(
            _generateSlidingMoves(index, piece.color, [15, 17, -15, -17]));
        break;
      case PieceType.ROOK:
        moves.addAll(
            _generateSlidingMoves(index, piece.color, [1, -1, 16, -16]));
        break;
      case PieceType.QUEEN:
        moves.addAll(_generateSlidingMoves(
            index, piece.color, [1, -1, 16, -16, 15, 17, -15, -17]));
        break;
      case PieceType.KING:
        moves.addAll(_generateKingMoves(index, piece.color));
        break;
      default:
        break;
    }

    return moves;
  }

  List<int> _generatePawnMoves(int index, Color color) {
    List<int> moves = [];
    int direction =
        (color == Color.WHITE) ? 16 : -16; // White moves up, black moves down

    int front = index + direction;
    if (squares[front] && pieces[front] == null) {
      moves.add(front);

      // Double move from starting position
      if ((color == Color.WHITE && index >= 16 && index <= 23) ||
          (color == Color.BLACK && index >= 96 && index <= 103)) {
        int doubleMove = front + direction;
        if (pieces[doubleMove] == null) moves.add(doubleMove);
      }
    }

    // Captures
    for (int side in [-1, 1]) {
      int captureSquare = front + side;
      if ((captureSquare & 0x88) == 0 &&
          pieces[captureSquare] != null &&
          pieces[captureSquare]!.color != color) {
        moves.add(captureSquare);
      }
    }

    // En Passant logic
    if (color == Color.WHITE && index >= 48 && index <= 55) {
      // White pawn can en passant (if it's on the 5th rank)
      int leftEnPassant = front - 1;
      int rightEnPassant = front + 1;
      if (pieces[leftEnPassant]?.type == PieceType.PAWN &&
          pieces[leftEnPassant]?.color == Color.BLACK &&
          blackCanEnPassant) {
        moves.add(front - 16); // Capture to the left
      }
      if (pieces[rightEnPassant]?.type == PieceType.PAWN &&
          pieces[rightEnPassant]?.color == Color.BLACK &&
          blackCanEnPassant) {
        moves.add(front - 16); // Capture to the right
      }
    } else if (color == Color.BLACK && index >= 72 && index <= 79) {
      // Black pawn can en passant (if it's on the 4th rank)
      int leftEnPassant = front - 1;
      int rightEnPassant = front + 1;
      if (pieces[leftEnPassant]?.type == PieceType.PAWN &&
          pieces[leftEnPassant]?.color == Color.WHITE &&
          whiteCanEnPassant) {
        moves.add(front + 16); // Capture to the left
      }
      if (pieces[rightEnPassant]?.type == PieceType.PAWN &&
          pieces[rightEnPassant]?.color == Color.WHITE &&
          whiteCanEnPassant) {
        moves.add(front + 16); // Capture to the right
      }
    }

    // Pawn promotion check
    if ((color == Color.WHITE && index >= 112 && index <= 119) ||
        (color == Color.BLACK && index >= 8 && index <= 15)) {
      // Add promotion moves to the list
      // Promote to a Queen (default), can modify later for other pieces
      moves.add(front); // Add the move as a promotion to a queen
    }

    return moves;
  }

  List<int> _generateKnightMoves(int index, Color color) {
    List<int> moves = [];
    List<int> offsets = [-33, -31, -18, -14, 14, 18, 31, 33];

    for (int offset in offsets) {
      int target = index + offset;
      if ((target & 0x88) == 0 &&
          (pieces[target] == null || pieces[target]!.color != color)) {
        moves.add(target);
      }
    }
    return moves;
  }

  List<int> _generateSlidingMoves(
      int index, Color color, List<int> directions) {
    List<int> moves = [];

    for (int dir in directions) {
      int target = index;
      while (true) {
        target += dir;
        if ((target & 0x88) != 0) break; // Stop if out of bounds

        if (pieces[target] == null) {
          moves.add(target);
        } else {
          if (pieces[target]!.color != color) moves.add(target); // Capture
          break;
        }
      }
    }

    return moves;
  }

  List<int> _generateKingMoves(int index, Color color) {
    List<int> moves = [];
    List<int> offsets = [-1, 1, -16, 16, -17, -15, 17, 15];

    for (int offset in offsets) {
      int target = index + offset;
      if ((target & 0x88) == 0 &&
          (pieces[target] == null || pieces[target]!.color != color)) {
        moves.add(target);
      }
    }

    // Add castling moves
    moves.addAll(_generateCastlingMoves(index, color));

    return moves;
  }

  List<int> _generateCastlingMoves(int index, Color color) {
    List<int> moves = [];
    bool kingsideAllowed =
        (color == Color.WHITE) ? whiteKingsideCastle : blackKingsideCastle;
    bool queensideAllowed =
        (color == Color.WHITE) ? whiteQueensideCastle : blackQueensideCastle;

    int rowStart =
        (color == Color.WHITE) ? 0x04 : 0x74; // e1 (0x04) or e8 (0x74)

    if (index == rowStart) {
      // Kingside castling
      if (kingsideAllowed &&
          pieces[index + 1] == null &&
          pieces[index + 2] == null &&
          !_isSquareAttacked(index, color) &&
          !_isSquareAttacked(index + 1, color) &&
          !_isSquareAttacked(index + 2, color)) {
        moves.add(index + 2); // King moves two squares right
      }

      // Queenside castling
      if (queensideAllowed &&
          pieces[index - 1] == null &&
          pieces[index - 2] == null &&
          pieces[index - 3] == null &&
          !_isSquareAttacked(index, color) &&
          !_isSquareAttacked(index - 1, color) &&
          !_isSquareAttacked(index - 2, color)) {
        moves.add(index - 2); // King moves two squares left
      }
    }

    return moves;
  }

  bool _isSquareAttacked(int index, Color color) {
    for (int i = 0; i < 128; i++) {
      if ((i & 0x88) != 0 || pieces[i] == null || pieces[i]!.color == color)
        continue;

      List<int> enemyMoves = generateMoves(i);
      if (enemyMoves.contains(index)) return true;
    }
    return false;
  }

  int? enpassantSquare;
  int? enpassantPieceSquare;
  void makeMove(int from, int to) {
    Piece? piece = pieces[from];
    if (piece == null) return;

    // En Passant logic
    if (piece.type == PieceType.PAWN && (from - to).abs() == 16) {
      // Pawn moves two squares forward
      if (piece.color == Color.WHITE) {
        whiteCanEnPassant = true;
      } else if (piece.color == Color.BLACK) {
        blackCanEnPassant = true;
      }
    }

    // En Passant capture
    // if (piece.type == PieceType.PAWN && (to - from).abs() == 1) {
    //   if (piece.color == Color.WHITE &&
    //       blackCanEnPassant &&
    //       pieces[to] == null) {
    //     pieces[to - 16] = null; // Capture the opponent's pawn en passant
    //     whiteCanEnPassant = false;
    //   } else if (piece.color == Color.BLACK &&
    //       whiteCanEnPassant &&
    //       pieces[to] == null) {
    //     pieces[to + 16] = null; // Capture the opponent's pawn en passant
    //     blackCanEnPassant = false;
    //   }
    // }

    // En Passant capture
    if (piece.type == PieceType.PAWN && to == enpassantSquare) {
      //if (rankFrom0x88(to) == 2) {
      print("Enpassant capture: ${to.toRadixString(16)}");
      print("Enpassant capture: ${enpassantSquare!.toRadixString(16)}");
      print("Enpassant capture: ${enpassantSquare!.toRadixString(16)}");
      print("Enpassant capture: ${enpassantPieceSquare!.toRadixString(16)}");
      print("Enpassant capture: ${pieces[enpassantPieceSquare!]}");
      pieces[enpassantPieceSquare!] = null;
      // }
      //pieces[enpassantPieceSquare!] != null;
      // if (piece.color == Color.WHITE &&
      //     blackCanEnPassant &&
      //     pieces[to] == null) {
      // pieces[to - 16] = null; // Capture the opponent's pawn en passant
      // whiteCanEnPassant = false;
      // } else if (piece.color == Color.BLACK &&
      //     whiteCanEnPassant &&
      //     pieces[to] == null) {
      //   pieces[to + 16] = null; // Capture the opponent's pawn en passant
      //   blackCanEnPassant = false;
      // }
    }

    if (piece.type == PieceType.PAWN &&
        piece.color == Color.BLACK &&
        rankFrom0x88(from) == 6 &&
        rankFrom0x88(to) == 4) {
      print("pawn move from: ${rankFrom0x88(from)}");
      if (!isOffBoard(to + 1) &&
          rankFrom0x88(to + 1) == 4 &&
          pieces[to + 1] != null &&
          pieces[to + 1]!.type == PieceType.PAWN &&
          pieces[to + 1]!.color == Color.WHITE) {
        enpassantSquare = to + 16;
        enpassantPieceSquare = to;
        print(
            'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        print(
            "${pieces[to + 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
      }

      if (!isOffBoard(to - 1) &&
          rankFrom0x88(to - 1) == 4 &&
          pieces[to - 1] != null &&
          pieces[to - 1]!.type == PieceType.PAWN &&
          pieces[to - 1]!.color == Color.WHITE) {
        enpassantSquare = to + 16;
        enpassantPieceSquare = to;

        print(
            'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        print(
            "${pieces[to - 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
      }
    } else if (piece.type == PieceType.PAWN &&
        piece.color == Color.WHITE &&
        rankFrom0x88(from) == 1 &&
        rankFrom0x88(to) == 3) {
      print("pawn move from: ${rankFrom0x88(from)}");
      if (!isOffBoard(to + 1) &&
          rankFrom0x88(to + 1) == 3 &&
          pieces[to + 1] != null &&
          pieces[to + 1]!.type == PieceType.PAWN &&
          pieces[to + 1]!.color == Color.BLACK) {
        enpassantSquare = to - 16;
        enpassantPieceSquare = to;

        print("empassant: e4d3");

        print(
            'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        print(
            "${pieces[to + 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
      }

      if (!isOffBoard(to - 1) &&
          rankFrom0x88(to - 1) == 3 &&
          pieces[to - 1] != null &&
          pieces[to - 1]!.type == PieceType.PAWN &&
          pieces[to - 1]!.color == Color.BLACK) {
        enpassantSquare = to - 16;
        enpassantPieceSquare = to;

        print(
            'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        print(
            "${pieces[to - 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
      }
    }

    // Check if this is a castling move
    if (piece.type == PieceType.KING && (to - from).abs() == 2) {
      // Kingside Castling
      if (to > from) {
        pieces[to] = piece;
        pieces[from] = null;
        pieces[from + 3] = null;
        pieces[from + 1] =
            Piece(1, PieceType.ROOK, piece.color); // Assigning rook with id 1
      }
      // Queenside Castling
      else {
        pieces[to] = piece;
        pieces[from] = null;
        pieces[from - 4] = null;
        pieces[from - 1] =
            Piece(2, PieceType.ROOK, piece.color); // Assigning rook with id 2
      }
    } else {
      // Normal move
      pieces[to] = piece;
      pieces[from] = null;
    }

    // Disable castling rights if king or rook moves
    if (piece.type == PieceType.KING) {
      if (piece.color == Color.WHITE) {
        whiteKingsideCastle = false;
        whiteQueensideCastle = false;
      } else {
        blackKingsideCastle = false;
        blackQueensideCastle = false;
      }
    }
    if (piece.type == PieceType.ROOK) {
      if (from == 0x00) whiteQueensideCastle = false; // a1 rook
      if (from == 0x07) whiteKingsideCastle = false; // h1 rook
      if (from == 0x70) blackQueensideCastle = false; // a8 rook
      if (from == 0x77) blackKingsideCastle = false; // h8 rook
    }

    // Reset en passant flags after each move
    if (piece.type == PieceType.PAWN) {
      if (piece.color == Color.WHITE) {
        blackCanEnPassant = false; // Black can't en passant after White moves
      } else {
        whiteCanEnPassant = false; // White can't en passant after Black moves
      }
    }
  }

  // Converts 128-board index to algebraic notation (e.g., 0x10 -> e2)
  String indexToAlgebraicNotation(int index) {
    // Convert the index to a rank (1 to 8) and file (a to h)
    int row = (index ~/ 16) - 2; // Offset by 2 rows for the 128-board
    int col = (index % 16);

    // Ensure it's a valid square
    if ((index & 0x88) != 0 ||
        !squares[index] ||
        row < 0 ||
        row > 7 ||
        col < 0 ||
        col > 7) {
      throw FormatException('Invalid board index');
    }

    // File (a-h), based on column 0-7
    String file = String.fromCharCode('a'.codeUnitAt(0) + col);

    // Rank (1-8), based on row 0-7
    String rank = (8 - row).toString();

    return file + rank;
  }
}

// void main() {
//   Board board = Board();
//   board.printBoard();

//   int index = 0x14; // Example: White pawn at e2 (0x14)
//   List<int> moves = board.generateMoves(index);

//   print("Valid moves: $moves");
//   // print("Move: 0x34: ${board.indexToAlgebraicNotation(0x34)}");
//   // board.makeMove(0x14, 0x34);
//   // board.printBoard();

//   // Test case: e6 -> 0x88 index
//   String notation = "e2";
//   int? sq0x88 = board.algebraicTo0x88(notation);
//   if (sq0x88 != null) {
//     print('$notation -> 0x88: 0x${sq0x88.toRadixString(16)}');
//     print(
//         'File: ${board.fileFrom0x88(sq0x88)}, Rank: ${board.rankFrom0x88(sq0x88)}');
//   }
// }

void main() {
  Board board = Board();
  print("id name DartChess");
  print("id author YourName");
  print("uciok");

  // int? startfromSq = board.algebraicTo0x88("e2");

  // int? startfromTosSq = board.algebraicTo0x88("e3");

  // board.makeMove(startfromSq!, startfromTosSq!);

  // startfromSq = board.algebraicTo0x88("e7");

  // startfromTosSq = board.algebraicTo0x88("e5");

  // board.makeMove(startfromSq!, startfromTosSq!);

  // startfromSq = board.algebraicTo0x88("a2");

  // startfromTosSq = board.algebraicTo0x88("a3");

  // board.makeMove(startfromSq!, startfromTosSq!);

  // startfromSq = board.algebraicTo0x88("e5");

  // startfromTosSq = board.algebraicTo0x88("e4");

  // board.makeMove(startfromSq!, startfromTosSq!);

  // board.printBoard();

  while (true) {
    stdout.write(""); // Ensures prompt is ready
    String? input = stdin.readLineSync()?.trim();

    if (input == null) continue;

    String strFrom = "${input[0]}${input[1]}";

    String strTo = "${input[2]}${input[3]}";

    int? fromSq = board.algebraicTo0x88(strFrom);

    int? fromTosSq = board.algebraicTo0x88(strTo);

    board.makeMove(fromSq!, fromTosSq!);
    board.printBoard();

    // int? sq0x88 = board.algebraicTo0x88(notation);

    // print("index: $sq0x88");

    // if (sq0x88 != null) {
    //   print('$notation -> 0x88: 0x${sq0x88.toRadixString(16)}');
    //   print(
    //       'File: ${board.fileFrom0x88(sq0x88)}, Rank: ${board.rankFrom0x88(sq0x88)}');
    // }

    // switch (input) {
    //   case "uci":
    //     print("id name DartChess");
    //     print("id author YourName");
    //     print("uciok");
    //     break;
    //   case "isready":
    //     print("readyok");
    //     break;
    //   case "quit":
    //     exit(0);

    //   case "move":
    //   default:
    //     if (input.startsWith("position")) {
    //       print("Position command received: $input");
    //     } else if (input.startsWith("go")) {
    //       print("Go command received: $input");
    //     } else {
    //       print("Unknown command: $input");
    //     }
    // }
  }
}
