import '../models/age_group.dart';
import '../models/cell.dart';
import '../models/command.dart';
import '../models/intro_glyph.dart';
import 'tutorial_step.dart';

const _f = Command.forward;
const _r = Command.turnRight;
const _l = Command.turnLeft;
const _right = Command.moveRight;
const _down = Command.moveDown;

/// Dönüşlerin eğitimi (8–12 ve 13+, göreli komutlar).
const relativeTutorial = <TutorialStep>[
  TutorialStep(
    id: 'meet',
    textKey: 'tutRel01',
    boardId: 'T1',
    highlight: [TutorialTarget.character],
  ),
  TutorialStep(
    id: 'goal',
    textKey: 'tutRel02',
    highlight: [TutorialTarget.goal],
  ),
  TutorialStep(
    id: 'arrow',
    textKey: 'tutRel03',
    highlight: [TutorialTarget.arrow, TutorialTarget.frontCell],
  ),
  TutorialStep(
    id: 'firstCard',
    textKey: 'tutRel04',
    highlight: [TutorialTarget.card(_f)],
    waitFor: TutorialAction.tapCard(_f),
    showHand: true,
  ),
  TutorialStep(
    id: 'strip',
    textKey: 'tutRel05',
    highlight: [TutorialTarget.strip],
  ),
  TutorialStep(
    id: 'secondCard',
    textKey: 'tutRel06',
    highlight: [TutorialTarget.card(_f)],
    waitFor: TutorialAction.tapCard(_f),
    showHand: true,
  ),
  TutorialStep(
    id: 'run',
    textKey: 'tutRel07',
    highlight: [TutorialTarget.run],
    waitFor: TutorialAction.runSucceeded(),
    showHand: true,
  ),
  TutorialStep(id: 'bravo', textKey: 'tutRel08', celebrate: true),
  TutorialStep(
    id: 'turnIntro',
    textKey: 'tutRel09',
    boardId: 'T2',
    highlight: [TutorialTarget.character, TutorialTarget.arrow],
  ),
  TutorialStep(
    id: 'turnForward',
    textKey: 'tutRel10',
    highlight: [TutorialTarget.card(_f)],
    waitFor: TutorialAction.tapCard(_f),
  ),
  TutorialStep(
    id: 'turnRight',
    textKey: 'tutRel11',
    highlight: [TutorialTarget.card(_r)],
    waitFor: TutorialAction.tapCard(_r),
    showHand: true,
  ),
  TutorialStep(
    id: 'lastStep',
    textKey: 'tutRel12',
    highlight: [TutorialTarget.card(_f)],
    waitFor: TutorialAction.tapCard(_f),
  ),
  TutorialStep(
    id: 'turnRun',
    textKey: 'tutRel13',
    highlight: [TutorialTarget.run],
    waitFor: TutorialAction.runSucceeded(),
  ),
  TutorialStep(
    id: 'rightLeft',
    textKey: 'tutRel14',
    highlight: [TutorialTarget.card(_r), TutorialTarget.card(_l)],
  ),
  TutorialStep(
    id: 'remove',
    textKey: 'tutRel15',
    highlight: [TutorialTarget.strip],
    waitFor: TutorialAction.removeCard(),
  ),
  TutorialStep(
    id: 'yourTurn',
    textKey: 'tutRel16',
    boardId: 'T3',
    waitFor: TutorialAction.runSucceeded(freePlay: true),
    hintAfterFails: 2,
  ),
  TutorialStep(
    id: 'collectible',
    textKey: 'tutRel17',
    boardId: 'T4',
    highlight: [TutorialTarget.collectible],
  ),
  TutorialStep(id: 'stars', textKey: 'tutRel18', stars: true),
  TutorialStep(
    id: 'practice',
    textKey: 'tutRel19',
    waitFor: TutorialAction.runSucceeded(requireAll: true, freePlay: true),
    hintAfterFails: 2,
  ),
  TutorialStep(
    id: 'lives',
    textKey: 'tutRel20',
    highlight: [TutorialTarget.hearts],
    showLives: true,
  ),
  TutorialStep(
    id: 'jokers',
    textKey: 'tutRel21',
    highlight: [TutorialTarget.jokerBar],
    showJokers: true,
  ),
  TutorialStep(
    id: 'done',
    textKey: 'tutRel22',
    waitFor: TutorialAction.finish(),
    celebrate: true,
  ),
];

