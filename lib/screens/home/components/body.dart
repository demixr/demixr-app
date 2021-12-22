import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:demixr_app/components/buttons.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin:
            const EdgeInsets.only(top: 125, left: 20, right: 20, bottom: 20),
        height: double.maxFinite,
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Demixr',
                  style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.normal,
                      color: ColorPalette.primary),
                ),
                Text(
                  'Music demixing in your pocket',
                  style: TextStyle(fontSize: 14),
                )
              ],
            ),
            Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Library',
                      style: TextStyle(
                          color: ColorPalette.onSurface, fontSize: 36),
                    ),
                    SizedBox(
                      height: 450,
                      width: double.maxFinite,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            child: Image.asset('assets/images/astronaut.png'),
                          ),
                          const SizedBox(
                            width: 200,
                            child: Text(
                              'Your library is empty at the moment',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: ColorPalette.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.maxFinite,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Button(
                        'Unmix a new song',
                        icon: Icon(
                          Icons.add,
                          color: ColorPalette.onPrimary,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ));
  }
}
