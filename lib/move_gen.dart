import 'piece.dart';

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
      moves.addAll(_generateSlidingMoves(index, piece.color, [15, 17, -15, -17]));
      break;
    case PieceType.ROOK:
      moves.addAll(_generateSlidingMoves(index, piece.color, [1, -1, 16, -16]));
      break;
    case PieceType.QUEEN:
      moves.addAll(_generateSlidingMoves(index, piece.color, [1, -1, 16, -16, 15, 17, -15, -17]));
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
  int direction = (color == Color.WHITE) ? 16 : -16; // White moves up, black moves down

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
    if ((captureSquare & 0x88) == 0 && pieces[captureSquare] != null && pieces[captureSquare]!.color != color) {
      moves.add(captureSquare);
    }
  }

  return moves;
}

List<int> _generateKnightMoves(int index, Color color) {
  List<int> moves = [];
  List<int> offsets = [-33, -31, -18, -14, 14, 18, 31, 33];

  for (int offset in offsets) {
    int target = index + offset;
    if ((target & 0x88) == 0 && (pieces[target] == null || pieces[target]!.color != color)) {
      moves.add(target);
    }
  }
  return moves;
}


List<int> _generateSlidingMoves(int index, Color color, List<int> directions) {
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
