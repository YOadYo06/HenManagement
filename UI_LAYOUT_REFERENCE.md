# Live Metrics Dashboard - UI Layout

## Visual Reference (Text Representation)

```
┌─────────────────────────────────────────────────────────────┐
│           Live Metrics Dashboard                            │
│ ⌫  HOME  ⚙️                                                  │
└─────────────────────────────────────────────────────────────┘

┌───────────────────── BLUE GRADIENT HEADER ───────────────────┐
│                                                               │
│ IoT University Mental Health                         [75%]    │
│ Monitoring mental health through environmental sensors       │
│                                                               │
│ [4 Sensors] [Weights: Compromise]                           │
│                                                               │
│ [CHANGE DATASET]              [WEIGHT METHOD]                │
│                                                               │
└───────────────────────────────────────────────────────────────┘

┌──────────────────── LAST METRIC CARD ────────────────────────┐
│ Last Metric                                         [75.3%]   │
│                                                               │
│ 📊 IoT University Mental Health                              │
│    Weights: Compromise                                       │
│                                                               │
│                    ┌─────────────────┐                       │
│                    │     75.3%       │                       │
│                    │      GOOD       │                       │
│                    │   (Light Green) │                       │
│                    └─────────────────┘                       │
│                                                               │
│ Sensor Values:                                               │
│ Temperature         24.5°C    [████████░░░░░░░░░░░░]  50%   │
│ Humidity             60.0%    [██████████████░░░░░░░░]  60%   │
│ Noise Level         55.0dB    [███████████░░░░░░░░░░░░]  55%   │
│ Lighting            350Lux    [██████████████████░░░░░░]  70%   │
│                                                               │
│ 🧮 Weight Formula:                                           │
│    Weight = (STD+Entropy+CRITIC+MEREC)/4 (Balanced)         │
│                                                               │
│ Calculated: 2024-01-15 10:30:45                             │
└───────────────────────────────────────────────────────────────┘

┌──────────────── EDIT METRICS CARD ────────────────────────────┐
│ 🎛️ Edit Metrics                                              │
│                                                               │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Temperature (°C)                  Weight: 26.8%    [°C]  │ │
│ │ [✓ Use Dataset ]  [ Custom ]                             │ │
│ │ Choose Value:                                            │ │
│ │  [Min: 15.24]  [Mean: 24.21]  [Max: 33.58]             │ │
│ │  Selected: Mean: 24.21°C                                │ │
│ └──────────────────────────────────────────────────────────┘ │
│                                                               │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Humidity (%)                      Weight: 27.7%    [%]   │ │
│ │ [✓ Use Dataset ]  [ Custom ]                             │ │
│ │ Choose Value:                                            │ │
│ │  [Min: 29.8]  [Mean: 60.19]  [Max: 91.38]              │ │
│ │  Selected: Mean: 60.19%                                 │ │
│ └──────────────────────────────────────────────────────────┘ │
│                                                               │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Noise Level (dB)                  Weight: 30.8%   [dB]  │ │
│ │ [ Use Dataset ]  [✓ Custom ]                             │ │
│ │ Enter Value (24.54 - 85.93 dB):                         │ │
│ │  ┌──────────┐                                            │ │
│ │  │ 55.0     │ dB                                         │ │
│ │  └──────────┘                                            │ │
│ └──────────────────────────────────────────────────────────┘ │
│                                                               │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Lighting (Lux)                    Weight: 14.7%  [Lux]  │ │
│ │ [✓ Use Dataset ]  [ Custom ]                             │ │
│ │ Choose Value:                                            │ │
│ │  [Min: 155.22]  [Mean: 301.5]  [Max: 502.63]           │ │
│ │  Selected: Mean: 301.5 Lux                              │ │
│ └──────────────────────────────────────────────────────────┘ │
│                                                               │
└───────────────────────────────────────────────────────────────┘

┌──────────────── HOW TO USE CARD ──────────────────────────────┐
│                                                               │
│ ✓ 1. Choose Dataset: Select from 8 pre-configured datasets  │
│ ✓ 2. Pick Weight Method: Compare STD, Entropy, CRITIC, ...  │
│ ✓ 3. Set Sensor Values: Use dataset (min/max/mean) or edit  │
│ ✓ 4. View Score: Real-time MCDM comfort score updates       │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Color Reference

### Score Colors (MCDM Interpretation)
```
Red        #FF5722    0-20%   Critical
Orange     #FFF57F1   20-40%  Poor
Amber      #FFC107    40-60%  Fair
Lt Green   #8BC34A    60-80%  Good
Green      #4CAF50    80-100% Excellent
```

### UI Element Colors
```
Header Background      Blue 400-600 gradient (#2196F3 → #1565C0)
Button (Primary)       Blue (#2196F3)
Button (Secondary)     Green (#4CAF50)
Text (Primary)         Dark Gray (#212121)
Text (Secondary)       Medium Gray (#757575)
Divider                Light Gray (#BDBDBD)
Card Background        White (#FFFFFF)
Help Section BG        Light Blue (#E3F2FD)
Selected Button        Dark Blue (#1976D2)
Unselected Button      Light Gray (#E0E0E0)
```

## Responsive Layout

### Portrait (Mobile)
```
Width: 360-600px

┌─────────────────────┐
│     HEADER          │  ← Full width
├─────────────────────┤
│  LAST METRIC        │  ← Cards stack vertically
│                     │
├─────────────────────┤
│  EDIT METRICS       │
│  (Scrollable)       │
│                     │
├─────────────────────┤
│  HOW TO USE         │
│                     │
└─────────────────────┘
```

### Landscape / Tablet
```
Width: 600px+

┌──────────────────────────────────┐
│          HEADER (Full)           │
├────────────────┬─────────────────┤
│  LAST METRIC   │  EDIT METRICS   │
│                │  (Scrollable)   │
│                │                 │
├────────────────┴─────────────────┤
│          HOW TO USE              │
└──────────────────────────────────┘
```

## State Transitions

### 1. Loading State
```
┌─────────────────────┐
│  Calculating Metric │
│        ↻            │  ← Spinner
│                     │
│   Calculating...    │
└─────────────────────┘
```

### 2. No Metric State (Initial)
```
┌─────────────────────┐
│       ℹ️             │
│  No Metric          │
│  Calculated Yet     │
│                     │
│ Select sensors and  │
│ values to calculate │
│ a comfort score     │
└─────────────────────┘
```

### 3. Error State (Config Not Loaded)
```
┌─────────────────────┐
│       ⚠️             │
│  Configuration      │
│  Not Loaded         │
│                     │
│ The MCDM config     │
│ file is not loaded. │
│ Check assets.       │
│                     │
│       [OK]          │
└─────────────────────┘
```

## Interaction Examples

### Example 1: User Changes Dataset

```
User taps: [CHANGE DATASET]
    ↓
Modal Opens with List:
  ✓ IoT Mental Health (4 sensors)
    Air Quality (5 sensors)
    Green Building (4 sensors)
    Smart Library (5 sensors)
    Occupancy (5 sensors)
    Egg Production (3 sensors)
    Herbal Plant (4 sensors)
    User Behavior (5 sensors)
    ↓
User taps: Air Quality (5 sensors)
    ↓
Modal Closes
    ↓
Dashboard Updates:
  - Header changes to "Air Quality Analysis"
  - Edit Metrics updates: 5 sensors instead of 4
  - Last Metric clears (no metric for new dataset yet)
```

### Example 2: User Edits Custom Sensor Value

```
User sees: Temperature [Use Dataset] ✓
                       [Custom]

User taps: [Custom]
    ↓
Temperature field updates:
  - Shows text input instead of min/max/mean
  - Input shows: "24.21" (current mean value)
  ↓
User taps input: [24.21]
  ↓
User types: 30.5
  ↓
Real-time update:
  - Last Metric score recalculates
  - New score displays with new color
  - Sensor breakdown updates
  - All in ~1ms (imperceptible)
```

### Example 3: User Compares Weight Methods

```
User taps: [WEIGHT METHOD]
    ↓
Modal Opens with List:
  ✓ Compromise
    STD
    Entropy
    CRITIC
    MEREC
    ↓
User taps: STD
    ↓
Modal Closes
    ↓
Dashboard Updates:
  - Header: "Weights: STD"
  - Last Metric recalculates with STD weights
  - Score may change (emphasizes high variance)
  - Color and interpretation updates
  - Formula explanation changes
```

## Accessibility Features

- ✅ Touch targets: 48x48 dp minimum
- ✅ Text contrast: 4.5:1 ratio (WCAG AA)
- ✅ Font sizes: Min 14sp (body text)
- ✅ Color not only indicator (text + icon)
- ✅ Clear button labels
- ✅ Scrollable on small screens
- ✅ Semantic structure

## Animation Details

### Button Press
```
Duration: 100ms
Effect: Ripple + scale (98% → 100%)
Color: Darker by 10%
```

### Card Appearance
```
Duration: 200ms
Effect: Fade + slide up
From: 20px below
To: Final position
```

### Score Update
```
Duration: 300ms
Effect: Color fade + scale pulse
Color: Old color → New color
Size: 100% → 102% → 100%
```

### Metric Card Rebuild
```
Duration: 150ms
Effect: Smooth repaint
No full fade (keeps context)
```

## Typography

```
Header (AppBar)          20sp Bold      #FFFFFF
Dataset Name            20sp Bold      #FFFFFF
Dataset Description     13sp Regular   #FFFFFF (80%)
Metric Title           18sp Bold      #212121
Metric Score           48sp Bold      (Color)
Interpretation Text    18sp Bold      (Color)
Sensor Name            14sp Regular   #212121
Sensor Value           12sp Bold      #212121
Formula Text           11sp Monospace #1976D2
Help Section           13sp Regular   #1976D2
Button Text            14sp Medium    (Varies)
```

## Spacing

```
Page Margins            16dp all sides
Card Margins            16dp all sides
Card Padding            20dp all sides
Section Spacing         16dp between sections
Sensor Card Spacing     12dp between cards
Internal Padding        12dp (sensor inputs)
Button Height           48dp (touch target)
List Item Height        64dp
Icon Size               24sp (standard)
Avatar Size             40dp
```

---

**This visual reference helps you understand what users will see when using the Live Metrics Dashboard!**
