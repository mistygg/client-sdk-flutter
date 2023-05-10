import 'dart:io';

class EventRecorder {
  String eventsUrl;
  String sdkKey;
  int flushInterval;
  late List<Event> events;
  late HttpClient httpClient;

  EventRecorder(this.eventsUrl, this.sdkKey, this.flushInterval) {
    events = [];
    httpClient = HttpClient();
  }

  void recordEvent(Event event) {
    events.add(event);
  }

  void flush() {}

  Access access() {
    int? startTime;
    int? endTime;
    Map<String, List<Counter>> counters = {};

    for (var event in events) {
      if (event.kind == "access") {
        if (startTime == null || startTime > event.time) {
          startTime = event.time;
        }
        if (endTime == null || endTime < event.time) {
          endTime = event.time;
        }

        var e = event as AccessEvent;
        var counter = counters[e.key];
        if (counter == null) {
          counters[e.key] = [Counter(e.value, e.version, e.variationIndex, 1)];
        } else {
          var added = false;
          for (var c in counter) {
            if (c.index == e.variationIndex &&
                c.version == e.version &&
                c.value == e.value) {
              c.count++;
              added = true;
            }
          }

          if (!added) {
            counter.add(Counter(e.value, e.version, e.variationIndex, 1));
          }
        }
      }
    }

    return Access(startTime!, endTime!, counters);
  }
}

class PostBody {
  Access access;
  List<Event> events;

  PostBody(this.access, this.events);

  Map toJson() => {
        'access': access,
        'events': events,
      };
}

class Access {
  int startTime;
  int endTime;
  Map<String, List<Counter>> counters;

  Access(this.startTime, this.endTime, this.counters);

  Map toJson() =>
      {'startTime': startTime, 'endTime': endTime, 'counters': counters};
}

class Counter {
  dynamic value;
  int? version;
  late int index;
  late int count;

  Counter(this.value, this.version, this.index, this.count);

  Map toJson() =>
      {'value': value, 'version': version, 'index': index, 'count': count};
}

abstract class Event {
  String kind;
  int time;
  String user;
  dynamic value;

  Event(this.kind, this.time, this.user, this.value);
}

class AccessEvent implements Event {
  @override
  String kind;
  @override
  int time;
  @override
  String user;
  @override
  dynamic value;

  String key;
  int variationIndex;
  int ruleIndex;
  int version;

  AccessEvent(this.kind, this.time, this.user, this.value, this.key,
      this.variationIndex, this.ruleIndex, this.version);

  Map toJson() => {
        'kind': kind,
        'time': time,
        'user': user,
        'value': value,
        'key': key,
        'variationIndex': variationIndex,
        'rulendex': ruleIndex,
        'version': version
      };
}

class DebugEvent implements Event {
  @override
  String kind;
  @override
  int time;
  @override
  String user;
  @override
  dynamic value;

  String key;
  dynamic userDetail;
  int variationIndex;
  int ruleIndex;
  int version;
  String reason;

  DebugEvent(
      this.kind,
      this.time,
      this.user,
      this.key,
      this.value,
      this.userDetail,
      this.variationIndex,
      this.ruleIndex,
      this.version,
      this.reason);

  Map toJson() => {
        'kind': kind,
        'time': time,
        'user': user,
        'userDetail': userDetail,
        'value': value,
        'key': key,
        'variationIndex': variationIndex,
        'rulendex': ruleIndex,
        'version': version,
        'reason': reason,
      };
}

class CustomEvent implements Event {
  @override
  String kind;
  @override
  int time;
  @override
  String user;
  @override
  dynamic value;

  String name;

  CustomEvent(this.kind, this.time, this.user, this.value, this.name);

  Map toJson() =>
      {'kind': kind, 'time': time, 'user': user, 'name': name, 'value': value};
}
