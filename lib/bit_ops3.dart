import 'dart:typed_data';

class Board0x88 {
  static const int boardSize = 128;
  static const int rankMask = 0x70;
  static const int fileMask = 0x07;
  static const String files = "abcdefgh";

  // Bitboards
  int whitePawns = 0;
  int blackPawns = 0;
  int knights = 0;
  int bishops = 0;
  int rooks = 0;
  int queens = 0;
  int kings = 0;
  int whitePieces = 0;
  int blackPieces = 0;
  int occupied = 0;

  Board0x88();

  // Converts algebraic notation (e.g., "e6") to 0x88 index
  static int? algebraicTo0x88(String notation) {
    if (notation.length != 2) return null;
    int file = files.indexOf(notation[0]);
    int rank = int.tryParse(notation[1]) ?? -1;
    if (file == -1 || rank < 1 || rank > 8) return null;
    return to0x88(file, rank - 1);
  }

  // Converts 0x88 index to algebraic notation (e.g., 0x54 -> "e6")
  static String? toAlgebraic(int sq0x88) {
    if (isOffBoard(sq0x88)) return null;
    int file = fileFrom0x88(sq0x88);
    int rank = rankFrom0x88(sq0x88);
    return "${files[file]}${rank + 1}";
  }

  static int to0x88(int file, int rank) {
    return (rank << 4) | file;
  }

  static int fileFrom0x88(int sq0x88) {
    return sq0x88 & fileMask;
  }

  static int rankFrom0x88(int sq0x88) {
    return (sq0x88 & rankMask) >> 4;
  }

  static bool isOffBoard(int sq0x88) {
    return (sq0x88 & 0x88) != 0;
  }

  // Converts 0x88 index to bitboard index (0-63)
  static int toBitboardIndex(int sq0x88) {
    return (sq0x88 & 7) + (sq0x88 >> 4) * 8;
  }

  // Set a bit in a bitboard
  void setBit(int bitboard, int sq0x88) {
    bitboard |= (1 << toBitboardIndex(sq0x88));
  }

  // Pawn move generation (single push)
  int generatePawnMoves(int pawns, bool isWhite) {
    int moves = 0;
    if (isWhite) {
      moves = (pawns << 8) & ~occupied; // White pawns move up
    } else {
      moves = (pawns >> 8) & ~occupied; // Black pawns move down
    }
    return moves;
  }

  // Knight move generation
  int generateKnightMoves(int knightBoard) {
    int moves = 0;
    final List<int> knightOffsets = [-17, -15, -10, -6, 6, 10, 15, 17];

    for (int sq = 0; sq < 64; sq++) {
      if ((knightBoard & (1 << sq)) != 0) {
        for (var offset in knightOffsets) {
          int targetSq = sq + offset;
          if (targetSq >= 0 && targetSq < 64) {
            int target0x88 = to0x88(targetSq % 8, targetSq ~/ 8);
            if (!isOffBoard(target0x88)) {
              moves |= (1 << targetSq);
            }
          }
        }
      }
    }
    return moves;
  }

  // Bishop move generation (Sliding)
  int generateBishopMoves(int bishopBoard) {
    int moves = 0;
    for (int sq = 0; sq < 64; sq++) {
      if ((bishopBoard & (1 << sq)) != 0) {
        int sq0x88 = to0x88(sq % 8, sq ~/ 8);
        moves |= generateSlidingMoves(sq0x88, [-9, -7, 7, 9]);
      }
    }
    return moves;
  }

  // Rook move generation (Sliding)
  int generateRookMoves(int rookBoard) {
    int moves = 0;
    for (int sq = 0; sq < 64; sq++) {
      if ((rookBoard & (1 << sq)) != 0) {
        int sq0x88 = to0x88(sq % 8, sq ~/ 8);
        moves |= generateSlidingMoves(sq0x88, [-8, -1, 1, 8]);
      }
    }
    return moves;
  }

  // Generate moves for sliding pieces
  int generateSlidingMoves(int startSq, List<int> directions) {
    int moves = 0;
    for (int dir in directions) {
      int target = startSq;
      while (true) {
        target += dir;
        if (isOffBoard(target)) break;
        int bitIndex = toBitboardIndex(target);
        moves |= (1 << bitIndex);
        if ((occupied & (1 << bitIndex)) != 0) break;
      }
    }
    return moves;
  }

  // King move generation
  int generateKingMoves(int kingBoard) {
    int moves = 0;
    final List<int> kingOffsets = [-9, -8, -7, -1, 1, 7, 8, 9];

    for (int sq = 0; sq < 64; sq++) {
      if ((kingBoard & (1 << sq)) != 0) {
        for (var offset in kingOffsets) {
          int targetSq = sq + offset;
          if (targetSq >= 0 && targetSq < 64) {
            int target0x88 = to0x88(targetSq % 8, targetSq ~/ 8);
            if (!isOffBoard(target0x88)) {
              moves |= (1 << targetSq);
            }
          }
        }
      }
    }
    return moves;
  }

  // Prints a bitboard for debugging
  void printBitboard(int bitboard) {
    for (int rank = 7; rank >= 0; rank--) {
      String line = "";
      for (int file = 0; file < 8; file++) {
        int sq = toBitboardIndex(to0x88(file, rank));
        line += ((bitboard & (1 << sq)) != 0) ? "1 " : ". ";
      }
      print(line);
    }
    print("");
  }
}

void main() {
  Board0x88 board = Board0x88();

  // Set up some test pieces
  board.whitePawns =
      (1 << Board0x88.toBitboardIndex(Board0x88.algebraicTo0x88("e2")!));
  board.knights =
      (1 << Board0x88.toBitboardIndex(Board0x88.algebraicTo0x88("g1")!));
  board.rooks =
      (1 << Board0x88.toBitboardIndex(Board0x88.algebraicTo0x88("a1")!));
  board.kings =
      (1 << Board0x88.toBitboardIndex(Board0x88.algebraicTo0x88("e1")!));

  // Compute moves
  int pawnMoves = board.generatePawnMoves(board.whitePawns, true);
  int knightMoves = board.generateKnightMoves(board.knights);
  int rookMoves = board.generateRookMoves(board.rooks);
  int kingMoves = board.generateKingMoves(board.kings);

  // Print bitboards for moves
  print("Pawn Moves:");
  board.printBitboard(pawnMoves);

  print("Knight Moves:");
  board.printBitboard(knightMoves);

  print("Rook Moves:");
  board.printBitboard(rookMoves);

  print("King Moves:");
  board.printBitboard(kingMoves);
}
