# Peach — Glossary

## Concepts

### Core Training Concepts

| Term | Definition |
|---|---|
| **Comparison** | A single training interaction containing Note1, Note2, cent difference, and direction. Two sequential notes are played, and the user judges whether the second is higher or lower than the first. The atomic unit of training. |
| **Completed Comparison** | A comparison bundled with the user's answer and timestamp. Contains the original comparison, whether the user answered higher, and whether the answer was correct. Used for recording and analysis. |
| **Answer** | The user's judgment in a comparison - either "higher" (the second note is higher) or "lower" (the second note is lower). Recorded as `userAnsweredHigher` in the system. |
| **Note1** | The reference note in a comparison, specified as a MIDI number (0-127). The first note played in each comparison. |
| **Note2** | The target note in a comparison, specified as a MIDI number (0-127). Typically the same MIDI number as Note1, with pitch difference applied through cent offset. The second note played in each comparison. |
| **Cent** | Unit of pitch difference. 100 cents = 1 semitone. Used as the measure of discrimination precision. |
| **Cent Difference** | The magnitude of pitch difference between two notes, always positive. 100 cents equals 1 semitone. Converted to signed cent offset based on direction. |
| **Cent Offset** | The signed pitch difference applied to a note. Positive values raise the pitch, negative values lower it. Used in frequency calculations and profile statistics. |
| **MIDI Note** | A standardized numerical representation of musical pitch (0-127), where 60 is middle C (C4) and 69 is A4. Each increment represents one semitone. |

### Algorithm & Strategy

| Term | Definition |
|---|---|
| **Next Note Strategy** | A protocol defining how the next comparison is selected based on the user's perceptual profile and training settings. Implementations determine which note to present and what cent difference to use. |
| **Adaptive Note Strategy** | The intelligent comparison selection algorithm. Balances between exploring nearby notes (Natural mode) and targeting weak spots (Mechanical mode). Adjusts difficulty regionally based on user performance. |
| **Natural vs. Mechanical** | The user-facing algorithm behavior slider (0.0 to 1.0). Natural (0.0) selects nearby notes for regional training. Mechanical (1.0) jumps to weak spots across the range. Values in between use weighted probability. |
| **Weak Spot** | A note where the user's detection threshold is relatively large, indicating lower discrimination ability. Identified by comparing absolute mean values across notes - untrained notes are considered the weakest spots. The algorithm prioritizes these in Mechanical mode. |
| **Regional Range** | The pitch range (±12 semitones = one octave) defining a training region. Within this range: (1) difficulty persists and adjusts gradually based on performance, (2) Natural mode selects nearby notes to maintain regional focus. Jumping beyond this range resets difficulty to the mean detection threshold and switches training zones. |
| **Narrowing Factor** | The multiplier (0.95 = 5% harder) applied to cent difference after a correct answer within the same regional range. Makes subsequent comparisons progressively more challenging. |
| **Widening Factor** | The multiplier (1.3 = 30% easier) applied to cent difference after an incorrect answer within the same regional range. Makes subsequent comparisons easier to help the user succeed. |
| **Current Difficulty** | The active cent difference being used for a note during regional training. Starts at the mean detection threshold when jumping to a new region, then adjusts via narrowing/widening factors based on correctness. Distinct from mean detection threshold, which tracks historical averages across all comparisons. |
| **Range Mean** | The average detection threshold calculated across all trained notes in the note range. Used as the initial difficulty for untrained notes when no nearby trained notes exist. Falls back to 100 cents if no notes are trained. |

### Profile & Statistics

| Term | Definition |
|---|---|
| **Perceptual Profile** | A map of the user's pitch discrimination ability across the note range. Tracks per-note statistics (mean detection threshold, standard deviation, sample count) for all 128 MIDI notes. Updated incrementally as comparisons complete. Identifies weak spots and informs difficulty selection. Visualized as a confidence band over a piano keyboard. |
| **Mean Detection Threshold** | The average signed cent offset at which comparisons have been presented for a specific note. Positive values indicate more "higher" comparisons, negative values indicate more "lower" comparisons. Represents the estimated pitch difference the user can discriminate at that note. Derived incrementally from comparison history using Welford's algorithm. Used to identify weak spots and set difficulty. |
| **Standard Deviation** | A measure of consistency in pitch discrimination for a note. Lower values indicate more consistent performance. Calculated incrementally using Welford's algorithm. |
| **Sample Count** | The number of comparisons completed for a specific note. Notes with zero sample count are considered untrained. Used to determine whether a note has sufficient training data. |
| **Trained Note** | A note with at least one completed comparison (sample count > 0). Has statistical data (mean, standard deviation) that can inform difficulty selection. |
| **Untrained Note** | A note with zero completed comparisons. Receives highest priority as a weak spot. Initial difficulty determined from range mean or defaults to 100 cents. |
| **Welford's Algorithm** | An incremental statistical method for calculating mean and variance without storing all historical data. Enables efficient real-time profile updates as each comparison completes. |
| **Cold Start** | The initial state for a new user or untrained note. All notes have zero sample count, no statistical data exists. Comparisons default to 100-cent differences, and note selection is either random or prioritizes untrained notes as weak spots. |
| **Confidence Band** | The visual representation of detection thresholds across the note range, overlaid on the piano keyboard in the perceptual profile visualization. |

### Training & State

| Term | Definition |
|---|---|
| **Training Session** | The central orchestrator for the training loop state machine. Coordinates comparison generation, note playback, answer handling, observer notification, and feedback display. Manages graceful error handling and audio interruptions. |
| **Training State** | The current phase of the training loop. Values: idle (not training), playingNote1 (first note playing, buttons disabled), playingNote2 (second note playing, buttons enabled), awaitingAnswer (both notes finished, waiting for user), showingFeedback (displaying result before next comparison). |
| **Haptic Feedback** | Tactile vibration provided through the device when an answer is incorrect. Uses a double heavy-intensity impact pattern. No haptic occurs for correct answers (silence = confirmation). Enables eyes-closed training. |
| **Audio Interruption** | An external event that disrupts audio playback, such as phone calls, Siri activation, alarms, or headphone disconnection. Automatically stops training, requiring explicit user restart. |

### Configuration

| Term | Definition |
|---|---|
| **Reference Pitch** | The tuning standard used to derive all note frequencies. Default: A4 = 440Hz (standard concert pitch). Supports alternative tunings including A442 (orchestral), A432 (alternative), and A415 (baroque). Configurable in settings. |
| **Note Range** | The span of MIDI notes used for comparisons, defined by minimum and maximum boundaries (noteRangeMin and noteRangeMax in TrainingSettings). Default: C2 to C6 (MIDI 36-84), covering typical vocal and instrument ranges. Configurable in settings. Also referred to as "training range" in user-facing contexts. |
| **Training Settings** | Configuration parameters that control the adaptive algorithm's behavior. Includes note range boundaries, Natural/Mechanical balance, reference pitch, and difficulty bounds (min/max cent difference). |
| **Min Cent Difference** | The difficulty floor - the smallest cent difference the algorithm will use. Default: 1.0 cent, representing the practical limit of human pitch discrimination. Prevents comparisons from becoming impossibly difficult. |
| **Max Cent Difference** | The difficulty ceiling - the largest cent difference the algorithm will use. Default: 100.0 cents (1 semitone), representing easily detectable intervals. Prevents comparisons from becoming too easy. |

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
| **Feedback Indicator** | Visual element on the Training Screen showing thumbs up (correct) or thumbs down (incorrect) after each comparison. Displays for 0.4 seconds before the next comparison begins. Accompanied by haptic feedback on incorrect answers. |
