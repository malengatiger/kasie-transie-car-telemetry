import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';

class AggregateWidget extends StatelessWidget {
  const AggregateWidget({
    super.key,
    required this.title,
    required this.number,
    this.color,
    this.padding,
    this.fontSize,
  });

  final String title;
  final int number;
  final Color? color;
  final double? padding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    double mPad = 12.0;
    double fSize = 12.0;
    Color fColor = Colors.red;
    if (padding != null) {
      mPad = padding!;
    }
    if (fontSize != null) {
      fSize = fontSize!;
    }
    if (color != null) {
      fColor = color!;
    }
    return SizedBox(
        width: 300,
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 100,
                child: Text(
                  title,
                  style: myTextStyle(fontSize: fSize, ),
                )),
            // gapW32,
            bd.Badge(
              badgeContent: Text(
                number.toString(),
                style: myTextStyle(color: Colors.white, ),
              ),
              badgeStyle: bd.BadgeStyle(
                  badgeColor: fColor, padding: EdgeInsets.all(mPad)),
            ),
          ],
        ));
  }
}
