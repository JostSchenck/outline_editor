import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:structured_rich_text_editor/src/infrastructure/platform.dart';
import 'package:super_editor/super_editor.dart';

// parts copied from super_editor LICENSE

ExecutionInstruction moveUpAndDownWithArrowKeysWithFolding({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  const arrowKeys = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  ];
  if (!arrowKeys.contains(keyEvent.logicalKey)) {
    return ExecutionInstruction.continueExecution;
  }

  if (CurrentPlatform.isWeb && (editContext.composer.composingRegion.value != null)) {
    // We are composing a character on web. It's possible that a native element is being displayed,
    // like an emoji picker or a character selection panel.
    // We need to let the OS handle the key so the user can navigate
    // on the list of possible characters.
    // TODO: update this after https://github.com/flutter/flutter/issues/134268 is resolved.
    return ExecutionInstruction.blocked;
  }

  if (defaultTargetPlatform == TargetPlatform.windows && HardwareKeyboard.instance.isAltPressed) {
    return ExecutionInstruction.continueExecution;
  }

  if (defaultTargetPlatform == TargetPlatform.linux && HardwareKeyboard.instance.isAltPressed) {
    return ExecutionInstruction.continueExecution;
  }

  bool didMove = false;
  if (keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
    if (CurrentPlatform.isApple && HardwareKeyboard.instance.isAltPressed) {
      didMove = editContext.commonOps.moveCaretUpstream(
        expand: HardwareKeyboard.instance.isShiftPressed,
        movementModifier: MovementModifier.paragraph,
      );
    } else if (CurrentPlatform.isApple && HardwareKeyboard.instance.isMetaPressed) {
      didMove =
          editContext.commonOps.moveSelectionToBeginningOfDocument(expand: HardwareKeyboard.instance.isShiftPressed);
    } else {
      didMove = editContext.commonOps.moveCaretUp(expand: HardwareKeyboard.instance.isShiftPressed);
    }
  } else {
    if (CurrentPlatform.isApple && HardwareKeyboard.instance.isAltPressed) {
      didMove = editContext.commonOps.moveCaretDownstream(
        expand: HardwareKeyboard.instance.isShiftPressed,
        movementModifier: MovementModifier.paragraph,
      );
    } else if (CurrentPlatform.isApple && HardwareKeyboard.instance.isMetaPressed) {
      didMove = editContext.commonOps.moveSelectionToEndOfDocument(expand: HardwareKeyboard.instance.isShiftPressed);
    } else {
      //didMove = SECommonOps.moveCaretDownWithFolding(expand: HardwareKeyboard.instance.isShiftPressed, editor: editContext.editor);
      didMove = editContext.commonOps.moveCaretDown(expand: HardwareKeyboard.instance.isShiftPressed);
    }
  }

  return didMove ? ExecutionInstruction.haltExecution : ExecutionInstruction.continueExecution;
}