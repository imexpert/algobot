import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AlgoBot'**
  String get appTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get soundOff;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parent;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Character gallery'**
  String get gallery;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Yaş aralığının uzun adı
  ///
  /// In en, this message translates to:
  /// **'{age, select, ages5to7{Ages 5–7} ages8to12{Ages 8–12} other{Ages 13+}}'**
  String ageRange(String age);

  /// Yaş aralığının kısa adı
  ///
  /// In en, this message translates to:
  /// **'{age, select, ages5to7{5–7} ages8to12{8–12} other{13+}}'**
  String ageShort(String age);

  /// No description provided for @worldTitle.
  ///
  /// In en, this message translates to:
  /// **'World 1 · Factory · {ageRange}'**
  String worldTitle(String ageRange);

  /// No description provided for @totalStars.
  ///
  /// In en, this message translates to:
  /// **'Your stars: {earned} / {total}'**
  String totalStars(int earned, int total);

  /// No description provided for @nextWorldTeaser.
  ///
  /// In en, this message translates to:
  /// **'World 2 coming soon: Loops!'**
  String get nextWorldTeaser;

  /// No description provided for @levelCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {id}, {title}, {stars, plural, =0{no stars} =1{1 star} other{{stars} stars}}'**
  String levelCardLabel(int id, String title, int stars);

  /// No description provided for @levelCardLockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {id}, {title}, locked'**
  String levelCardLockedLabel(int id, String title);

  /// No description provided for @levelCardSkippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {id}, {title}, skipped'**
  String levelCardSkippedLabel(int id, String title);

  /// No description provided for @levelCardNoLivesLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {id}, {title}, no lives. Next life: {time}'**
  String levelCardNoLivesLabel(int id, String title, String time);

  /// No description provided for @levelHeader.
  ///
  /// In en, this message translates to:
  /// **'World 1 · Level {id}'**
  String levelHeader(int id);

  /// No description provided for @program.
  ///
  /// In en, this message translates to:
  /// **'Your program'**
  String get program;

  /// Komut paletinin ekran okuyucu etiketi (görünmez)
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get paletteSemanticsLabel;

  /// No description provided for @slotCounter.
  ///
  /// In en, this message translates to:
  /// **'{used} / {max}'**
  String slotCounter(int used, int max);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @emptyProgram.
  ///
  /// In en, this message translates to:
  /// **'Add a command first'**
  String get emptyProgram;

  /// No description provided for @stripFull.
  ///
  /// In en, this message translates to:
  /// **'No more room'**
  String get stripFull;

  /// No description provided for @stepInfo.
  ///
  /// In en, this message translates to:
  /// **'Step {step} / {total} · {command}'**
  String stepInfo(int step, int total, String command);

  /// No description provided for @crashMessage.
  ///
  /// In en, this message translates to:
  /// **'Bump! You hit a wall. Fix your program and try again.'**
  String get crashMessage;

  /// No description provided for @stoppedShortMessage.
  ///
  /// In en, this message translates to:
  /// **'The program ended, but you didn\'t reach the goal.'**
  String get stoppedShortMessage;

  /// No description provided for @tapToClose.
  ///
  /// In en, this message translates to:
  /// **'Tap to close'**
  String get tapToClose;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Game board'**
  String get board;

  /// No description provided for @cmdForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get cmdForward;

  /// No description provided for @cmdRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get cmdRight;

  /// No description provided for @cmdLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get cmdLeft;

  /// No description provided for @cmdTurnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn right'**
  String get cmdTurnRight;

  /// No description provided for @cmdTurnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn left'**
  String get cmdTurnLeft;

  /// No description provided for @cmdUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get cmdUp;

  /// No description provided for @cmdDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get cmdDown;

  /// No description provided for @cmdMoveLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get cmdMoveLeft;

  /// No description provided for @cmdMoveRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get cmdMoveRight;

  /// No description provided for @paletteCardLabel.
  ///
  /// In en, this message translates to:
  /// **'{command} card'**
  String paletteCardLabel(String command);

  /// No description provided for @stripCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove from program: {command}'**
  String stripCardLabel(String command);

  /// No description provided for @emptySlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Empty slot {n}'**
  String emptySlotLabel(int n);

  /// No description provided for @livesLabel.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No lives left} =1{1 life left} other{{n} lives left}}'**
  String livesLabel(int n);

  /// No description provided for @lastLife.
  ///
  /// In en, this message translates to:
  /// **'Last life!'**
  String get lastLife;

  /// No description provided for @outOfLivesTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of lives'**
  String get outOfLivesTitle;

  /// No description provided for @outOfLivesBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s okay! Take a break and try again.'**
  String get outOfLivesBody;

  /// No description provided for @nextLife.
  ///
  /// In en, this message translates to:
  /// **'Next life: {time}'**
  String nextLife(String time);

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenu;

  /// No description provided for @useLifeJoker.
  ///
  /// In en, this message translates to:
  /// **'Use Extra Life (+1)'**
  String get useLifeJoker;

  /// No description provided for @skipLevelAction.
  ///
  /// In en, this message translates to:
  /// **'Skip this level'**
  String get skipLevelAction;

  /// No description provided for @watchVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Watch a video to skip'**
  String get watchVideoAction;

  /// No description provided for @jokerSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get jokerSkip;

  /// No description provided for @jokerLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get jokerLife;

  /// No description provided for @jokerVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get jokerVideo;

  /// No description provided for @jokerUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, used'**
  String jokerUsedLabel(String name);

  /// No description provided for @skipConfirm.
  ///
  /// In en, this message translates to:
  /// **'Skip this level? You won\'t earn stars for a skipped level.'**
  String get skipConfirm;

  /// No description provided for @skipConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipConfirmYes;

  /// No description provided for @skippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skippedLabel;

  /// No description provided for @videoFailed.
  ///
  /// In en, this message translates to:
  /// **'The video couldn\'t load right now.'**
  String get videoFailed;

  /// No description provided for @videoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Video will play here'**
  String get videoPlaceholder;

  /// No description provided for @resultOneStar.
  ///
  /// In en, this message translates to:
  /// **'You did it!'**
  String get resultOneStar;

  /// No description provided for @resultTwoStars.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get resultTwoStars;

  /// No description provided for @resultThreeStars.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get resultThreeStars;

  /// No description provided for @resultCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands used: {used} · Shortest: {optimal}'**
  String resultCommands(int used, int optimal);

  /// Toplanan nesne sayısı, karakterin toplanabilir adıyla
  ///
  /// In en, this message translates to:
  /// **'{character, select, bip{Batteries} pati{Fish} vizviz{Honey drops} buzi{Ice crystals} tosbi{Strawberries} hop{Carrots} zorp{Stars} kivilcim{Coins} other{?}}: {got} / {total}'**
  String collectedCount(String character, int got, int total);

  /// No description provided for @hintCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect all the {character, select, bip{batteries} pati{fish} vizviz{honey drops} buzi{ice crystals} tosbi{strawberries} hop{carrots} zorp{stars} kivilcim{coins} other{?}} to earn the 2nd star.'**
  String hintCollect(String character);

  /// No description provided for @hintShorter.
  ///
  /// In en, this message translates to:
  /// **'Can you do it in {optimal} commands?'**
  String hintShorter(int optimal);

  /// No description provided for @again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get again;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @starsLabel.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, =1{1 star out of 3} other{{stars} stars out of 3}}'**
  String starsLabel(int stars);

  /// Karakter adı (kimliğe göre)
  ///
  /// In en, this message translates to:
  /// **'{id, select, bip{Bip} pati{Whiskers} vizviz{Buzzy} buzi{Pingo} tosbi{Shelly} hop{Hop} zorp{Zorp} kivilcim{Sparky} other{?}}'**
  String characterName(String id);

  /// No description provided for @collectibleOf.
  ///
  /// In en, this message translates to:
  /// **'Collects: {id, select, bip{battery} pati{fish} vizviz{honey drop} buzi{ice crystal} tosbi{strawberry} hop{carrot} zorp{star} kivilcim{coin} other{?}}'**
  String collectibleOf(String id);

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get select;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Chosen'**
  String get selectedLabel;

  /// No description provided for @unlockAt.
  ///
  /// In en, this message translates to:
  /// **'Unlocks at {stars} stars'**
  String unlockAt(int stars);

  /// No description provided for @unlockProgress.
  ///
  /// In en, this message translates to:
  /// **'{have} / {need}'**
  String unlockProgress(int have, int need);

  /// No description provided for @newFriend.
  ///
  /// In en, this message translates to:
  /// **'New friend: {name}!'**
  String newFriend(String name);

  /// No description provided for @tryNow.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get tryNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @characterCardLocked.
  ///
  /// In en, this message translates to:
  /// **'{name}, locked'**
  String characterCardLocked(String name);

  /// No description provided for @characterCardSelected.
  ///
  /// In en, this message translates to:
  /// **'{name}, chosen'**
  String characterCardSelected(String name);

  /// No description provided for @welcomeAge.
  ///
  /// In en, this message translates to:
  /// **'Hi! How old are you?'**
  String get welcomeAge;

  /// No description provided for @pickFriend.
  ///
  /// In en, this message translates to:
  /// **'Pick a friend!'**
  String get pickFriend;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @parentGateTitle.
  ///
  /// In en, this message translates to:
  /// **'For parents'**
  String get parentGateTitle;

  /// No description provided for @parentQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is {a} + {b}?'**
  String parentQuestion(int a, int b);

  /// No description provided for @wrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Try again.'**
  String get wrongAnswer;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @ageRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get ageRangeTitle;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All stars will be erased and levels will lock again.'**
  String get resetConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Progress reset.'**
  String get resetDone;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'AlgoBot is a puzzle game that teaches kids to think like programmers. No data collected. No internet needed. Characters unlock only by playing; there are no purchases.'**
  String get about;

  /// No description provided for @level57n01Title.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get level57n01Title;

  /// No description provided for @level57n01Intro.
  ///
  /// In en, this message translates to:
  /// **'Tap the arrow card, then press the green button!'**
  String get level57n01Intro;

  /// No description provided for @level57n02Title.
  ///
  /// In en, this message translates to:
  /// **'Going Down'**
  String get level57n02Title;

  /// No description provided for @level57n02Intro.
  ///
  /// In en, this message translates to:
  /// **'This time you need to go down.'**
  String get level57n02Intro;

  /// No description provided for @level57n03Title.
  ///
  /// In en, this message translates to:
  /// **'The Corner'**
  String get level57n03Title;

  /// No description provided for @level57n03Intro.
  ///
  /// In en, this message translates to:
  /// **'First right, then down!'**
  String get level57n03Intro;

  /// No description provided for @level57n04Title.
  ///
  /// In en, this message translates to:
  /// **'Climb Up'**
  String get level57n04Title;

  /// No description provided for @level57n04Intro.
  ///
  /// In en, this message translates to:
  /// **'Go around the wall.'**
  String get level57n04Intro;

  /// No description provided for @level57n05Title.
  ///
  /// In en, this message translates to:
  /// **'Treasure'**
  String get level57n05Title;

  /// No description provided for @level57n05Intro.
  ///
  /// In en, this message translates to:
  /// **'Can you grab the treasure too?'**
  String get level57n05Intro;

  /// No description provided for @level57n06Title.
  ///
  /// In en, this message translates to:
  /// **'Snake Path'**
  String get level57n06Title;

  /// No description provided for @level57n06Intro.
  ///
  /// In en, this message translates to:
  /// **'Trace the path with your finger.'**
  String get level57n06Intro;

  /// No description provided for @level57n07Title.
  ///
  /// In en, this message translates to:
  /// **'Two Treasures'**
  String get level57n07Title;

  /// No description provided for @level57n07Intro.
  ///
  /// In en, this message translates to:
  /// **'Go to the goal last!'**
  String get level57n07Intro;

  /// No description provided for @level57n08Title.
  ///
  /// In en, this message translates to:
  /// **'Big Factory'**
  String get level57n08Title;

  /// No description provided for @level57n08Intro.
  ///
  /// In en, this message translates to:
  /// **'The treasure is a bit far. Get it first, then come back.'**
  String get level57n08Intro;

  /// No description provided for @level812n01Title.
  ///
  /// In en, this message translates to:
  /// **'First Step'**
  String get level812n01Title;

  /// No description provided for @level812n01Intro.
  ///
  /// In en, this message translates to:
  /// **'Drag the Forward card into the strip below, then press Run.'**
  String get level812n01Intro;

  /// No description provided for @level812n02Title.
  ///
  /// In en, this message translates to:
  /// **'Right Turn'**
  String get level812n02Title;

  /// No description provided for @level812n02Intro.
  ///
  /// In en, this message translates to:
  /// **'A turn card spins you in place. It doesn\'t move you forward.'**
  String get level812n02Intro;

  /// No description provided for @level812n03Title.
  ///
  /// In en, this message translates to:
  /// **'Left Turn'**
  String get level812n03Title;

  /// No description provided for @level812n03Intro.
  ///
  /// In en, this message translates to:
  /// **'Right and left depend on which way you are facing.'**
  String get level812n03Intro;

  /// No description provided for @level812n04Title.
  ///
  /// In en, this message translates to:
  /// **'Zigzag'**
  String get level812n04Title;

  /// No description provided for @level812n04Intro.
  ///
  /// In en, this message translates to:
  /// **'Trace the path with your finger first.'**
  String get level812n04Intro;

  /// No description provided for @level812n05Title.
  ///
  /// In en, this message translates to:
  /// **'Treasure or Shortcut?'**
  String get level812n05Title;

  /// No description provided for @level812n05Intro.
  ///
  /// In en, this message translates to:
  /// **'There\'s more than one way to the goal. Can you collect everything, too?'**
  String get level812n05Intro;

  /// No description provided for @level812n06Title.
  ///
  /// In en, this message translates to:
  /// **'Wrong Way'**
  String get level812n06Title;

  /// No description provided for @level812n06Intro.
  ///
  /// In en, this message translates to:
  /// **'Which way are you facing? Turn around first.'**
  String get level812n06Intro;

  /// No description provided for @level812n07Title.
  ///
  /// In en, this message translates to:
  /// **'Limited Cards'**
  String get level812n07Title;

  /// No description provided for @level812n07Intro.
  ///
  /// In en, this message translates to:
  /// **'You only have room for 10 cards. Make every card count.'**
  String get level812n07Intro;

  /// No description provided for @level812n08Title.
  ///
  /// In en, this message translates to:
  /// **'Factory Exit'**
  String get level812n08Title;

  /// No description provided for @level812n08Intro.
  ///
  /// In en, this message translates to:
  /// **'A long way! Did you notice you keep repeating the same moves?'**
  String get level812n08Intro;

  /// No description provided for @level13n01Title.
  ///
  /// In en, this message translates to:
  /// **'The Big Maze'**
  String get level13n01Title;

  /// No description provided for @level13n01Intro.
  ///
  /// In en, this message translates to:
  /// **'The map got bigger. Watch out for dead ends!'**
  String get level13n01Intro;

  /// No description provided for @level13n02Title.
  ///
  /// In en, this message translates to:
  /// **'Fork in the Road'**
  String get level13n02Title;

  /// No description provided for @level13n02Intro.
  ///
  /// In en, this message translates to:
  /// **'Grabbing the closest one first isn\'t always the shortest way.'**
  String get level13n02Intro;

  /// No description provided for @level13n03Title.
  ///
  /// In en, this message translates to:
  /// **'Locked Door'**
  String get level13n03Title;

  /// No description provided for @level13n03Intro.
  ///
  /// In en, this message translates to:
  /// **'Doors won\'t open without a key. Where is it?'**
  String get level13n03Intro;

  /// No description provided for @level13n04Title.
  ///
  /// In en, this message translates to:
  /// **'Key Hunt'**
  String get level13n04Title;

  /// No description provided for @level13n04Intro.
  ///
  /// In en, this message translates to:
  /// **'Sometimes you have to turn back. Find the key first.'**
  String get level13n04Intro;

  /// No description provided for @level13n05Title.
  ///
  /// In en, this message translates to:
  /// **'Slippery Floor'**
  String get level13n05Title;

  /// No description provided for @level13n05Intro.
  ///
  /// In en, this message translates to:
  /// **'It\'s hard to stop on ice: you slide until something blocks you.'**
  String get level13n05Intro;

  /// No description provided for @level13n06Title.
  ///
  /// In en, this message translates to:
  /// **'Ice Skating'**
  String get level13n06Title;

  /// No description provided for @level13n06Intro.
  ///
  /// In en, this message translates to:
  /// **'Ice is fast, but will it let you collect everything?'**
  String get level13n06Intro;

  /// No description provided for @level13n07Title.
  ///
  /// In en, this message translates to:
  /// **'Teleport!'**
  String get level13n07Title;

  /// No description provided for @level13n07Intro.
  ///
  /// In en, this message translates to:
  /// **'Step into a portal and you pop out of the other one, facing the same way.'**
  String get level13n07Intro;

  /// No description provided for @level13n08Title.
  ///
  /// In en, this message translates to:
  /// **'The Final'**
  String get level13n08Title;

  /// No description provided for @level13n08Intro.
  ///
  /// In en, this message translates to:
  /// **'Keys, ice and portals all at once. You have exactly enough cards!'**
  String get level13n08Intro;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
