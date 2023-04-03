import 'package:flutter/Material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import '../provider/flash_provider.dart';

class BottomSheetWidget extends StatelessWidget {
  int inferenceTime;
  int preProcessingTime;
  double height;
  double width;
  double depth;
  BottomSheetWidget(this.inferenceTime, this.preProcessingTime, this.height,
      this.width, this.depth);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.20,
          //width: double.infinity,
          child: Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15))),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                            onTap: () {
                              context
                                  .read<FlashModeProvider>()
                                  .changeFlashModetoTorch();
                            },
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.deepOrange,
                              child: Icon(
                                Icons.highlight,
                                size: 35,
                                color: context
                                            .watch<FlashModeProvider>()
                                            .flashMode ==
                                        FlashMode.torch
                                    ? Colors.amber
                                    : Colors.black,
                              ),
                            )),
                        InkWell(
                            onTap: () {
                              context
                                  .read<FlashModeProvider>()
                                  .changeFlashModetoAuto();
                            },
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.deepOrange,
                              child: Icon(
                                Icons.flash_auto,
                                size: 35,
                                color: context
                                            .watch<FlashModeProvider>()
                                            .flashMode ==
                                        FlashMode.auto
                                    ? Colors.amber
                                    : Colors.black,
                              ),
                            )),
                      ],
                    ),
                    Divider(),
                    Text(
                      'Pre-Processing Time: $preProcessingTime ms',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Inference Time: $inferenceTime ms',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(top: 4)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Container(
                              child: Text(
                            'Height: $height',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          )),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Container(
                              child: Text(
                            'Width: $width',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          )),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Container(
                          child: Text(
                        'Depth: $depth',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