/// Okların eğitimi (5–7, mutlak komutlar). Her balonda simge vardır.
const absoluteTutorial = <TutorialStep>[
  TutorialStep(
    id: 'meet',
    textKey: 'tutAbs01',
    boardId: 'A1',
    highlight: [TutorialTarget.character],
    glyphs: [IntroGlyph.heart],
  ),
  TutorialStep(
    id: 'goal',
    textKey: 'tutAbs02',
    highlight: [TutorialTarget.goal],
    glyphs: [IntroGlyph.goal],
  ),
  TutorialStep(
    id: 'firstCard',
    textKey: 'tutAbs03',
    highlight: [TutorialTarget.card(_right)],
    waitFor: TutorialAction.tapCard(_right),
    showHand: true,
    glyphs: [IntroGlyph.finger, IntroGlyph.cardRight],
  ),
  TutorialStep(
    id: 'again',
    textKey: 'tutAbs04',
    highlight: [TutorialTarget.card(_right)],
    waitFor: TutorialAction.tapCard(_right),
    showHand: true,
    glyphs: [IntroGlyph.plus, IntroGlyph.cardRight],
  ),
  TutorialStep(
    id: 'run',
    textKey: 'tutAbs05',
    highlight: [TutorialTarget.run],
    waitFor: TutorialAction.runSucceeded(),
    showHand: true,
    glyphs: [IntroGlyph.finger, IntroGlyph.run],
  ),
  TutorialStep(
    id: 'bravo',
    textKey: 'tutAbs06',
    celebrate: true,
    glyphs: [IntroGlyph.star, IntroGlyph.star, IntroGlyph.star],
  ),
  TutorialStep(
    id: 'down',
    textKey: 'tutAbs07',
    boardId: 'A2',
    waitFor: TutorialAction.runSucceeded(sequence: [_right, _down]),
    showHand: true,
    glyphs: [
      IntroGlyph.cardRight,
      IntroGlyph.then,
      IntroGlyph.cardDown,
      IntroGlyph.then,
      IntroGlyph.run,
    ],
  ),
  TutorialStep(
    id: 'remove',
    textKey: 'tutAbs08',
    highlight: [TutorialTarget.strip],
    waitFor: TutorialAction.removeCard(),
    showHand: true,
    glyphs: [IntroGlyph.finger, IntroGlyph.remove],
  ),
  TutorialStep(
    id: 'treasure',
    textKey: 'tutAbs09',
    boardId: 'A3',
    highlight: [TutorialTarget.collectible],
    waitFor: TutorialAction.runSucceeded(requireAll: true, freePlay: true),
    hintAfterFails: 2,
    glyphs: [IntroGlyph.collectible, IntroGlyph.plus, IntroGlyph.goal],
  ),
  TutorialStep(
    id: 'lives',
    textKey: 'tutAbs10',
    highlight: [TutorialTarget.hearts],
    showLives: true,
    glyphs: [IntroGlyph.heart, IntroGlyph.heart, IntroGlyph.heart],
  ),
  TutorialStep(
    id: 'done',
    textKey: 'tutAbs11',
    waitFor: TutorialAction.finish(),
    celebrate: true,
    glyphs: [IntroGlyph.star],
  ),
];

/// Komut ailesine göre eğitim.
List<TutorialStep> tutorialFor(CommandFamily family) => switch (family) {
  CommandFamily.relative => relativeTutorial,
  CommandFamily.absolute => absoluteTutorial,
};

/// 13+ mekanik tanıtımları: seviyenin kendi tahtasında iki adım.
/// Anahtar: `mechanic_intro_seen_<ad>` tercih anahtarının sonu.
const mechanicIntros = <String, List<TutorialStep>>{
  'ice': [
    TutorialStep(
      id: 'ice',
      textKey: 'tutMechIce',
      highlight: [TutorialTarget.mechanic(CellType.ice)],
    ),
    TutorialStep(
      id: 'iceGhost',
      textKey: 'tutMechWatch',
      highlight: [TutorialTarget.board],
      ghost: true,
      waitFor: TutorialAction.finish(),
    ),
  ],
  'door': [
    TutorialStep(
      id: 'door',
      textKey: 'tutMechDoor',
      highlight: [TutorialTarget.mechanic(CellType.door)],
    ),
    TutorialStep(
      id: 'doorGhost',
      textKey: 'tutMechWatch',
      highlight: [TutorialTarget.board],
      ghost: true,
      waitFor: TutorialAction.finish(),
    ),
  ],
  'portal': [
    TutorialStep(
      id: 'portal',
      textKey: 'tutMechPortal',
      highlight: [TutorialTarget.mechanic(CellType.portalA)],
    ),
    TutorialStep(
      id: 'portalGhost',
      textKey: 'tutMechWatch',
      highlight: [TutorialTarget.board],
      ghost: true,
      waitFor: TutorialAction.finish(),
    ),
  ],
};
