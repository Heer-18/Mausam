---
name: Mausam
colors:
  surface: '#131315'
  surface-dim: '#131315'
  surface-bright: '#39393b'
  surface-container-lowest: '#0e0e10'
  surface-container-low: '#1b1b1d'
  surface-container: '#1f1f21'
  surface-container-high: '#2a2a2c'
  surface-container-highest: '#353437'
  on-surface: '#e4e2e4'
  on-surface-variant: '#c1c6d7'
  inverse-surface: '#e4e2e4'
  inverse-on-surface: '#303032'
  outline: '#8b90a0'
  outline-variant: '#414755'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e69'
  primary-container: '#4b8eff'
  on-primary-container: '#00285c'
  inverse-primary: '#005bc1'
  secondary: '#ffbc7c'
  on-secondary: '#4b2800'
  secondary-container: '#fe9400'
  on-secondary-container: '#633700'
  tertiary: '#c2c1ff'
  on-tertiary: '#1c0b9f'
  tertiary-container: '#8382ff'
  on-tertiary-container: '#150093'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004493'
  secondary-fixed: '#ffdcbf'
  secondary-fixed-dim: '#ffb874'
  on-secondary-fixed: '#2d1600'
  on-secondary-fixed-variant: '#6a3b00'
  tertiary-fixed: '#e2dfff'
  tertiary-fixed-dim: '#c2c1ff'
  on-tertiary-fixed: '#0c006a'
  on-tertiary-fixed-variant: '#3631b4'
  background: '#131315'
  on-background: '#e4e2e4'
  surface-variant: '#353437'
typography:
  display-temp:
    fontFamily: Inter
    fontSize: 96px
    fontWeight: '700'
    lineHeight: 116px
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.1em
  data-mono:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 20px
  stack-gap: 12px
  grid-gutter: 16px
---

## Brand & Style
The design system is centered on **Modern Clarity**, a style that fuses high-utility data density with an atmospheric, immersive aesthetic. It aims to evoke a sense of reliability and proactive insight, transforming raw meteorological data into intuitive visual stories.

The interface leverages **Glassmorphism** to create a sense of depth and lightness, mimicking the layering of the atmosphere itself. Backgrounds are not static; they are dynamic canvases that reflect current weather states, while UI components float atop using translucent materials. The overall feel is sophisticated, calm, and technologically advanced, positioning the product as an essential, high-end tool for daily planning.

## Colors
The color strategy is inherently adaptive. While **Mausam Blue (#007AFF)** serves as the anchor for interactive elements and brand identity, the interface palette shifts based on the weather state:
- **Clear/Sunny:** Transitions to vibrant sky blues and solar yellows.
- **Stormy/Rainy:** Deepens into indigos, teals, and slate grays.
- **Sunset/Dusk:** Warm oranges, soft purples, and deep magentas.

The default mode is **Dark**, as it allows glassmorphic layers and vibrant semantic colors (for AQI and UV levels) to pop with maximum legibility. Use semantic colors strictly for data visualization and status alerts to maintain a "glanceable" hierarchy.

## Typography
This design system utilizes **Inter** across all levels to ensure clinical legibility of dense numerical data. 

- **Display Scales:** The primary temperature reading uses a heavy weight and tight tracking to act as the visual hero of the layout.
- **Data Tables:** For hourly forecasts and specific metrics (humidity, pressure), use the `data-mono` setting (tabular figures) to ensure columns align perfectly regardless of the digits displayed.
- **Hierarchy:** Use `label-caps` for section headers (e.g., "AIR QUALITY", "SUNSET") to provide clear boundaries between data modules without occupying excessive vertical space.

## Layout & Spacing
The layout follows a **Fluid Grid** model with a focus on vertical stacking for mobile-first consumption. 

- **Grid:** On mobile, use a 4-column grid; on desktop, a 12-column grid.
- **Modules:** Content is organized into "Weather Modules" (cards). These cards should have consistent internal padding of `16px`.
- **Rhythm:** Use an 8px base unit. Gaps between modules should be `12px` or `16px` to maintain a tight, information-rich density without feeling cluttered. 
- **Safe Areas:** Ensure a `20px` horizontal margin on mobile to prevent content from touching the screen edges, especially for glassmorphic elements which require visible edges to maintain the "glass" illusion.

## Elevation & Depth
Depth is achieved through **Glassmorphism** and backdrop filters rather than traditional shadows.

- **Background Layers:** Use high-definition atmospheric imagery or animated weather gradients as the base layer.
- **Surface Layers:** All cards use a semi-transparent fill (e.g., `rgba(255, 255, 255, 0.1)`) with a `backdrop-filter: blur(20px)`. 
- **Edge Definition:** Apply a 1px inner border (stroke) to all glass cards using a high-opacity top-left gradient to simulate a light catch on the "edge of the glass."
- **Z-Index:** The 'Advisor AI' interface sits at the highest elevation, utilizing a soft, colored outer glow that pulses slightly to indicate activity, separating it visually from static weather cards.

## Shapes
The shape language is **Rounded** to feel modern and friendly. 

- **Cards:** Use `rounded-lg` (1rem/16px) for main weather modules to create a soft, contained look.
- **Interactive Elements:** Buttons and input fields should use `rounded-xl` (1.5rem/24px) or full pill-shapes to differentiate them from static data cards.
- **Visualizations:** Progress rings for AQI and UV should use rounded caps on their strokes to maintain the overall softness of the design system.

## Components
- **Weather Cards:** The core component. Glassmorphic, containing a label, a large icon or value, and a sub-text description.
- **Advisor AI Chat:** A distinctive interface using a subtle gradient background (Primary Blue to Tertiary Purple). Message bubbles should be highly rounded; the input field should have a "glow" focus state.
- **Data Visualizations:** 
    - **Progress Rings:** Use for AQI and UV. A thick background track with a vibrant, color-coded foreground stroke.
    - **Line Charts:** For 24-hour temperature. Use a smooth Bezier curve with a subtle gradient fill underneath the line.
- **Weather-State Icons:** Minimalist, monochromatic icons that use transparency and "frosted" segments to match the glass style.
- **Chips:** Small, high-contrast capsules used for "Active Alerts" or "Rain Starting Soon" notifications.
- **Buttons:** Primary buttons use a solid 'Mausam Blue' fill with white text. Secondary buttons use the glass style with a white border.