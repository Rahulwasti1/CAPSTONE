import 'package:flutter/material.dart';

class DetailAppBar extends StatefulWidget {
  const DetailAppBar({super.key});

  @override
  State<DetailAppBar> createState() => _DetailAppBarState();
}

class _DetailAppBarState extends State<DetailAppBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Spacer(),
          IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 242, 240, 240),
                  padding: const EdgeInsets.all(15)),
              onPressed: () {},
              icon: Icon(Icons.arrow_back_ios)),
          const SizedBox(width: 230),
          SizedBox(width: 10),
          IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 242, 240, 240),
                  padding: const EdgeInsets.all(15)),
              onPressed: () {},
              icon: Icon(Icons.favorite_border_outlined))
        ],
      ),
    );
  }
}
