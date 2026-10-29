/// Eğitimi daha önce görmüş (atlamış) oyuncu: "Oyna" doğrudan seviye
/// seçimini açar, 13+ mekanik tanıtımları görülmüş sayılır. "Atlandı"
/// durumunda eski Seviye 1–2 parmak tanıtımları gösterilmeye devam eder.
const seenTutorialPrefs = <String, Object>{
  'tutorial_done_relative': 'skipped',
  'tutorial_done_absolute': 'skipped',
  'mechanic_intro_seen_ice': true,
  'mechanic_intro_seen_door': true,
  'mechanic_intro_seen_portal': true,
};
