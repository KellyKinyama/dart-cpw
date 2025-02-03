import 'package:dart_cpw/board.dart';

import 'piece.dart';

class Evaluation {
  Board board;
  //static List<Piece?> pieces = List.filled(128, null);

  Evaluation(this.board);

  int evaluatePosition() {
    const Map<PieceType, int> pieceValues = {
      PieceType.PAWN: 100,
      PieceType.KNIGHT: 320,
      PieceType.BISHOP: 330,
      PieceType.ROOK: 500,
      PieceType.QUEEN: 900,
      PieceType.KING: 0, // King is invaluable
    };

    int score = 0;

    for (int square = 0; square < 128; square++) {
      if ((square & 0x88) != 0) continue; // Skip invalid squares

      Piece? piece = board.pieces[square];
      if (piece == null) continue;

      int pieceValue = pieceValues[piece.type] ?? 0;
      int positionalBonus = pieceSquareTable(piece.type, square, piece.color);

      if (piece.color == Color.WHITE) {
        score += pieceValue + positionalBonus;
      } else {
        score -= pieceValue + positionalBonus;
      }
    }

    // Adjust score for the side to move
    return (board.sideToMove == Color.WHITE) ? score : -score;
  }

  static int pieceSquareTable(PieceType type, int square, Color color) {
    List<int>? table = tables[type];
    if (table == null) return 0;

    int file = square % 16;
    int rank = square ~/ 16;

    // Ensure rank is valid (0-7)
    if (rank > 7 || file > 7) return 0;

    int index = (rank * 8) + file;
    if (color == Color.BLACK) {
      index = 56 + (file) - (rank * 8); // Correct flipping
    }

    return table[index];
  }

  int evaluatePawnStructure() {
    int penalty = 0;

    List<int> whitePawns = List.filled(8, 0);
    List<int> blackPawns = List.filled(8, 0);

    for (int square = 0; square < 128; square++) {
      if ((square & 0x88) != 0) continue;
      Piece? piece = board.pieces[square];
      if (piece == null || piece.type != PieceType.PAWN) continue;

      int file = square % 16;

      if (piece.color == Color.WHITE) {
        whitePawns[file]++;
      } else {
        blackPawns[file]++;
      }
    }

    for (int f = 0; f < 8; f++) {
      if (whitePawns[f] > 1)
        penalty -= 10 * (whitePawns[f] - 1); // Doubled pawn penalty
      if (blackPawns[f] > 1)
        penalty += 10 * (blackPawns[f] - 1); // Doubled pawn penalty

      if (whitePawns[f] > 0 &&
          (f == 0 || whitePawns[f - 1] == 0) &&
          (f == 7 || whitePawns[f + 1] == 0)) {
        penalty -= 20; // Isolated pawn penalty
      }
      if (blackPawns[f] > 0 &&
          (f == 0 || blackPawns[f - 1] == 0) &&
          (f == 7 || blackPawns[f + 1] == 0)) {
        penalty += 20; // Isolated pawn penalty
      }
    }

    return penalty;
  }

  int evaluateKingSafety() {
    int score = 0;

    int whiteKingSquare = -1, blackKingSquare = -1;
    for (int square = 0; square < 128; square++) {
      if ((square & 0x88) != 0) continue;
      Piece? piece = board.pieces[square];
      if (piece == null) continue;

      if (piece.type == PieceType.KING) {
        if (piece.color == Color.WHITE) {
          whiteKingSquare = square;
        } else {
          blackKingSquare = square;
        }
      }
    }

    if (whiteKingSquare >= 0) {
      if (whiteKingSquare == 0x02 || whiteKingSquare == 0x06)
        score += 30; // Castled
      if (whiteKingSquare == 0x04) score -= 20; // Uncastled
    }

    if (blackKingSquare >= 0) {
      if (blackKingSquare == 0x72 || blackKingSquare == 0x76)
        score -= 30; // Castled
      if (blackKingSquare == 0x74) score += 20; // Uncastled
    }

    return score;
  }

  int evaluate() {
    int score = evaluatePosition();
    score += evaluatePawnStructure();
    score += evaluateKingSafety();
    return score;
  }
}

void main() {
  Board board = Board();
  final eval = Evaluation(board);
  final val = eval.evaluate();
  print("Score: $val");
}

const Map<PieceType, List<int>> tables = {
  PieceType.PAWN: [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    50,
    50,
    50,
    50,
    50,
    50,
    50,
    50,
    10,
    10,
    20,
    30,
    30,
    20,
    10,
    10,
    5,
    5,
    10,
    25,
    25,
    10,
    5,
    5,
    0,
    0,
    0,
    20,
    20,
    0,
    0,
    0,
    5,
    -5,
    -10,
    0,
    0,
    -10,
    -5,
    5,
    5,
    10,
    10,
    -20,
    -20,
    10,
    10,
    5,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0
  ],
  PieceType.KNIGHT: [
    -50,
    -40,
    -30,
    -30,
    -30,
    -30,
    -40,
    -50,
    -40,
    -20,
    0,
    5,
    5,
    0,
    -20,
    -40,
    -30,
    5,
    10,
    15,
    15,
    10,
    5,
    -30,
    -30,
    0,
    15,
    20,
    20,
    15,
    0,
    -30,
    -30,
    5,
    15,
    20,
    20,
    15,
    5,
    -30,
    -30,
    0,
    10,
    15,
    15,
    10,
    0,
    -30,
    -40,
    -20,
    0,
    0,
    0,
    0,
    -20,
    -40,
    -50,
    -40,
    -30,
    -30,
    -30,
    -30,
    -40,
    -50
  ],
};
