import 'dart:io';
import 'dart:math';

import 'package:dart_cpw/gameline.dart';
import 'package:dart_cpw/piece.dart';

import 'move.dart';
import 'search.dart';
import 'uci_parser.dart';

class Board {
  bool whiteKingsideCastle = true;
  bool whiteQueensideCastle = true;
  bool blackKingsideCastle = true;
  bool blackQueensideCastle = true;

  bool whiteCanPass = false; // White's en passant opportunity
  bool blackCanPass = false; // Black's en passant opportunity

  List<Piece?> pieces = List.filled(128, null); // 128 squares (null = empty)
  List<bool> squares = List.filled(128, false); // False = illegal, True = legal

  Map<String, Move> rootMoves = {};

  static const int boardSize = 128;
  static const int rankMask = 0x70;
  static const int fileMask = 0x07;
  static const String files = "abcdefgh";

  int whiteKingSquare = 0x04;
  int blackKingSquare = 0x74;

  List<GameLineRecord?> gameLine = [];

  Color sideToMove = Color.WHITE;
  int endOfSearch = 0;

  // Checks if a square is off the board
  bool isOffBoard(int sq0x88) {
    return (sq0x88 & 0x88) != 0;
  }

  Board() {
    sideToMove = Color.WHITE;
    _initializeBoard();
    _setupInitialPieces();
  }

  void init() {
    sideToMove = Color.WHITE;
    pieces = List.filled(128, null); // 128 squares (null = empty)
    squares = List.filled(128, false); // False = illegal, True = legal
    _initializeBoard();
    _setupInitialPieces();
  }

