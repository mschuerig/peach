# Peach — Glossary

## Concepts

| Term | Definition |
|---|---|
| **Comparison** | A single training interaction: two sequential notes played, user judges whether the second is higher or lower than the first. The atomic unit of training. |
| **Perceptual Profile** | A map of the user's pitch discrimination ability across their training range, showing the smallest detectable cent difference at each note. Visualized as a confidence band over a piano keyboard. |
| **Cent** | Unit of pitch difference. 100 cents = 1 semitone. Used as the measure of discrimination precision. |
| **Reference Pitch** | The tuning standard used to derive all note frequencies. Default: A4 = 440Hz. Configurable in settings. |
| **Training Range** | The span of musical notes the app uses for comparisons. Can be set manually or expand adaptively based on performance at the edges. |
| **Cold Start** | The initial state for a new user: all notes are treated as weak, comparisons use 100-cent (1 semitone) differences, comparisons are selected randomly. |
| **Weak Spot** | A note or region in the training range where the user's detectable cent difference is relatively large — indicating lower discrimination ability. The algorithm prioritizes these. |
| **Natural vs. Mechanical** | The user-facing algorithm behavior slider. "Natural" keeps comparisons in nearby pitch regions before jumping to weak spots. "Mechanical" jumps more aggressively across the range. |
| **Confidence Band** | The visual representation of detection thresholds across the training range, overlaid on the piano keyboard in the perceptual profile visualization. |
| **Detection Threshold** | The smallest cent difference the user can reliably discriminate at a given note. Derived from comparison history. |

## Screens

| Term | Definition |
|---|---|
| **Start Screen** | The app's home screen. Shows the Start Training Button, a short app description, the Profile Preview (tappable), and buttons for Settings Screen, Profile Screen, and Info Screen. |
| **Info Screen** | Displays app name, developer, copyright, and version number. Accessible from the Start Screen. |
| **Training Screen** | The active training interface. Shows the Higher Button, Lower Button, and Feedback Indicator, plus buttons for Settings Screen and Profile Screen. Navigating to Settings or Profile stops training. Minimal by design — no distractions. |
| **Profile Screen** | The full perceptual profile visualization. Shows the piano keyboard with confidence band overlay, summary statistics (mean and standard deviation with trend). Accessible from both Start Screen and Training Screen. Always returns to Start Screen. |
| **Settings Screen** | Configuration interface. Contains the Natural vs. Mechanical slider, note range, note duration, reference pitch, and sound source selection. |

## Controls

| Term | Definition |
|---|---|
| **Start Training Button** | Prominent button on the Start Screen that immediately begins a training session. The primary call to action. |
| **Higher Button** | Training Screen control. User taps this when they judge the second note to be higher than the first. Disabled during the first note, enabled when the second note plays. |
| **Lower Button** | Training Screen control. User taps this when they judge the second note to be lower than the first. Disabled during the first note, enabled when the second note plays. |
| **Profile Preview** | Stylized miniature of the perceptual profile shown on the Start Screen. Tappable to navigate to the full Profile Screen. |
| **Feedback Indicator** | Visual element on the Training Screen showing thumbs up (correct) or thumbs down (incorrect) after each comparison. Accompanied by haptic feedback on incorrect answers. |
