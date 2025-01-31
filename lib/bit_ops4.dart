class Bitboard {
  int bits = 0;

  void set(int sq) {
    bits |= (1 << sq);
  }

  bool get(int sq) {
    return (bits & (1 << sq)) != 0;
  }

  @override
  String toString() {
    return bits.toRadixString(2).padLeft(64, '0');
  }
}

class Board0x88 {
  static const int boardSize = 128;
  static const int rankMask = 0x70;
  static const int fileMask = 0x07;
  static const String files = "abcdefgh";

  // Converts rank and file (0-based) to 0x88 index
  static int to0x88(int file, int rank) {
    return (rank << 4) | file;
  }

  // Converts algebraic notation (e.g., "e6") to 0x88 index
  static int? algebraicTo0x88(String notation) {
    if (notation.length != 2) return null;

    int file = files.indexOf(notation[0]);
    int rank = int.tryParse(notation[1]) ?? -1;

    if (file == -1 || rank < 1 || rank > 8) return null; // Invalid notation

    return to0x88(file, rank - 1); // Convert 1-based rank to 0-based
  }

  // Checks if a square is off the board
  static bool isOffBoard(int sq0x88) {
    return (sq0x88 & 0x88) != 0;
  }

  // Generates knight moves using 0x88 offsets
  static Bitboard generateKnightMoves(int sq) {
    Bitboard moves = Bitboard();
    List<int> offsets = [-33, -31, -18, -14, 14, 18, 31, 33];

    for (int offset in offsets) {
      int target = sq + offset;
      if (!isOffBoard(target)) {
        moves.set(target);
      }
    }

    return moves;
  }

  // Converts 0x88 index to bitboard index (0-63)
  static int toBitboardIndex(int sq0x88) {
    return (sq0x88 & 7) + (sq0x88 >> 4) * 8;
  }

  // Prints a bitboard for debugging
  static void printBitboard(int bitboard) {
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
  int? knightSq = Board0x88.algebraicTo0x88("e4");
  if (knightSq != null) {
    print("Knight moves from e4:");
    print(Board0x88.generateKnightMoves(knightSq));
    final bb = Board0x88.generateKnightMoves(knightSq);
    Board0x88.printBitboard(bb.bits);
  }
}
