# Staff4dshire Properties - Design System

## Color Palette

### Primary Colors
- **Primary 700** (Dark Purple): `#4a026f`
  - Usage: Buttons, headers, interactive elements, primary actions
  - Text on primary: White (`#FFFFFF`)

- **Primary 500** (Light Purple): `#897c98`
  - Usage: Backgrounds, highlights, secondary buttons, accents

### Secondary Colors
- **Secondary 500** (Grey): `#707173`
  - Usage: Text, icons, borders, secondary elements

### Status Colors
- **Success**: `#10B981` (Green)
- **Error**: `#EF4444` (Red)
- **Warning**: `#F59E0B` (Orange)
- **Info**: `#3B82F6` (Blue)

### Neutral Colors
- **Background**: White (`#FFFFFF`)
- **Surface**: Light Grey (`#F9FAFB`)
- **On Background**: Dark Grey (`#111827`)
- **On Surface**: Grey (`#1F2937`)

## Typography

### Font Family
- **Primary**: Inter
- **Weights**: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)

### Font Sizes
- **Display Large**: 32px (Bold)
- **Display Medium**: 28px (Bold)
- **Display Small**: 24px (Bold)
- **Headline Large**: 22px (SemiBold)
- **Headline Medium**: 20px (SemiBold)
- **Headline Small**: 18px (SemiBold)
- **Title Large**: 18px (SemiBold)
- **Title Medium**: 16px (SemiBold)
- **Title Small**: 14px (SemiBold)
- **Body Large**: 16px (Regular)
- **Body Medium**: 14px (Regular)
- **Body Small**: 12px (Regular)
- **Label Large**: 14px (SemiBold)
- **Label Medium**: 12px (SemiBold)
- **Label Small**: 11px (SemiBold)

## Spacing

### Base Unit
- 4px increments

### Common Spacings
- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 24px
- **2xl**: 32px
- **3xl**: 48px

## Components

### Buttons

#### Primary Button
- Background: Primary 700
- Text: White
- Padding: 24px horizontal, 16px vertical
- Border Radius: 12px
- Font: SemiBold, 16px

#### Secondary Button
- Background: Primary 500
- Text: White
- Padding: 24px horizontal, 16px vertical
- Border Radius: 12px
- Font: SemiBold, 16px

#### Outlined Button
- Border: 2px solid Primary 700
- Text: Primary 700
- Background: Transparent
- Padding: 24px horizontal, 16px vertical
- Border Radius: 12px
- Font: SemiBold, 16px

### Input Fields

- Background: Surface color
- Border: 1px solid Secondary 200
- Border Radius: 12px
- Padding: 16px
- Focus State: 2px solid Primary 700 border
- Label: Secondary 500, 14px
- Placeholder: Secondary 300, 14px

### Cards

- Background: White
- Border Radius: 16px
- Shadow: 2px elevation
- Padding: 20px (standard)

### Navigation

#### Bottom Navigation
- Background: White
- Selected: Primary 700
- Unselected: Secondary 400
- Icon Size: 24px
- Label: 12px, SemiBold

#### App Bar
- Background: Primary 700
- Text: White
- Height: 56px
- Elevation: 0

## Layout Guidelines

### Grid System
- Maximum Content Width: 1280px (7xl)
- Standard Padding: 16px (mobile), 24px (tablet/desktop)
- Column Gutter: 16px (mobile), 24px (desktop)

### Breakpoints
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

## Accessibility

### Color Contrast
- Text on Primary: WCAG AAA compliant
- Body text: Minimum 4.5:1 contrast ratio
- Interactive elements: Minimum 3:1 contrast ratio

### Touch Targets
- Minimum size: 44x44px
- Recommended: 48x48px

### Font Sizes
- Minimum readable: 12px
- Recommended body: 14-16px

## Animation & Transitions

### Standard Transitions
- Duration: 200-300ms
- Easing: Ease-in-out
- Common properties: Color, opacity, transform

### Loading States
- Skeleton loaders for content
- Circular progress for actions
- Linear progress for page loading

## Icons

### Icon Library
- Material Icons (Flutter)
- Heroicons (Next.js)

### Icon Sizes
- Small: 16px
- Medium: 24px
- Large: 32px
- XLarge: 48px

## Brand Guidelines

### Logo Usage
- Full logo with "Staff4dshire Properties" text
- Icon-only variant for small spaces
- Minimum clear space: 2x icon height

### Tone of Voice
- Professional
- Clear and concise
- Helpful and supportive
- Trustworthy

