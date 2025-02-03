import 'move.dart';

List<Move> sortedMoves(Map<String, Move> moveMap) {
  List<Move> moves = moveMap.values.toList();

  // Sort in descending order based on move.score (higher score = better move)
  moves.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

  return moves;
}

void main() {
  Map<String, Move> moveMap = {
    "e2e4": Move(0x12, 0x32)..score = 100,
    "d2d4": Move(0x13, 0x33)..score = 200,
    "g1f3": Move(0x06, 0x25)..score = 150,
  };

  List<Move> orderedMoves = sortedMoves(moveMap);

  for (var move in orderedMoves) {
    print("${move} - Score: ${move.score}");
  }
}

String? bestMoveKey(Map<String, Move> moveMap) {
  if (moveMap.isEmpty) return null;

  return moveMap.entries
      .reduce((a, b) => (b.value.score ?? 0) > (a.value.score ?? 0) ? b : a)
      .key;
}
