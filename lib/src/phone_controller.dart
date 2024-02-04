import 'package:flutter/material.dart';
import 'package:phone_form_field/src/validation/allowed_characters.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class PhoneController extends ChangeNotifier {
  final bool shouldFormat;

  /// focus node of the national number
  // final FocusNode focusNode;
  final PhoneNumber initialValue;
  PhoneNumber _value;
  PhoneNumber get value => _value;

  set value(PhoneNumber phoneNumber) {
    _value = phoneNumber;
    changeCountry(_value.isoCode);
    changeText(_value.nsn);
  }

  /// text editing controller of the nsn ( where user types the phone number )
  late final TextEditingController nationalNumberController;

  PhoneController({
    this.initialValue = const PhoneNumber(isoCode: IsoCode.US, nsn: ''),
    this.shouldFormat = true,
  })  : _value = initialValue,
        nationalNumberController =
            TextEditingController(text: initialValue.getFormattedNsn());

  reset() {
    _value = initialValue;
    changeCountry(_value.isoCode);
    changeText(_value.nsn);
    notifyListeners();
  }

  changeCountry(IsoCode isoCode) {
    _value = PhoneNumber.parse(
      _value.nsn,
      destinationCountry: isoCode,
    );
    notifyListeners();
  }

  changeText(String? text) {
    text = text ?? '';
    var newText = text;

    // if starts with + then we parse the whole number
    final startsWithPlus =
        text.startsWith(RegExp('[${AllowedCharacters.plus}]'));

    if (startsWithPlus) {
      final phoneNumber = _tryParseWithPlus(text);
      // if we could parse the phone number we can change the value inside
      // the national number field to remove the "+ country dial code"
      if (phoneNumber != null) {
        _value = phoneNumber;
        newText = _value.getFormattedNsn();
      }
    } else {
      final phoneNumber = PhoneNumber.parse(
        text,
        destinationCountry: _value.isoCode,
      );
      _value = phoneNumber;
      newText = phoneNumber.getFormattedNsn();
    }
    nationalNumberController.value = TextEditingValue(
      text: newText,
      selection: computeSelection(text, newText),
    );

    notifyListeners();
  }

  /// When the cursor is at the end of the text we need to preserve that.
  /// Since there is formatting going on we need to explicitely do it.
  /// We don't want to do it in the middle because the user might have
  /// used arrow keys to move inside the text.
  TextSelection computeSelection(String originalText, String newText) {
    final currentSelectionOffset =
        nationalNumberController.selection.extentOffset;
    final isCursorAtEnd = currentSelectionOffset == originalText.length;
    var offset = currentSelectionOffset;

    if (isCursorAtEnd || currentSelectionOffset >= newText.length) {
      offset = newText.length;
    }
    return TextSelection.fromPosition(
      TextPosition(offset: offset),
    );
  }

  PhoneNumber? _tryParseWithPlus(String text) {
    try {
      return PhoneNumber.parse(text);
      // parsing "+", a country code won't be found
    } on PhoneNumberException {
      return null;
    }
  }

  selectNationalNumber() {
    nationalNumberController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: nationalNumberController.value.text.length,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    nationalNumberController.dispose();
    super.dispose();
  }
}
