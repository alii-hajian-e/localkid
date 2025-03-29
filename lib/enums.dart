const gameWidth = 820.0;
const gameHeight = 1600.0;
const ballRadius = gameWidth * 0.03;
const batWidth = gameWidth * 0.2;
const batHeight = ballRadius * 2;
const batStep = gameWidth * 0.05;
const brickGutter = gameWidth * 0.015;

enum PlayState { welcome, playing, gameOver, won }
enum Direction { down, left, right, up }
enum PlayerTurn { player1, player2 }
enum AIBehavior { aggressive, superAggressive, evasive }