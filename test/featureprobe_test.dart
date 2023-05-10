import 'dart:io';

import 'package:featureprobe/featureprobe.dart';
import 'package:featureprobe/src/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('featureprobe construct', () async {
    var user = FPUser();
    var fp = FeatureProbe("https://featureprobe.io/server",
        "client-c818e854f483dda94e21d91889ab9557ecf0707d", user, 10 * 1000, 0);
    await fp.start();

    expect(fp.boolValue("key_not_exist", false), false);
    expect(fp.boolDetail("key_not_exist", false).value, false);
    expect(fp.boolDetail("key_not_exist", false).reason,
        "Toggle key_not_exist not found");
  });

  test('test event record', () {
    var recorder = EventRecorder("url", "key", 100);
    recorder.recordEvent(
        AccessEvent("access", 100, "user1", 1, "toggle_1", 1, 1, 1));

    recorder.recordEvent(
        AccessEvent("access", 101, "user1", 1, "toggle_1", 2, 1, 1));

    var access = recorder.access();

    expect(access.startTime, 100);
    expect(access.endTime, 101);
    expect(access.counters.length, 1);
    expect(access.counters['toggle_1']?.length, 2);
  });
}
