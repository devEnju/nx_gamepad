import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  const ItemCard(
    this.id,
    this.amount,
    this.pixel, {
    this.color,
    this.onTap,
    super.key,
  });

  final int id;
  final int amount;
  final double pixel;
  final Color? color;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    Widget item = Container();
    List<Widget> description = [];

    if (id != 0) {
      item = Container(
        margin: EdgeInsets.all(pixel),
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('images/$id.png'),
            filterQuality: FilterQuality.none,
          ),
        ),
      );

      if (amount > 1) {
        int digit1 = amount ~/ 10;
        int digit2 = amount % 10;

        if (digit1 != 0) {
          description.add(Image(
            width: pixel * 5,
            height: pixel * 7,
            fit: BoxFit.fill,
            image: AssetImage('font/$digit1.png'),
            filterQuality: FilterQuality.none,
          ));
          description.add(SizedBox(width: pixel));
        }

        description.add(Image(
          width: pixel * 5,
          height: pixel * 7,
          fit: BoxFit.fill,
          image: AssetImage('font/$digit2.png'),
          filterQuality: FilterQuality.none,
        ));
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: pixel * 18,
        height: pixel * 18,
        decoration: BoxDecoration(
          color: color,
          image: const DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('images/frame.png'),
            filterQuality: FilterQuality.none,
          ),
        ),
        child: Stack(
          children: [
            item,
            Container(
              alignment: Alignment.bottomRight,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color.fromARGB(255, 63, 63, 63),
                  BlendMode.srcIn,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: description,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(pixel),
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: description,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
