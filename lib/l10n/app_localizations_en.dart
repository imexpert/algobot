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
  String worldTitle(String ageRange) {
    return 'World 1 · Factory · $ageRange';
  }

  @override
  String totalStars(int earned, int total) {
    return 'Your stars: $earned / $total';
  }

  @override
  String get nextWorldTeaser => 'World 2 coming soon: Loops!';

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
  String levelHeader(int id) {
    return 'World 1 · Level $id';
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
      'AlgoBot is a puzzle game that teaches kids to think like programmers. No data collected. No internet needed. Characters unlock only by playing; there are no purchases.';

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
}
