import 'package:flutter/material.dart';
import 'package:me_fit/DB/hive_function.dart';
import 'package:me_fit/screens/steps/widgets/closeBtn.dart';
import 'package:me_fit/styles/styles.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:lottie/lottie.dart';

class StepsTrackerScreen extends StatefulWidget {
  final int userWeight;
  final num userHeightInMeters;
  const StepsTrackerScreen(
      {super.key, required this.userWeight, required this.userHeightInMeters});

  @override
  State<StepsTrackerScreen> createState() => StepsTrackerScreenState();
}

class StepsTrackerScreenState extends State<StepsTrackerScreen> {
  HiveDb db = HiveDb();
  late bool activityRecognitionGranded;
  late Stream<StepCount> _stepCountStream;
  int _stepCurrent = 0;
  int _totalSteps = 0;
  int _caloriesBurnedToday = 0;

  // initLastStep() async {}

  void onStepCount(StepCount event) async {
    db.setLastStep(event.steps);
    await db.setTotalSteps(event.steps);
    int lastStep = await db.getLastStep();
    if (mounted) {
      setState(() {
        _totalSteps = event.steps;
        _stepCurrent = lastStep - _totalSteps;
        print('lastStep - _totalSteps = _stepCurrent');
        print('$lastStep - $_totalSteps = $_stepCurrent');

        num stride = widget.userHeightInMeters * 0.414;
        num distance = stride * _stepCurrent;

        num time = distance / 3;
        double MET = 3.5;

        _caloriesBurnedToday =
            (time * MET * 3.5 * widget.userWeight / (200 * 60)).round();
      });
    }
    // when sensor value is 0
    if (_totalSteps == 0) {
      db.setLastStep(1);
      setState(() {
        _stepCurrent = lastStep - _totalSteps;
      });
    }
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
  }

  void initPlatformState() async {
    activityRecognitionGranded =
        await Permission.activityRecognition.request().isGranted;
    if (activityRecognitionGranded) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    } else {
      Permission.activityRecognition.request();
    }

    if (!mounted) return;
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
    _caloriesBurnedToday = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Steps tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 300,
              height: 300,
              child:
                  Lottie.asset('assets/lottie/Animation - 1695630496886.json'),
            ),
            const SizedBox(height: 50),
            Text(
              'Steps Taken today',
              style: kMedText.copyWith(color: Colors.black),
            ),
            Text(
              _stepCurrent.abs().toString(),
              style: const TextStyle(fontSize: 30),
            ),
            const Divider(
              height: 10,
              thickness: 0,
              color: Colors.white,
            ),
            Text(
                'calories burned : ${_caloriesBurnedToday.abs().round().toString()}'),
            const Spacer(),
            CloseBtnWidget(
                db: db,
                totalSteps: _totalSteps,
                stepCurrent: _stepCurrent,
                caloriesBurnedToday: _caloriesBurnedToday),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
