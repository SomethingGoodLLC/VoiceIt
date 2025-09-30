# VoiceIt Accessibility Guide

## Overview

VoiceIt is fully accessible and follows Apple's Human Interface Guidelines for accessibility. The app supports VoiceOver, Dynamic Type, and other iOS accessibility features.

## VoiceOver Support

### Key Features

#### Evidence Timeline
- **Each evidence row** provides comprehensive VoiceOver descriptions including:
  - Evidence type (voice note, photo, video, text)
  - Timestamp in relative format
  - Critical status indicator
  - Location information
  - Notes preview
  - Tags
  - Type-specific details (duration, file size, word count)
- **Hint**: "Double tap to view details, swipe up or down for more actions"

#### Panic Button
- **Label**: "Emergency panic button"
- **Hint**: "Press and hold for 3 seconds to activate emergency mode. Drag to reposition."
- **Traits**: Button, Starts media session
- **Minimized state**: Clearly labeled with "Expand panic button" hint

#### Settings Screen
- All toggle switches announce state changes
- Picker selections announce new values
- Clear labels and hints for all interactive elements

#### Emergency Contacts
- Each contact includes name, relationship, and auto-notify status
- Swipe actions are clearly labeled
- Primary contact status announced

### Custom Announcements

The app announces important state changes:
- "Evidence saved successfully" when creating evidence
- "Evidence deleted" when removing evidence
- "Emergency mode activated" when panic button triggers
- "Stealth mode activated/deactivated" for privacy mode
- "Authentication successful/failed" for login

## Dynamic Type Support

### Text Scaling
- All text elements support Dynamic Type sizes from Extra Small to AAAExtra Large
- Minimum scale factor: 0.8 to ensure readability
- Line limits removed on critical text to prevent truncation

### Adaptive Layouts
- Spacing adjusts based on text size
- Buttons scale appropriately
- Multi-line text wraps naturally

## Accessibility Features by Screen

### Timeline View
- Pull-to-refresh: "Pull down to refresh timeline"
- Filter buttons: Clear labels for each evidence type
- Export banner: Announces item count and export options
- Empty state: Clear guidance when no evidence exists

### Add Evidence View
- Large central + button: "Add new evidence"
- Action sheet options: Voice, Photo, Video, Text clearly labeled
- Recording states announced for voice and video

### Emergency Features
- Panic button: Persistent, draggable, with hold gesture
- Emergency contacts: Swipe actions for call/message/delete
- Countdown sheet: "I'm Safe" button clearly labeled

### Settings
- All toggles announce state changes
- Pickers announce selection changes
- Navigation links include "Double tap to open" hint
- Destructive actions include confirmation prompts

### Stealth Mode
- Decoy screens labeled as "Calculator mode", "Weather mode", "Notes mode"
- Unlock mechanism clearly explained
- Biometric prompts accessible

## Color Contrast

### Accessibility Colors
- **Primary purple**: #7C3AED (WCAG AA compliant)
- **Error red**: System red for critical indicators
- **Text contrast**: Follows iOS system standards
- **Dark mode**: Full support with appropriate contrast ratios

## Motion & Animations

### Reduce Motion Support
- Crossfade transitions instead of slides when Reduce Motion is enabled
- Haptic feedback maintained for non-visual cues
- Progress indicators use opacity changes instead of complex animations

## Testing Accessibility

### VoiceOver Testing Checklist

1. **Enable VoiceOver**: Settings → Accessibility → VoiceOver
2. **Navigate Timeline**:
   - Swipe right/left to navigate between evidence items
   - Verify each item reads complete information
   - Test swipe actions (swipe up/down for actions)
3. **Test Panic Button**:
   - Verify hold gesture is announced
   - Test dragging to reposition
   - Verify countdown announcements
4. **Test Settings**:
   - Navigate through all sections
   - Toggle switches and verify announcements
   - Test picker selections
5. **Test Add Evidence**:
   - Navigate to each evidence type
   - Verify recording states are announced
   - Test save confirmation

### Dynamic Type Testing

1. **Enable Large Text**: Settings → Accessibility → Display & Text Size → Larger Text
2. **Test Sizes**: Try Extra Small, Default, and AAAExtra Large
3. **Verify Layouts**:
   - Text doesn't truncate
   - Buttons remain tappable
   - Spacing adapts appropriately
   - Multi-line text wraps correctly

### Keyboard Navigation (iPad/Mac)

1. **Tab Navigation**: Verify tab key moves focus
2. **Arrow Keys**: Navigate lists and pickers
3. **Space/Return**: Activate buttons and controls
4. **Escape**: Close sheets and modals

## Accessibility Identifiers

For UI testing, all major elements have accessibility identifiers:

### Evidence
- `evidence-row-{UUID}`: Each evidence row
- `add-evidence-button`: Main add button
- `filter-chip-{type}`: Filter buttons

### Emergency
- `panic-button-minimized`: Minimized panic button
- `panic-button-expanded`: Expanded panic button
- `emergency-contact-{UUID}`: Each contact row

### Settings
- `settings-security-section`: Security settings group
- `settings-privacy-section`: Privacy settings group
- `app-icon-picker`: Icon selection screen

## Accessibility APIs Used

- **UIAccessibility**: For VoiceOver announcements
- **AccessibilityTraits**: Button, header, selected states
- **AccessibilityActions**: Custom swipe actions
- **AccessibilityLabels**: Descriptive text for screen readers
- **AccessibilityHints**: Guidance for interactions
- **AccessibilityValues**: Dynamic state information
- **AccessibilityIdentifiers**: UI testing support

## Best Practices Implemented

1. **Meaningful Labels**: All interactive elements have descriptive labels
2. **State Announcements**: Dynamic changes are announced to VoiceOver
3. **Logical Reading Order**: Content flows naturally for screen readers
4. **Grouped Elements**: Related content combined into single elements
5. **Hidden Decorations**: Purely decorative icons hidden from VoiceOver
6. **Custom Actions**: Swipe actions properly labeled
7. **Dynamic Type**: All text scales appropriately
8. **Contrast Ratios**: Meet or exceed WCAG AA standards
9. **Touch Targets**: Minimum 44x44 points for all tappable areas
10. **Keyboard Support**: Full keyboard navigation on iPad/Mac

## Known Limitations

1. **Camera Views**: Live camera preview not accessible via VoiceOver (iOS limitation)
2. **Audio Waveforms**: Visual waveforms not described (audio itself is accessible)
3. **Map Views**: Location map requires sighted assistance (coordinates are provided)

## Future Improvements

- [ ] Audio descriptions for camera guidance
- [ ] Haptic patterns for recording states
- [ ] Braille display support testing
- [ ] Voice Control optimization
- [ ] Switch Control support

## Feedback

Users can report accessibility issues through:
- Settings → Support & Resources → Technical Support
- Email: support@voiceit.app
- Include iOS version, accessibility features used, and steps to reproduce

## Resources

- [Apple Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [iOS Accessibility Programming Guide](https://developer.apple.com/accessibility/ios/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

**Last Updated**: September 2025
**App Version**: 1.0.0
**iOS Target**: 18.0+
