import 'dart:math';
import '../../../config.dart';

class IronyGeneratorController {
  IronyGeneratorController({Random? random})
      : irony = Ironies.ironicList[
          (random ?? Random()).nextInt(Ironies.ironicList.length),
        ];

  final String irony;
}
