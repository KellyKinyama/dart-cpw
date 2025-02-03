import 'piece.dart';

class Move {
  int from;
  int to;
  int? score;

  Piece? capturedPiece;
  int? capturedSquare;
  Move(this.from, this.to);

  @override
  String toString() {
    return "{from: 0x${from.toRadixString(16)}, to:  0x${to.toRadixString(16)}}";
  }
}
