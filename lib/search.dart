import 'dart:math';

import 'package:dart_cpw/board.dart';

import 'evaluation.dart';
import 'move.dart';
import 'sort.dart';

int makeMoves = 0;
int unMakeMoves = 0;

void prepareRootMoves(Board board) {
  final moves = board.generalPseudoMoves();
  board.rootMoves.clear();

  for (var move in moves) {
    String strFrom = board.algebraicFromSquare(move.from);

    String strTo = board.algebraicFromSquare(move.to);
    // print("board state:");
    // //board.printBoard();
    // print("bestmove $strFrom$strTo");
    board.rootMoves["$strFrom$strTo"] = move;
  }
}

String search(Board board, int depth, int ply) {
  prepareRootMoves(board);

  for (int iterativeDeepening = 1;
      iterativeDeepening < depth;
      iterativeDeepening++) {
    alphaBeta(board, -32670, 32670, iterativeDeepening, ply);
  }

  //alphaBeta(board, -32670, 32670, depth, ply);
  //print("Score: $val");
  // Random random = Random();
  // final moveInt = random.nextInt(moves.length - 1);
  // String strFrom = board.algebraicFromSquare(moves[moveInt].from);

  // String strTo = board.algebraicFromSquare(moves[moveInt].to);
  // print("board state:");
  // board.printBoard();
  //print("bestmove $strFrom$strTo");
  // return "$strFrom$strTo";

  // List<Move> orderedMoves = sortedMoves(board.rootMoves);
  //print("Root moves: ${board.rootMoves}");
  print("bestmove ${bestMoveKey(board.rootMoves)}");

  return bestMoveKey(board.rootMoves)!;
}

int alphaBeta(Board board, int alpha, int beta, int depth, int ply) {
  if (depth <= 0) return evaluate(board);

  final moves =
      ply == 0 ? sortedMoves(board.rootMoves) : board.generalPseudoMoves();
  //final moves = board.generalPseudoMoves();
  // if (ply == 0) {
  //   print("Possible moves: $moves");
  // }

  int movesFound = 0;
  int pvMoveFound = 0;
  bool? incheck;

  for (var move in moves) {
    makeMoves++;

    // if (move.to > 127) throw "Error move index: ${move.to} is not valid";
    if (move.to > 127) continue;

    board.makeMove(move.from, move.to);

    incheck = board.inCheck();
    if (!incheck) {
      // if (board.endOfSearch == 0) throw "EndofSearch cannot be == 0";
      //search(board, depth - 1, ply + 1);
      movesFound++;
      int val;

      if (pvMoveFound > 0) {
        final boardFrom = Board.fromBoard(board);

        zwSearch(boardFrom, -(alpha + 1), -alpha, depth - 1, ply + 1)
            .then((onValue) {
          val = -onValue;

          if (val > alpha && val < beta) {
            val = -alphaBeta(board, -beta, -alpha, depth - 1, ply + 1);
          }

          if (val >= beta) return beta;
          if (val > alpha) {
            pvMoveFound++;
            alpha = val;
            if (ply == 0) {
              move.score = val;
              String strFrom = board.algebraicFromSquare(move.from);

              String strTo = board.algebraicFromSquare(move.to);
              // print("board state:");
              // //board.printBoard();
              // print("bestmove $strFrom$strTo");
              board.rootMoves["$strFrom$strTo"] = move;
            }
          }
        });
      } else {
        val = -alphaBeta(board, -beta, -alpha, depth - 1, ply + 1);
        if (val >= beta) return beta;
        if (val > alpha) {
          pvMoveFound++;
          alpha = val;
          if (ply == 0) {
            move.score = val;
            String strFrom = board.algebraicFromSquare(move.from);

            String strTo = board.algebraicFromSquare(move.to);
            // print("board state:");
            // //board.printBoard();
            // print("bestmove $strFrom$strTo");
            board.rootMoves["$strFrom$strTo"] = move;
          }
        }
      }
    } else {
      //print("I am in check");
    }
    board.unmakeMove();
    unMakeMoves++;
  }

  if (movesFound == 0 && incheck == null) return 0;
  if (movesFound == 0 && incheck!) {
    //print("We are checkmated in ply: $ply");
    return -32600 + ply;
  }

  return alpha;
}

Future<int> zwSearch(
    Board board, int alpha, int beta, int depth, int ply) async {
  if (depth <= 0) return evaluate(board);

  final moves =
      ply == 0 ? sortedMoves(board.rootMoves) : board.generalPseudoMoves();
  //final moves = board.generalPseudoMoves();
  // if (ply == 0) {
  //   print("Possible moves: $moves");
  // }

  int movesFound = 0;
  int pvMoveFound = 0;
  bool? incheck;

  for (var move in moves) {
    makeMoves++;

    // if (move.to > 127) throw "Error move index: ${move.to} is not valid";
    if (move.to > 127) continue;

    board.makeMove(move.from, move.to);

    incheck = board.inCheck();
    if (!incheck) {
      // if (board.endOfSearch == 0) throw "EndofSearch cannot be == 0";
      //search(board, depth - 1, ply + 1);
      movesFound++;

      final val = await zwSearch(board, -beta, -alpha, depth - 1, ply + 1);
      if (val >= beta) return beta;
      if (val > alpha) {
        pvMoveFound++;
        alpha = val;
        if (ply == 0) {
          move.score = val;
          String strFrom = board.algebraicFromSquare(move.from);

          String strTo = board.algebraicFromSquare(move.to);
          // print("board state:");
          // //board.printBoard();
          // print("bestmove $strFrom$strTo");
          board.rootMoves["$strFrom$strTo"] = move;
        }
      } else {
        if (ply == 0) {
          move.score = val;
          String strFrom = board.algebraicFromSquare(move.from);

          String strTo = board.algebraicFromSquare(move.to);
          // print("board state:");
          // //board.printBoard();
          // print("bestmove $strFrom$strTo");
          board.rootMoves["$strFrom$strTo"] = move;
        }
      }
    } else {
      //print("I am in check");
    }
    board.unmakeMove();
    unMakeMoves++;
  }

  if (movesFound == 0 && incheck == null) return 0;
  if (movesFound == 0 && incheck!) {
    //print("We are checkmated in ply: $ply");
    return -32600 + ply;
  }

  return alpha;
}

int evaluate(Board board) {
  Board board = Board();
  final eval = Evaluation(board);
  final val = eval.evaluate();
  return val;
}
