import 'dart:io';

import 'package:mockito/annotations.dart';

import 'package:featureprobe/featureprobe.dart';
import 'package:featureprobe/src/event.dart';
import 'package:flutter_test/flutter_test.dart';

@GenerateMocks([HttpClient])
void main() {
  test('featureprobe construct', () async {
    var user = FPUser();
    var fp = FeatureProbe(
        "https://featureprobe.io/server",
        "client-75d9182a7724b03d531178142b9031b831e464fe",
        user,
        10 * 1000,
        2000);
    await fp.start();

    expect(fp.boolValue("key_not_exist", false), false);
    expect(fp.boolDetail("key_not_exist", false).value, false);
    expect(fp.boolDetail("key_not_exist", false).reason,
        "Toggle key_not_exist not found");

    fp.boolValue('campaign_allow_list', false);
    await fp.stop();
  });

  test('test event record', () {
    var recorder = EventRecorder("url", "key", 100, "UA");
    recorder.recordEvent(AccessEvent(
        "access", 100, "user1", 1, "toggle_1", 1, 1, 1,
        trackAccessEvents: true));

    recorder.recordEvent(AccessEvent(
        "access", 101, "user1", 1, "toggle_1", 2, 1, 1,
        trackAccessEvents: true));

    var body = recorder.buildBody();

    expect(body?.pack.access.startTime, 100);
    expect(body?.pack.access.endTime, 101);
    expect(body?.pack.access.counters.length, 1);
    expect(body?.pack.access.counters['toggle_1']?.length, 2);
    expect(body?.pack.events.length, 2);

    recorder.recordEvent(AccessEvent(
        "access", 100, "user1", 1, "toggle_1", 1, 1, 1,
        trackAccessEvents: false));

    body = recorder.buildBody();

    expect(body?.pack.access.counters.length, 1);
    expect(body?.pack.events.length, 0);
  });
}
