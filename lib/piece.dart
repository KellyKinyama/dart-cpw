enum PieceType { NO_PIECE, PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }

enum Color { NONE, WHITE, BLACK }

class Piece {
  final int id;
  final PieceType type;
  final Color color;

  Piece(this.id, this.type, this.color);

  // Get piece symbol for board display
  String get symbol {
    if (color == Color.WHITE) {
      return switch (type) {
        PieceType.PAWN => "P",
        PieceType.KNIGHT => "N",
        PieceType.BISHOP => "B",
        PieceType.ROOK => "R",
        PieceType.QUEEN => "Q",
        PieceType.KING => "K",
        _ => " ",
      };
    } else if (color == Color.BLACK) {
      return switch (type) {
        PieceType.PAWN => "p",
        PieceType.KNIGHT => "n",
        PieceType.BISHOP => "b",
        PieceType.ROOK => "r",
        PieceType.QUEEN => "q",
        PieceType.KING => "k",
        _ => " ",
      };
    }
    return " ";
  }

  @override
  String toString() {
    return "${color == Color.WHITE ? "White" : "Black"} ${type.name}";
  }
}

void main() {
  Piece whiteKing = Piece(1, PieceType.KING, Color.WHITE);
  Piece blackQueen = Piece(2, PieceType.QUEEN, Color.BLACK);
  Piece empty = Piece(0, PieceType.NO_PIECE, Color.NONE);

  print(whiteKing); // White King
  print(blackQueen); // Black Queen
  print("Symbol: ${whiteKing.symbol}"); // Symbol: K
  print("Symbol: ${blackQueen.symbol}"); // Symbol: q
  print("Empty: ${empty.symbol}"); // Empty: (space)
}