  void _initializeBoard() {
    sideToMove = Color.WHITE;
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

    whiteKingSquare = 0x04;

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

    blackKingSquare = 0x74;

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

  String algebraicFromSquare(int square) {
    int file = fileFrom0x88(square); // Extract file (0-7)
    int rank = rankFrom0x88(square); // Extract rank (0-7)

    return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
  }

  List<Move> generalPseudoMoves() {
    List<Move> pMoves = [];

    for (int index = 0; index < 128; index++) {
      if (pieces[index] == null) {
        continue;
      } else if (pieces[index]!.color != sideToMove) {
        continue;
      }
      List<int> moves = generateMoves(index);
      for (var move in moves) {
        pMoves.add(Move(index, move));
      }
    }
    return pMoves;
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
    if ((front >= 0 && front < 128) &&
        squares[front] &&
        pieces[front] == null) {
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
      if (pieces[leftEnPassant] != null &&
          pieces[leftEnPassant]!.type == PieceType.PAWN &&
          pieces[leftEnPassant]!.color == Color.BLACK &&
          blackCanPass) {
        moves.add(front - 16); // Capture to the left
      }
      if (pieces[rightEnPassant] != null &&
          pieces[rightEnPassant]!.type == PieceType.PAWN &&
          pieces[rightEnPassant]!.color == Color.BLACK &&
          blackCanPass) {
        moves.add(front - 16); // Capture to the right
      }
    } else if (color == Color.BLACK && index >= 72 && index <= 79) {
      // Black pawn can en passant (if it's on the 4th rank)
      int leftEnPassant = front - 1;
      int rightEnPassant = front + 1;
      if (pieces[leftEnPassant] != null &&
          pieces[leftEnPassant]!.type == PieceType.PAWN &&
          pieces[leftEnPassant]!.color == Color.WHITE &&
          whiteCanPass) {
        moves.add(front + 16); // Capture to the left
      }
      if (pieces[rightEnPassant] != null &&
          pieces[rightEnPassant]!.type == PieceType.PAWN &&
          pieces[rightEnPassant]!.color == Color.WHITE &&
          whiteCanPass) {
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
        //if (!_isSquareAttacked(target, color)) {
        moves.add(target);
        //}
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

  bool inCheck() {
    int index;
    if (sideToMove == Color.WHITE) {
      index = blackKingSquare;
    } else {
      index = whiteKingSquare;
    }

    for (int i = 0; i < 128; i++) {
      if ((i & 0x88) != 0 ||
          pieces[i] == null ||
          pieces[i]!.color == sideToMove) {
        continue;
      }

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

    if (gameLine.isEmpty || gameLine.length < endOfSearch + 1) {
      gameLine.add(GameLineRecord(
          Move(from, to),
          whiteKingsideCastle,
          whiteQueensideCastle,
          blackKingsideCastle,
          blackQueensideCastle,
          enpassantSquare,
          enpassantPieceSquare,
          0));
    } else {
      gameLine[endOfSearch] = (GameLineRecord(
          Move(from, to),
          whiteKingsideCastle,
          whiteQueensideCastle,
          blackKingsideCastle,
          blackQueensideCastle,
          enpassantSquare,
          enpassantPieceSquare,
          0));
    }

    //gameLine[endOfSearch].key = board.hashkey;

    gameLine[endOfSearch]!.fillPieces(pieces);

    // En Passant capture
    if (piece.type == PieceType.PAWN && to == enpassantSquare && whiteCanPass) {
      //if (rankFrom0x88(to) == 2) {
      print("Enpassant capture: ${to.toRadixString(16)}");
      print("Enpassant capture: ${enpassantSquare!.toRadixString(16)}");
      print("Enpassant capture: ${enpassantSquare!.toRadixString(16)}");
      print("Enpassant capture: ${enpassantPieceSquare!.toRadixString(16)}");
      print("Enpassant capture: ${pieces[enpassantPieceSquare!]}");
      pieces[enpassantPieceSquare!] = null;
      whiteCanPass = false;
      enpassantSquare = null;
      enpassantPieceSquare = null;
    }

    // En Passant capture
    if (piece.type == PieceType.PAWN && to == enpassantSquare && blackCanPass) {
      //if (rankFrom0x88(to) == 2) {
      // print("Enpassant capture: ${to.toRadixString(16)}");
      // print("Enpassant capture: ${enpassantSquare!.toRadixString(16)}");
      // print("Enpassant capture: ${enpassantSquare!.toRadixString(16)}");
      // print("Enpassant capture: ${enpassantPieceSquare!.toRadixString(16)}");
      // print("Enpassant capture: ${pieces[enpassantPieceSquare!]}");
      pieces[enpassantPieceSquare!] = null;
      blackCanPass = false;
      enpassantSquare = null;
      enpassantPieceSquare = null;
    }

    if (piece.type == PieceType.PAWN &&
        piece.color == Color.BLACK &&
        rankFrom0x88(from) == 6 &&
        rankFrom0x88(to) == 4) {
      if (!isOffBoard(to + 1) &&
          rankFrom0x88(to + 1) == 4 &&
          pieces[to + 1] != null &&
          pieces[to + 1]!.type == PieceType.PAWN &&
          pieces[to + 1]!.color == Color.WHITE) {
        enpassantSquare = to + 16;
        enpassantPieceSquare = to;

        whiteCanPass = true;
        // print(
        //     'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        // print(
        //     "${pieces[to + 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
      }

      if (!isOffBoard(to - 1) &&
          rankFrom0x88(to - 1) == 4 &&
          pieces[to - 1] != null &&
          pieces[to - 1]!.type == PieceType.PAWN &&
          pieces[to - 1]!.color == Color.WHITE) {
        enpassantSquare = to + 16;
        enpassantPieceSquare = to;
        whiteCanPass = true;

        // print(
        //     'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        // print(
        //     "${pieces[to - 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
      }
    } else if (piece.type == PieceType.PAWN &&
        piece.color == Color.WHITE &&
        rankFrom0x88(from) == 1 &&
        rankFrom0x88(to) == 3) {
      if (!isOffBoard(to + 1) &&
          rankFrom0x88(to + 1) == 3 &&
          pieces[to + 1] != null &&
          pieces[to + 1]!.type == PieceType.PAWN &&
          pieces[to + 1]!.color == Color.BLACK) {
        enpassantSquare = to - 16;
        enpassantPieceSquare = to;
        blackCanPass = true;

        // print("empassant: e4d3");

        // print(
        //     'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        // print(
        //     "${pieces[to + 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
      }

      if (!isOffBoard(to - 1) &&
          rankFrom0x88(to - 1) == 3 &&
          pieces[to - 1] != null &&
          pieces[to - 1]!.type == PieceType.PAWN &&
          pieces[to - 1]!.color == Color.BLACK) {
        enpassantSquare = to - 16;
        enpassantPieceSquare = to;
        blackCanPass = true;

        // print(
        //     'Enpassant square: 0x88: 0x${enpassantSquare!.toRadixString(16)}');
        // print(
        //     "${pieces[to - 1]!.color} pawn move from: ${(to + 1).toRadixString(16)} can empassant");
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
        blackCanPass = false; // Black can't en passant after White moves
      } else {
        whiteCanPass = false; // White can't en passant after Black moves
      }
    }

    if (sideToMove == Color.WHITE) {
      sideToMove = Color.BLACK;
    } else {
      sideToMove = Color.WHITE;
    }

    if (piece.type == PieceType.KING) {
      if (piece.color == Color.WHITE) {
        whiteKingSquare = to;
      } else {
        blackKingSquare = to;
      }
    }

    gameLine[endOfSearch]!.whiteKingSquare = whiteKingSquare;
    gameLine[endOfSearch]!.blackKingSquare = blackKingSquare;

    endOfSearch++;

    if (endOfSearch == 0) {
      throw "end of search cannot be incremented to 0";
    }
  }

  void unmakeMove() {
    // Undo the last move by accessing the game line and restoring previous state

    GameLineRecord lastMove = gameLine[endOfSearch - 1]!;
    //print("game line record: $lastMove");

    // Restore the castling rights
    whiteKingsideCastle = lastMove.whiteKingsideCastle;
    whiteQueensideCastle = lastMove.whiteQueensideCastle;
    blackKingsideCastle = lastMove.blackKingsideCastle;
    blackQueensideCastle = lastMove.blackQueensideCastle;

    whiteKingSquare = lastMove.whiteKingSquare;

    blackKingSquare = lastMove.blackKingSquare;

    // Restore the en passant square
    enpassantSquare = lastMove.enpassantSquare;
    enpassantPieceSquare = lastMove.enpassantPieceSquare;

    // Update en passant abilities (based on previous state)

    fillPieces(lastMove.pieces);
    // Restore the side to move
    sideToMove = sideToMove == Color.WHITE ? Color.BLACK : Color.WHITE;

    // Decrease the end of search index
    endOfSearch--;
    if (endOfSearch == -1) {
      throw ("End of search error: $endOfSearch");
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

  void fillPieces(List<Piece?> boardPieces) {
    for (int x = 0; x < 128; x++) {
      if (boardPieces[x] == null) {
        pieces[x] = null;
        continue;
      }

      pieces[x] = Piece(x, boardPieces[x]!.type, boardPieces[x]!.color);
    }
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

  while (true) {
    stdout.write(""); // Ensures prompt is ready
    String? input = stdin.readLineSync()?.trim();

    if (input == null) continue;

    // String strFrom = "${input[0]}${input[1]}";

    // String strTo = "${input[2]}${input[3]}";

    // int? fromSq = board.algebraicTo0x88(strFrom);

    // int? fromTosSq = board.algebraicTo0x88(strTo);

    // board.makeMove(fromSq!, fromTosSq!);
    board.printBoard();

    // int? sq0x88 = board.algebraicTo0x88(notation);

    // print("index: $sq0x88");

    // if (sq0x88 != null) {
    //   print('$notation -> 0x88: 0x${sq0x88.toRadixString(16)}');
    //   print(
    //       'File: ${board.fileFrom0x88(sq0x88)}, Rank: ${board.rankFrom0x88(sq0x88)}');
    // }

    switch (input) {
      case "uci":
        print("id name DartChess");
        print("id author YourName");
        print("uciok");
        break;
      case "isready":
        print("readyok");
        break;
      case "quit":
        exit(0);

      case "move":
      default:
        if (input.startsWith("position")) {
          print("Position command received: $input");

          UCIParser.parsePosition(board, input);
        } else if (input.startsWith("go")) {
          print("Go command received: $input");
          UCIParser.parseGoCommand(board, input);
          search(board, 4, 0);

          //print("bestmove ${search(board)}");
        } else {
          print("Unknown command: $input");
        }
    }
  }
}

// void main() {
//   Board board = Board();
//   search(board, 7, 0);
//   //print("bestmove ${search(board, 1, 0)}");
//   // print("board state:");
//   // board.printBoard();
// }
