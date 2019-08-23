import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GameMaster(),
    );
  }
}

class BoardSquare {
  bool hasBomb;
  int bombsAround;

  BoardSquare({this.hasBomb = false, this.bombsAround = 0});
}

class GameMaster extends StatefulWidget {
  @override
  GameMasterState createState() => GameMasterState();
}

class GameMasterState extends State<GameMaster> {
  List<List<BoardSquare>> board;
  List<bool> openedSquares;
  List<bool> flaggedSquares;
  int bombCount = 0;
  int squaresLeft = 0;

  final rowCount = 13;
  final columnCount = 9;
  final bombProbability = 3;
  final maxProbability = 15;

  GameMasterState() {
    initGame();
  }

  void initGame(){
    bombCount = 0;
    squaresLeft = 0;
    initBoard(rowCount, columnCount, bombProbability, maxProbability);
    initPlayState();
    print('init');
    printBoard();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
      ),
      itemBuilder: (context, index) {
        final row = (index / columnCount).floor();
        final column = (index % columnCount).floor();

        IconData image;

        if (openedSquares[index] == false) {
          if (flaggedSquares[index] == true)
            image = Icons.flag;
          else
            image = Icons.crop_square;
        } else {
          if (board[row][column].hasBomb)
            image = Icons.error;
          else
            image = getIconOfNumber(board[row][column].bombsAround);
        }

        return InkWell(
          onTap: () {
            // game over
            if (board[row][column].hasBomb) {
              setState(() {
                openedSquares[index] = true;
                squaresLeft--;
              });
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: Text('GameOver'),
                    actions: <Widget>[
                      FlatButton(
                          child: Text('Restart'),
                          onPressed: () {
                            setState(() {
                              initGame();
                            });

                            Navigator.pop(context);
                          })
                    ],
                  );
                },
              );
            }
            // game clear
            else if (checkWin()) {
              setState(() {
                for (int i = 0; i < openedSquares.length; i++)
                  openedSquares[i] = true;
//                openedSquares[index] = true;
                squaresLeft--;
              });
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: Text('GameClear'),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Restart'),
                        onPressed: () {
                          setState(() {
                            initGame();
                          });

                          Navigator.pop(context);
                        },
                      )
                    ],
                  );
                },
              );
            }

            // open
            else if (board[row][column].bombsAround == 0) {
              _handleTap(row, column);
            } else {
              setState(() {
                openedSquares[index] = true;
                squaresLeft--;
              });
            }
          },
          onLongPress: () {
            if (openedSquares[index] == false) {
              setState(() {
                flaggedSquares[index] = true;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange),
              color: Colors.grey,
            ),
//            color: Colors.grey,
            child: image != Icons.snooze
                ? Icon(image)
                : GridTile(
                    child: Container(),
                  ),
          ),
        );
      },
      itemCount: rowCount * columnCount,
    );
  }

  IconData getIconOfNumber(int num) {
    if (num == 1) return Icons.looks_one;
    if (num == 2) return Icons.looks_two;
    if (num == 3) return Icons.looks_3;
    if (num == 4) return Icons.looks_4;
    if (num == 5) return Icons.looks_5;
    if (num == 6) return Icons.looks_6;
    if (num == 7) return Icons.add;
    if (num == 8) return Icons.call_received;
    if (num == 9) return Icons.notification_important;
    return Icons.snooze;
  }

  void initBoard(
      int rowCount, int columnCount, int bombProbability, int maxProbability) {
//    List<List<BoardSquare>> board;

    squaresLeft = rowCount * columnCount;

    board = List.generate(
      rowCount,
      (r) => List.generate(
            columnCount,
            (c) => BoardSquare(hasBomb: false, bombsAround: 0),
          ),
    );

    Random random = new Random();

    // set bomb
    for (int r = 0; r < rowCount; r++) {
      for (int c = 0; c < columnCount; c++) {
        int randomNum = random.nextInt(maxProbability);
        if (randomNum < bombProbability) {
          board[r][c].hasBomb = true;

          bombCount++;
        }
      }
    }

    // calculate number of bombs around each square
    for (int r = 0; r < rowCount; r++) {
      for (int c = 0; c < columnCount; c++) {
        if (r > 0 && c > 0) {
          if (board[r - 1][c - 1].hasBomb) board[r][c].bombsAround++;
        }
        if (c > 0) {
          if (board[r][c - 1].hasBomb) board[r][c].bombsAround++;
        }
        if (r < rowCount - 1 && c > 0) {
          if (board[r + 1][c - 1].hasBomb) board[r][c].bombsAround++;
        }

        if (r > 0) {
          if (board[r - 1][c].hasBomb) board[r][c].bombsAround++;
        }
        if (r < rowCount - 1) {
          if (board[r + 1][c].hasBomb) board[r][c].bombsAround++;
        }

        if (r > 0 && c < columnCount - 1) {
          if (board[r - 1][c + 1].hasBomb) board[r][c].bombsAround++;
        }
        if (c < columnCount - 1) {
          if (board[r][c + 1].hasBomb) board[r][c].bombsAround++;
        }
        if (r < rowCount - 1 && c < columnCount - 1) {
          if (board[r + 1][c + 1].hasBomb) board[r][c].bombsAround++;
        }
      }
    }
  }

  void initPlayState() {
    openedSquares = List.generate(rowCount * columnCount, (i) => false);
    flaggedSquares = List.generate(rowCount * columnCount, (i) => false);
  }

  void _handleTap(int i, int j) {
    int position = (i * columnCount) + j;
    openedSquares[position] = true;
    squaresLeft--;

    if (i > 0) {
      if (!board[i - 1][j].hasBomb &&
          openedSquares[((i - 1) * columnCount) + j] != true) {
        if (board[i][j].bombsAround == 0) {
          _handleTap(i - 1, j);
        }
      }
    }

    if (j > 0) {
      if (!board[i][j - 1].hasBomb &&
          openedSquares[(i * columnCount) + j - 1] != true) {
        if (board[i][j].bombsAround == 0) {
          _handleTap(i, j - 1);
        }
      }
    }

    if (j < columnCount - 1) {
      if (!board[i][j + 1].hasBomb &&
          openedSquares[(i * columnCount) + j + 1] != true) {
        if (board[i][j].bombsAround == 0) {
          _handleTap(i, j + 1);
        }
      }
    }

    if (i < rowCount - 1) {
      if (!board[i + 1][j].hasBomb &&
          openedSquares[((i + 1) * columnCount) + j] != true) {
        if (board[i][j].bombsAround == 0) {
          _handleTap(i + 1, j);
        }
      }
    }

    setState(() {});
  }

  bool checkWin() {
    if (flaggedSquares.where((v) => v == true).toList().length == bombCount)
      return true;
    print(flaggedSquares);
    print(bombCount);
    print(flaggedSquares.where((v) => v == true).toList().length);
//    if (squaresLeft <= bombCount) return true;
    return false;
  }

  void printBoard() {
    for (int r = 0; r < rowCount; r++) {
      for (int c = 0; c < columnCount; c++) {
        print('($r, $c)' +
            (board[r][c].hasBomb ? '1' : '0') +
            '${board[r][c].bombsAround}');
      }
//      print('\n');
    }
  }
}
