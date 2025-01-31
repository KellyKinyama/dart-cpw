import 'dart:math';
import 'package:dart_cpw/piece.dart';

Map<String, int> algebraicToIndex = {};
Map<String, int> indexToAlgebraic = {};
Map<String, int> indexTo = {};
Map<String, int> indexToAlgebraic = {};

class Board {
  bool whiteKingsideCastle = true;
  bool whiteQueensideCastle = true;
  bool blackKingsideCastle = true;
  bool blackQueensideCastle = true;

  bool whiteCanEnPassant = false; // White's en passant opportunity
  bool blackCanEnPassant = false; // Black's en passant opportunity

  List<Piece?> pieces = List.filled(128, null); // 128 squares (null = empty)
  List<bool> squares = List.filled(128, false); // False = illegal, True = legal

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
    if (piece.type == PieceType.PAWN && (to - from).abs() == 1) {
      if (piece.color == Color.WHITE &&
          blackCanEnPassant &&
          pieces[to] == null) {
        pieces[to - 16] = null; // Capture the opponent's pawn en passant
        whiteCanEnPassant = false;
      } else if (piece.color == Color.BLACK &&
          whiteCanEnPassant &&
          pieces[to] == null) {
        pieces[to + 16] = null; // Capture the opponent's pawn en passant
        blackCanEnPassant = false;
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

  int algebraicToIndex(String algebraic) {
    if (algebraic.length != 2) {
      throw FormatException('Invalid algebraic notation');
    }

    // Extract file and rank from the algebraic notation
    String file = algebraic[0].toLowerCase(); // 'a' to 'h'
    String rank = algebraic[1]; // '1' to '8'

    // Convert file ('a' to 'h') to column (0 to 7)
    int col = file.codeUnitAt(0) - 'a'.codeUnitAt(0);

    // Convert rank ('1' to '8') to row (7 to 0)
    int row = 8 - int.parse(rank); // Reverse rank to fit row order

    // Check for out-of-bounds values
    if (col < 0 || col > 7 || row < 0 || row > 7) {
      throw FormatException('Invalid algebraic notation');
    }

    // Calculate the board index using the 0x88 system logic
    // Each row is offset by 16, but valid squares are only from 0x00 to 0x77.
    int index = (row * 16) + col;

    // Ensure the index is within the valid range of the board (0x00 to 0x77)
    if (index < 0 || index >= 128 || (index & 0x88) != 0) {
      throw FormatException('Invalid square on the board');
    }

    return index;
  }

  List<int> algebraicToMove(String move) {
    if (move.length != 4) {
      throw FormatException('Invalid move format');
    }

    // Get the from and to positions from the move string
    String from = move.substring(0, 2);
    String to = move.substring(2, 4);

    // Convert the algebraic notation to indices
    int fromIndex = algebraicToIndex(from);
    int toIndex = algebraicToIndex(to);

    return [fromIndex, toIndex];
  }
}

// void main() {
//   Board board = Board();
//   board.printBoard();

//   Random random = Random();
//   int turn = 0;

//   // Simulate random moves for a game
//   while (true) {
//     // Choose a random piece to move
//     List<int> validMoves = [];
//     for (int i = 0; i < 128; i++) {
//       if (board.pieces[i] != null &&
//           (turn % 2 == 0
//               ? board.pieces[i]!.color == Color.WHITE
//               : board.pieces[i]!.color == Color.BLACK)) {
//         validMoves.add(i);
//       }
//     }

//     if (validMoves.isEmpty) break; // No valid moves left

//     int from = validMoves[random.nextInt(validMoves.length)];
//     List<int> moves = board.generateMoves(from);

//     if (moves.isNotEmpty) {
//       int to = moves[random.nextInt(moves.length)];
//       board.makeMove(from, to);
//       print("Move: $from to $to");
//       board.printBoard();
//     }

//     turn++;
//   }
// }

void main() {
  Board board = Board();
  board.printBoard();
  String move = "d2d4";
  List<int> indices = board.algebraicToMove(move);
  print("From: ${indices[0]}, To: ${indices[1]}"); // Output: From: 16, To: 32
}
