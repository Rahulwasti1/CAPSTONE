import 'package:flutter/material.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 25),
        child: Column(
          children: [
            SafeArea(
                child: Row(
              children: [
                SizedBox(height: 80),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.brown),
                  height: 50,
                  width: 50,
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 49),
                      child: Text(" 👋 Hello!"),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        "Rahul Wasti",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                SizedBox(width: 110),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        print("Notification Button Clicked");
                      },
                      style: ElevatedButton.styleFrom(
                          elevation: 0.1,
                          backgroundColor: Colors.white,
                          minimumSize: Size(10, 40),
                          shape: CircleBorder()),
                      child: Icon(Icons.notifications,
                          size: 20,
                          color: const Color.fromARGB(255, 31, 31, 30))),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search), hintText: "Search"),
                    )
                  ],
                )
              ],
            )),
          ],
        ),
      ),
    );
  }
}
