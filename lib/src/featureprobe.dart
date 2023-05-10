import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'user.dart';
import 'dart:developer';

class FeatureProbe {
  Map<String, Toggle>? toggles;
  late FPUser user;
  late String sdkKey;
  late HttpClient httpClient;
  late Timer syncTimer;

  String? togglesUrl;
  String? eventsUrl;
  String? realtimeUrl;

  int refreshInterval;
  int waitTimeout;

  FeatureProbe(
    String remoteUrl,
    this.sdkKey,
    this.user,
    this.refreshInterval,
    this.waitTimeout, {
    this.togglesUrl,
    this.eventsUrl,
    this.realtimeUrl,
  }) {
    togglesUrl ??= "$remoteUrl/api/client-sdk/toggles";
    eventsUrl ??= "$remoteUrl/api/events";
    realtimeUrl ??= "$remoteUrl/realtime";

    httpClient = HttpClient();
  }

  Future<void> start() async {
    if (waitTimeout != 0) {
      await syncOnce().timeout(Duration(milliseconds: waitTimeout));
    }

    var d = Duration(milliseconds: refreshInterval);
    syncTimer = Timer.periodic(d, (timer) async {
      //code to run on every 5 seconds
      await syncOnce();
    });
  }

  void stop() {
    // TODO: flush events
    syncTimer.cancel();
  }

  bool boolValue(String key, bool defaultValue) {
    return value<bool>(key, defaultValue);
  }

  int numberValue(String key, int defaultValue) {
    return value<int>(key, defaultValue);
  }

  String stringValue(String key, String defaultValue) {
    return value<String>(key, defaultValue);
  }

  dynamic jsonValue(String key, dynamic defaultValue) {
    return value<dynamic>(key, defaultValue);
  }

  T value<T>(String key, dynamic defaultValue) {
    //TODO: record event

    var toggle = toggles?[key];
    if (toggle != null) {
      return tryCast<T>(toggle.value) ?? defaultValue;
    } else {
      return defaultValue;
    }
  }

  FPDetail<bool> boolDetail(String key, bool defaultValue) {
    return detail<bool>(key, defaultValue);
  }

  FPDetail<int> numberDetail(String key, int defaultValue) {
    return detail<int>(key, defaultValue);
  }

  FPDetail<String> stringDetail(String key, String defaultValue) {
    return detail<String>(key, defaultValue);
  }

  FPDetail<dynamic> jsonDetail(String key, dynamic defaultValue) {
    return detail<dynamic>(key, defaultValue);
  }

  FPDetail<T> detail<T>(String key, T defaultValue) {
    //TODO: record event

    var toggle = toggles?[key];
    T v = defaultValue;
    String? r;
    if (toggle != null) {
      var value = tryCast<T>(toggle.value);
      if (value == null) {
        r = "Value type mismatch";
      } else {
        v = value;
        r = toggle.reason;
      }
    } else {
      r = "Toggle $key not found";
    }

    return FPDetail<T>(
        value: v,
        reason: r,
        ruleIndex: toggle?.ruleIndex,
        variationIndex: toggle?.variationIndex,
        version: toggle?.version);
  }

  Future<void> syncOnce() async {
    log("syncOnce");
    String credentials = jsonEncode(user);
    Codec<String, String> stringToBase64Url = utf8.fuse(base64Url);
    String encoded = stringToBase64Url.encode(credentials);

    var url = Uri.parse(togglesUrl!).replace(queryParameters: {
      'user': encoded,
    });

    HttpClientRequest request = await httpClient.getUrl(url);
    request.headers.add(HttpHeaders.authorizationHeader, sdkKey);
    request.headers.add(HttpHeaders.userAgentHeader, "flutter/0.1.0");
    request.headers.add(HttpHeaders.contentTypeHeader, "application/json");

    HttpClientResponse response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      var body = await response.transform(utf8.decoder).join();
      Map<String, dynamic> json = jsonDecode(body);
      toggles = json.map((key, value) => MapEntry(key, Toggle.fromJson(value)));
    } else {
      log("Error: ${response.statusCode}");
    }
  }
}

class Toggle {
  late dynamic value;
  int? ruleIndex;
  int? variationIndex;
  int? version;
  late String reason;

  Toggle(
      {this.value,
      this.ruleIndex,
      this.variationIndex,
      this.version,
      required this.reason});

  factory Toggle.fromJson(Map<String, dynamic> parsedJson) {
    return Toggle(
        value: parsedJson['value'],
        ruleIndex: parsedJson['ruleIndex'],
        variationIndex: parsedJson['variationIndex'],
        version: parsedJson['version'],
        reason: parsedJson['reason']);
  }
}

class FPDetail<T> {
  late T value;
  int? ruleIndex;
  int? variationIndex;
  int? version;
  late String reason;

  FPDetail(
      {required this.value,
      this.ruleIndex,
      this.variationIndex,
      this.version,
      required this.reason});

  factory FPDetail.fromToggle(Toggle toggle) {
    return FPDetail(
        value: toggle.value,
        ruleIndex: toggle.ruleIndex,
        variationIndex: toggle.variationIndex,
        version: toggle.version,
        reason: toggle.reason);
  }
}

T? tryCast<T>(dynamic value) {
  try {
    return (value as T);
  } on TypeError catch (_) {
    return null;
  }
}
