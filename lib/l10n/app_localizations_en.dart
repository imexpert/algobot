// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AlgoBot';

  @override
  String get play => 'Play';

  @override
  String get soundOn => 'Sound on';

  @override
  String get soundOff => 'Sound off';

  @override
  String get parent => 'Parents';

  @override
  String get characters => 'Characters';

  @override
  String get gallery => 'Character gallery';

  @override
  String get back => 'Back';

  @override
  String ageRange(String age) {
    String _temp0 = intl.Intl.selectLogic(age, {
      'ages5to7': 'Ages 5–7',
      'ages8to12': 'Ages 8–12',
      'other': 'Ages 13+',
    });
    return '$_temp0';
  }

  @override
  String ageShort(String age) {
    String _temp0 = intl.Intl.selectLogic(age, {
      'ages5to7': '5–7',
      'ages8to12': '8–12',
      'other': '13+',
    });
    return '$_temp0';
  }

  @override
  String totalStars(int earned, int total) {
    return 'Your stars: $earned / $total';
  }

  @override
  String get nextWorldTeaser => 'More worlds coming soon!';

  @override
  String levelCardLabel(int id, String title, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stars',
      one: '1 star',
      zero: 'no stars',
    );
    return 'Level $id, $title, $_temp0';
  }

  @override
  String levelCardLockedLabel(int id, String title) {
    return 'Level $id, $title, locked';
  }

  @override
  String levelCardSkippedLabel(int id, String title) {
    return 'Level $id, $title, skipped';
  }

  @override
  String levelCardNoLivesLabel(int id, String title, String time) {
    return 'Level $id, $title, no lives. Next life: $time';
  }

  @override
  String levelHeader(int world, int number) {
    return 'World $world · Level $number';
  }

  @override
  String get program => 'Your program';

  @override
  String get paletteSemanticsLabel => 'Commands';

  @override
  String slotCounter(int used, int max) {
    return '$used / $max';
  }

  @override
  String get clear => 'Clear';

  @override
  String get run => 'Run';

  @override
  String get stop => 'Stop';

  @override
  String get fast => 'Fast';

  @override
  String get tryAgain => 'Try again';

  @override
  String get emptyProgram => 'Add a command first';

  @override
  String get stripFull => 'No more room';

  @override
  String stepInfo(int step, int total, String command) {
    return 'Step $step / $total · $command';
  }

  @override
  String get crashMessage =>
      'Bump! You hit a wall. Fix your program and try again.';

  @override
  String get stoppedShortMessage =>
      'The program ended, but you didn\'t reach the goal.';

  @override
  String get tapToClose => 'Tap to close';

  @override
  String get board => 'Game board';

  @override
  String get cmdForward => 'Forward';

  @override
  String get cmdRight => 'Right';

  @override
  String get cmdLeft => 'Left';

  @override
  String get cmdTurnRight => 'Turn right';

  @override
  String get cmdTurnLeft => 'Turn left';

  @override
  String get cmdUp => 'Up';

  @override
  String get cmdDown => 'Down';

  @override
  String get cmdMoveLeft => 'Left';

  @override
  String get cmdMoveRight => 'Right';

  @override
  String get cardHelpForward => 'Move 1 square the way you\'re facing';

  @override
  String get cardHelpTurnRight => 'Turn right on the spot';

  @override
  String get cardHelpTurnLeft => 'Turn left on the spot';

  @override
  String get cardHelpUp => 'Move 1 square up';

  @override
  String get cardHelpDown => 'Move 1 square down';

  @override
  String get cardHelpMoveLeft => 'Move 1 square left';

  @override
  String get cardHelpMoveRight => 'Move 1 square right';

  @override
  String paletteCardLabel(String command) {
    return '$command card';
  }

  @override
  String stripCardLabel(String command) {
    return 'Remove from program: $command';
  }

  @override
  String emptySlotLabel(int n) {
    return 'Empty slot $n';
  }

  @override
  String livesLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lives left',
      one: '1 life left',
      zero: 'No lives left',
    );
    return '$_temp0';
  }

  @override
  String get lastLife => 'Last life!';

  @override
  String get outOfLivesTitle => 'Out of lives';

  @override
  String get outOfLivesBody => 'That\'s okay! Take a break and try again.';

  @override
  String nextLife(String time) {
    return 'Next life: $time';
  }

  @override
  String get mainMenu => 'Main menu';

  @override
  String get useLifeJoker => 'Use Extra Life (+1)';

  @override
  String get skipLevelAction => 'Skip this level';

  @override
  String get watchVideoAction => 'Watch a video to skip';

  @override
  String get jokerSkip => 'Skip';

  @override
  String get jokerLife => 'Life';

  @override
  String get jokerVideo => 'Video';

  @override
  String jokerUsedLabel(String name) {
    return '$name, used';
  }

  @override
  String get skipConfirm =>
      'Skip this level? You won\'t earn stars for a skipped level.';

  @override
  String get skipConfirmYes => 'Skip';

  @override
  String get skippedLabel => 'Skipped';

  @override
  String get videoFailed => 'The video couldn\'t load right now.';

  @override
  String get videoPlaceholder => 'Video will play here';

  @override
  String get resultOneStar => 'You did it!';

  @override
  String get resultTwoStars => 'Great job!';

  @override
  String get resultThreeStars => 'Perfect!';

  @override
  String resultCommands(int used, int optimal) {
    return 'Commands used: $used · Shortest: $optimal';
  }

  @override
  String collectedCount(String character, int got, int total) {
    String _temp0 = intl.Intl.selectLogic(character, {
      'bip': 'Batteries',
      'pati': 'Fish',
      'vizviz': 'Honey drops',
      'buzi': 'Ice crystals',
      'tosbi': 'Strawberries',
      'hop': 'Carrots',
      'zorp': 'Stars',
      'kivilcim': 'Coins',
      'other': '?',
    });
    return '$_temp0: $got / $total';
  }

  @override
  String hintCollect(String character) {
    String _temp0 = intl.Intl.selectLogic(character, {
      'bip': 'batteries',
      'pati': 'fish',
      'vizviz': 'honey drops',
      'buzi': 'ice crystals',
      'tosbi': 'strawberries',
      'hop': 'carrots',
      'zorp': 'stars',
      'kivilcim': 'coins',
      'other': '?',
    });
    return 'Collect all the $_temp0 to earn the 2nd star.';
  }

  @override
  String hintShorter(int optimal) {
    return 'Can you do it in $optimal commands?';
  }

  @override
  String get again => 'Retry';

  @override
  String get next => 'Next';

  @override
  String starsLabel(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stars out of 3',
      one: '1 star out of 3',
    );
    return '$_temp0';
  }

  @override
  String characterName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bip': 'Bip',
      'pati': 'Whiskers',
      'vizviz': 'Buzzy',
      'buzi': 'Pingo',
      'tosbi': 'Shelly',
      'hop': 'Hop',
      'zorp': 'Zorp',
      'kivilcim': 'Sparky',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String collectibleOf(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bip': 'battery',
      'pati': 'fish',
      'vizviz': 'honey drop',
      'buzi': 'ice crystal',
      'tosbi': 'strawberry',
      'hop': 'carrot',
      'zorp': 'star',
      'kivilcim': 'coin',
      'other': '?',
    });
    return 'Collects: $_temp0';
  }

  @override
  String get select => 'Choose';

  @override
  String get selectedLabel => 'Chosen';

  @override
  String unlockAt(int stars) {
    return 'Unlocks at $stars stars';
  }

  @override
  String unlockProgress(int have, int need) {
    return '$have / $need';
  }

  @override
  String newFriend(String name) {
    return 'New friend: $name!';
  }

  @override
  String get tryNow => 'Try now';

  @override
  String get later => 'Later';

  @override
  String characterCardLocked(String name) {
    return '$name, locked';
  }

  @override
  String characterCardSelected(String name) {
    return '$name, chosen';
  }

  @override
  String get welcomeAge => 'Hi! How old are you?';

  @override
  String get pickFriend => 'Pick a friend!';

  @override
  String get start => 'Start';

  @override
  String get parentGateTitle => 'For parents';

  @override
  String parentQuestion(int a, int b) {
    return 'What is $a + $b?';
  }

  @override
  String get wrongAnswer => 'Not quite. Try again.';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get settings => 'Settings';

  @override
  String get sound => 'Sound';

  @override
  String get ageRangeTitle => 'Age range';

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetConfirmTitle => 'Are you sure?';

  @override
  String get resetConfirmBody =>
      'All stars will be erased and levels will lock again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get resetDone => 'Progress reset.';

  @override
  String get about =>
      'AlgoBot is a puzzle game that teaches kids to think like programmers. No data collected. No internet needed to play. Characters unlock only by playing; there are no purchases.';

  @override
  String get rateApp => 'Rate the app';

  @override
  String get reviewPromptTitle => 'You are doing great! 💛';

  @override
  String get reviewPromptBody =>
      'Enjoying AlgoBot? Show this to a grown-up. They can rate the app in the store.';

  @override
  String get reviewPromptParent => 'Grown-up';

  @override
  String get level57n01Title => 'Hello!';

  @override
  String get level57n01Intro =>
      'Tap the arrow card, then press the green button!';

  @override
  String get level57n02Title => 'Going Down';

  @override
  String get level57n02Intro => 'This time you need to go down.';

  @override
  String get level57n03Title => 'The Corner';

  @override
  String get level57n03Intro => 'First right, then down!';

  @override
  String get level57n04Title => 'Climb Up';

  @override
  String get level57n04Intro => 'Go around the wall.';

  @override
  String get level57n05Title => 'Treasure';

  @override
  String get level57n05Intro => 'Can you grab the treasure too?';

  @override
  String get level57n06Title => 'Snake Path';

  @override
  String get level57n06Intro => 'Trace the path with your finger.';

  @override
  String get level57n07Title => 'Two Treasures';

  @override
  String get level57n07Intro => 'Go to the goal last!';

  @override
  String get level57n08Title => 'Big Factory';

  @override
  String get level57n08Intro =>
      'The treasure is a bit far. Get it first, then come back.';

  @override
  String get level812n01Title => 'First Step';

  @override
  String get level812n01Intro =>
      'Drag the Forward card into the strip below, then press Run.';

  @override
  String get level812n02Title => 'Right Turn';

  @override
  String get level812n02Intro =>
      'A turn card spins you in place. It doesn\'t move you forward.';

  @override
  String get level812n03Title => 'Left Turn';

  @override
  String get level812n03Intro =>
      'Right and left depend on which way you are facing.';

  @override
  String get level812n04Title => 'Zigzag';

  @override
  String get level812n04Intro => 'Trace the path with your finger first.';

  @override
  String get level812n05Title => 'Treasure or Shortcut?';

  @override
  String get level812n05Intro =>
      'There\'s more than one way to the goal. Can you collect everything, too?';

  @override
  String get level812n06Title => 'Wrong Way';

  @override
  String get level812n06Intro => 'Which way are you facing? Turn around first.';

  @override
  String get level812n07Title => 'Limited Cards';

  @override
  String get level812n07Intro =>
      'You only have room for 10 cards. Make every card count.';

  @override
  String get level812n08Title => 'Factory Exit';

  @override
  String get level812n08Intro =>
      'A long way! Did you notice you keep repeating the same moves?';

  @override
  String get level13n01Title => 'The Big Maze';

  @override
  String get level13n01Intro => 'The map got bigger. Watch out for dead ends!';

  @override
  String get level13n02Title => 'Fork in the Road';

  @override
  String get level13n02Intro =>
      'Grabbing the closest one first isn\'t always the shortest way.';

  @override
  String get level13n03Title => 'Locked Door';

  @override
  String get level13n03Intro => 'Doors won\'t open without a key. Where is it?';

  @override
  String get level13n04Title => 'Key Hunt';

  @override
  String get level13n04Intro =>
      'Sometimes you have to turn back. Find the key first.';

  @override
  String get level13n05Title => 'Slippery Floor';

  @override
  String get level13n05Intro =>
      'It\'s hard to stop on ice: you slide until something blocks you.';

  @override
  String get level13n06Title => 'Ice Skating';

  @override
  String get level13n06Intro =>
      'Ice is fast, but will it let you collect everything?';

  @override
  String get level13n07Title => 'Teleport!';

  @override
  String get level13n07Intro =>
      'Step into a portal and you pop out of the other one, facing the same way.';

  @override
  String get level13n08Title => 'The Final';

  @override
  String get level13n08Intro =>
      'Keys, ice and portals all at once. You have exactly enough cards!';

  @override
  String get level57w2n01Title => 'Long Road';

  @override
  String get level57w2n01Intro =>
      'Don\'t add the same arrow again and again: make it ×5 with Repeat!';

  @override
  String get level57w2n02Title => 'Deep Well';

  @override
  String get level57w2n02Intro => 'The down arrow, but how many times?';

  @override
  String get level57w2n03Title => 'Long Corner';

  @override
  String get level57w2n03Intro => 'Right, then down. Repeat them both!';

  @override
  String get level57w2n04Title => 'Hidden Treasure';

  @override
  String get level57w2n04Intro => 'The treasure is off the path. Get it first.';

  @override
  String get level57w2n05Title => 'Zigzag';

  @override
  String get level57w2n05Intro => 'Two steps on every stair.';

  @override
  String get level57w2n06Title => 'Big Square';

  @override
  String get level57w2n06Intro => 'Two treasures in two different corners.';

  @override
  String get level57w2n07Title => 'The Snake';

  @override
  String get level57w2n07Intro => 'A long way, but a few cards are enough.';

  @override
  String get level57w2n08Title => 'Assembly Line';

  @override
  String get level57w2n08Intro => 'Collect the treasures, repeat the cards!';

  @override
  String get level812w2n01Title => 'First Loop';

  @override
  String get level812w2n01Intro =>
      'The Repeat card runs the cards inside it many times.';

  @override
  String get level812w2n02Title => 'Long Bend';

  @override
  String get level812w2n02Intro => 'Use a loop for each long straight.';

  @override
  String get level812w2n03Title => 'Staircase';

  @override
  String get level812w2n03Intro =>
      'Every step is the same moves. Write them once, repeat!';

  @override
  String get level812w2n04Title => 'Square Lap';

  @override
  String get level812w2n04Intro =>
      'The goal is right there, but the treasures are in the corners.';

  @override
  String get level812w2n05Title => 'Two Loops';

  @override
  String get level812w2n05Intro => 'A program can have more than one loop.';

  @override
  String get level812w2n06Title => 'Treasure Stairs';

  @override
  String get level812w2n06Intro =>
      'There\'s treasure on the steps; a loop collects it all.';

  @override
  String get level812w2n07Title => 'Grand Tour';

  @override
  String get level812w2n07Intro => 'Think first: which part repeats?';

  @override
  String get level812w2n08Title => 'End of the Line';

  @override
  String get level812w2n08Intro => 'Mix loops and single cards.';

  @override
  String get level13w2n01Title => 'Endless Stairs';

  @override
  String get level13w2n01Intro => 'Long stairs, short program.';

  @override
  String get level13w2n02Title => 'Portal Corridor';

  @override
  String get level13w2n02Intro => 'A loop keeps going even through a portal.';

  @override
  String get level13w2n03Title => 'Ice Stairs';

  @override
  String get level13w2n03Intro => 'Sliding on ice doesn\'t change the loop.';

  @override
  String get level13w2n04Title => 'Locked Square';

  @override
  String get level13w2n04Intro => 'The key is on a corner of the square.';

  @override
  String get level13w2n05Title => 'Key Stairs';

  @override
  String get level13w2n05Intro => 'Think of a separate loop for each part.';

  @override
  String get level13w2n06Title => 'Double Lap';

  @override
  String get level13w2n06Intro =>
      'The treasures are off the path; the shortest way won\'t do.';

  @override
  String get level13w2n07Title => 'The Comb';

  @override
  String get level13w2n07Intro =>
      'A treasure in every tooth. Find the repeating pattern.';

  @override
  String get level13w2n08Title => 'Grand Finale';

  @override
  String get level13w2n08Intro =>
      'Ice, portals, keys and loops. You have exactly enough cards!';

  @override
  String levelSelectTitle(String ageRange) {
    return 'Levels · $ageRange';
  }

  @override
  String worldSection(int world, String name) {
    return 'World $world · $name';
  }

  @override
  String get world1Name => 'Factory';

  @override
  String get world2Name => 'Assembly Line';

  @override
  String get cmdRepeat => 'Repeat';

  @override
  String get loopEndShort => 'End';

  @override
  String loopCardLabel(int count) {
    return 'Repeat $count times';
  }

  @override
  String get loopEndCardLabel => 'End of loop';

  @override
  String get loopEndOpenLabel =>
      'End of loop, new cards go inside. Tap to close.';

  @override
  String multiplierCardLabel(String command, int times) {
    return '$command ×$times. Tap to remove.';
  }

  @override
  String get loopCountTitle => 'How many times?';

  @override
  String get removeLoop => 'Remove loop';

  @override
  String stepInfoRound(
    int step,
    int total,
    String command,
    int round,
    int rounds,
  ) {
    return 'Step $step / $total · $command · round $round/$rounds';
  }

  @override
  String get noCardToRepeat => 'Add an arrow card first';

  @override
  String get maxRepeat => 'Up to ×5';

  @override
  String get howToPlay => 'How to play';

  @override
  String get tutTitle => 'Tutorial';

  @override
  String get tutSkip => 'Skip';

  @override
  String get tutSkipConfirm =>
      'Skip the tutorial? You can watch it again any time from the home screen.';

  @override
  String get tutHelpConfirm =>
      'Start the tutorial? Your program on this level won\'t be lost.';

  @override
  String get tutHelpStart => 'Start tutorial';

  @override
  String get tutHelpMechanic => 'This level\'s intro';

  @override
  String get tutNext => 'Next ›';

  @override
  String get tutStart => 'Start';

  @override
  String get tutGotIt => 'Got it';

  @override
  String get tutProgressLabel => 'Tutorial progress';

  @override
  String tutWrongCard(String card) {
    return 'This time, tap the $card card.';
  }

  @override
  String get tutTryAgain => 'Almost! Try again.';

  @override
  String get tutForgot => 'You reached the goal, but you forgot something!';

  @override
  String get tutRemoveWrong => 'Tap a wrong card to remove it.';

  @override
  String get tutRel01 =>
      'Hi! This is your character. Let\'s take it to the goal.';

  @override
  String get tutRel02 => 'This is the goal.';

  @override
  String get tutRel03 =>
      'The yellow arrow shows where your character is facing. Forward moves it to this square.';

  @override
  String get tutRel04 => 'Tap the Forward card.';

  @override
  String get tutRel05 =>
      'The card is in your program! Your character will do the cards in order.';

  @override
  String get tutRel06 => 'The goal is 2 squares away. Add one more Forward.';

  @override
  String get tutRel07 => 'Now tap Run and watch!';

  @override
  String get tutRel08 => 'Great! You wrote your first program.';

  @override
  String get tutRel09 =>
      'This time the goal is below. Your character is facing right.';

  @override
  String get tutRel10 => 'First, move one square forward.';

  @override
  String get tutRel11 =>
      'Now tap the Right card. It doesn\'t walk, it only turns your character on the spot.';

  @override
  String get tutRel12 =>
      'After the turn, the arrow will point down. Add one more Forward.';

  @override
  String get tutRel13 => 'Tap Run. Watch the arrow as it turns!';

  @override
  String get tutRel14 =>
      'Right and left depend on where your character is facing. If you\'re not sure, press and hold a card to see what it does.';

  @override
  String get tutRel15 =>
      'To remove a wrong card, tap it in your program. Try it now: remove a card.';

  @override
  String get tutRel16 => 'Your turn! Solve this path on your own.';

  @override
  String tutRel17(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bip': 'a battery',
      'pati': 'a fish',
      'vizviz': 'a honey drop',
      'buzi': 'an ice crystal',
      'tosbi': 'a strawberry',
      'hop': 'a carrot',
      'zorp': 'a star',
      'kivilcim': 'a coin',
      'other': 'a treasure',
    });
    return 'This is $_temp0. Collect it to earn more stars.';
  }

  @override
  String get tutRel18 =>
      '1 star: reach the goal. 2 stars: collect everything. 3 stars: use the fewest cards.';

  @override
  String get tutRel19 => 'Collect it and reach the goal!';

  @override
  String get tutRel20 =>
      'You have 3 lives. If your program misses the goal, you lose 1. Lives come back over time.';

  @override
  String get tutRel21 =>
      'Stuck? Jokers can help: skip the level or get a life.';

  @override
  String get tutRel21Video =>
      'Stuck? Jokers can help: skip the level, get a life or watch a video.';

  @override
  String get tutRel22 => 'You\'re ready! Let\'s go to the first level.';

  @override
  String get tutAbs01 => 'This is your friend!';

  @override
  String get tutAbs02 => 'Let\'s take it here.';

  @override
  String get tutAbs03 => 'Tap the right arrow.';

  @override
  String get tutAbs04 => 'One more time!';

  @override
  String get tutAbs05 => 'Press the green button!';

  @override
  String get tutAbs06 => 'Super!';

  @override
  String get tutAbs07 => 'Now right, then down.';

  @override
  String get tutAbs08 => 'To remove a wrong card, tap it.';

  @override
  String get tutAbs09 => 'Grab the treasure too!';

  @override
  String get tutAbs10 => 'You have 3 hearts. A mistake costs one heart.';

  @override
  String get tutAbs11 => 'You\'re ready!';

  @override
  String get tutMechIce => 'On ice, you slide until something stops you.';

  @override
  String get tutMechDoor => 'Pick up the key and the door opens.';

  @override
  String get tutMechPortal =>
      'Step into one portal and you come out of the other, facing the same way.';

  @override
  String get tutMechWatch => 'Watch! Tap Got it when you\'re ready.';
}
