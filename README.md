# How Long to Beat - Console Edition

This project submits a request to the www.howlongtobeat.com servers and returns
console-friendly output.

## Usage

### `hltb.rb`

This was the prototype to get the first returned game.

```
$ ./hltb.rb "witcher 3"
https://howlongtobeat.com/game.php?id=10270
The Witcher 3: Wild Hunt
main: 51 hours
plus_extras: 102 hours
completionist: 172 hours
```

### `hltb-direct.rb`

This is the refactored version to return multiple results for a single game. Note that quotes
around the game entry are not required.

```
$ ./hltb-direct.rb witcher 3
1: The Witcher 3 Wild Hunt
game?id=10270
Main: 51.5 hours
Extra: 102.0 hours
Complete: 172.0 hours

2: The Witcher 3 Wild Hunt  Game of the Year Edition
game?id=40171
Main: 54.5 hours
Extra: 127.0 hours
Complete: 190.0 hours
```

## Disclaimer

I am not affiliated with www.howlongtobeat.com in any way, shape, or form.
This is simply a script that utilizes the service and scrapes the results.
