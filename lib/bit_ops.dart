class Board0x88 {
  static const int boardSize = 128;
  static const int rankMask = 0x70;
  static const int fileMask = 0x07;
  static const String files = "abcdefgh";

  // Converts rank and file (0-based) to 0x88 index
  static int to0x88(int file, int rank) {
    return (rank << 4) | file;
  }

  // Extracts file (0-7) from 0x88 index
  static int fileFrom0x88(int sq0x88) {
    return sq0x88 & fileMask;
  }

  // Extracts rank (0-7) from 0x88 index
  static int rankFrom0x88(int sq0x88) {
    return (sq0x88 & rankMask) >> 4;
  }

  // Converts algebraic notation (e.g., "e6") to 0x88 index
  static int? algebraicTo0x88(String notation) {
    if (notation.length != 2) return null;

    int file = files.indexOf(notation[0]);
    int rank = int.tryParse(notation[1]) ?? -1;

    if (file == -1 || rank < 1 || rank > 8) return null; // Invalid notation

    return to0x88(file, rank - 1); // Convert 1-based rank to 0-based
  }

  // Converts 0x88 index to algebraic notation (e.g., 0x54 -> "e6")
  static String? toAlgebraic(int sq0x88) {
    if (isOffBoard(sq0x88)) return null;

    int file = fileFrom0x88(sq0x88);
    int rank = rankFrom0x88(sq0x88);

    return "${files[file]}${rank + 1}"; // Convert back to 1-based rank
  }

  // Checks if a square is off the board
  static bool isOffBoard(int sq0x88) {
    return (sq0x88 & 0x88) != 0;
  }
}

void main() {
  // Test case: e6 -> 0x88 index
  String notation = "e6";
  int? sq0x88 = Board0x88.algebraicTo0x88(notation);
  if (sq0x88 != null) {
    print('$notation -> 0x88: 0x${sq0x88.toRadixString(16)}');
    print(
        'File: ${Board0x88.fileFrom0x88(sq0x88)}, Rank: ${Board0x88.rankFrom0x88(sq0x88)}');
  }

  // Test case: e6 -> 0x88 index
  notation = "a1";
  sq0x88 = Board0x88.algebraicTo0x88(notation);
  if (sq0x88 != null) {
    print('$notation -> 0x88: 0x${sq0x88.toRadixString(16)}');
    print(
        'File: ${Board0x88.fileFrom0x88(sq0x88)}, Rank: ${Board0x88.rankFrom0x88(sq0x88)}');
  }

  // Test case: Convert back to algebraic notation
  int testSquare = 0x0; // e6 in 0x88
  String? algebraic = Board0x88.toAlgebraic(testSquare);
  print('0x88: 0x${testSquare.toRadixString(16)} -> $algebraic');

  // Test case: e6 -> 0x88 index
  notation = "h8";
  sq0x88 = Board0x88.algebraicTo0x88(notation);
  if (sq0x88 != null) {
    print('$notation -> 0x88: 0x${sq0x88.toRadixString(16)}');
    print(
        'File: ${Board0x88.fileFrom0x88(sq0x88)}, Rank: ${Board0x88.rankFrom0x88(sq0x88)}');
  }

  // Test case: Convert back to algebraic notation
  testSquare = 0x77; // e6 in 0x88
  algebraic = Board0x88.toAlgebraic(testSquare);
  print('0x88: 0x${testSquare.toRadixString(16)} -> $algebraic');
}
