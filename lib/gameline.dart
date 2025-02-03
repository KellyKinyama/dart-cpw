import 'package:dart_cpw/piece.dart';

import 'move.dart';

class GameLineRecord {
  Move move;
  int? enpassantSquare; // En-passant target square after double pawn move
  int? enpassantPieceSquare;
  int fiftyMove; // Moves since the last pawn move or capture
  //U64 key;					   // hash key of the position
  Piece? capturedPiece;
  bool whiteKingsideCastle = true;
  bool whiteQueensideCastle = true;
  bool blackKingsideCastle = true;
  bool blackQueensideCastle = true;

  late int whiteKingSquare;
  late int blackKingSquare;

  List<Piece?> pieces = List.filled(128, null);

  GameLineRecord(
      this.move,
      this.whiteKingsideCastle,
      this.whiteQueensideCastle,
      this.blackKingsideCastle,
      this.blackQueensideCastle,
      this.enpassantSquare,
      this.enpassantPieceSquare,
      this.fiftyMove);

  void fillPieces(List<Piece?> boardPieces) {
    for (int x = 0; x < 128; x++) {
      if (boardPieces[x] == null) {
        pieces[x] = null;
        continue;
      }

      pieces[x] = Piece(x, boardPieces[x]!.type, boardPieces[x]!.color);
    }
  }

  @override
  String toString() {
    return "Move: $move, En-passant target: $enpassantSquare";
  }
}
