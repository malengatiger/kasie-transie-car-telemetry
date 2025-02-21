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
    required this.isBadge,
  });

  final String title;
  final int number;
  final Color? color;
  final double? padding;
  final double? fontSize;
  final bool isBadge;

  @override
  Widget build(BuildContext context) {
    double mPad = 4.0;
    double fSize = 14.0;
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
        width: 240,
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            gapW32, gapW32,
            SizedBox(
                width: 100,
                child: Text(
                  title,
                  style: myTextStyle(
                    fontSize: fSize,
                  ),
                )),
            gapW4,
            isBadge
                ? bd.Badge(
                    badgeContent: Text(
                      number.toString(),
                      style: myTextStyle(color: Colors.white, fontSize: 12),
                    ),
                    badgeStyle: bd.BadgeStyle(
                        badgeColor: fColor, padding: EdgeInsets.all(mPad)),
                  )
                : Expanded(
                    child: SizedBox(
                    height: 36,
                    width: 140,
                    child: Text(
                      number.toString(),
                      style: myTextStyle(
                          color: fColor, fontSize: 24, weight: FontWeight.w900),
                    ),
                  ))
          ],
        ));
  }
}
