SuprSend SDK for Flutter applications for integrating inbox functionality using flutter hooks

## Installation

**Step 1. Open your Flutter project’s pubspec.yaml file**
Add following line of code inside dependencies in `pubspec.yaml` file

```
dependencies:
  flutter:
  	sdk: flutter
  suprsend_flutter_inbox: "^0.0.1"
```

**Step 2. Run `flutter pub get` in the terminal**

```
$ flutter pub get
```

## Initialization

Enclose your Material App inside SuprSendProvider and pass workspace key, workspace secret, distinct_id, subscriber_id.

```
import 'package:suprsend_flutter_inbox/main.dart';

SuprSendProvider(
    workspaceKey: <your workspace key>,
    workspaceSecret:  <your workspace secret>,
    distinctId: distinct_id,
    subscriberId: subscriber_id,
    child: YourAppComponent()
)
```

NOTE: Only inside SuprSendProvider you will be able to call suprsend hooks.

## Usage

### useBell

This hook is used to get unSeenCount, markAllSeen. markAllSeen should be called when user clicks on bell icon so that notification count can be reset to 0.

```
import 'package:suprsend_flutter_inbox/main.dart';

final bellData = useBell();
```

```
bellData structure:

{
  "unSeenCount": int,
  "markAllSeen": ()=>void
}
```

### useNotifications

This hook is used to get notifications list, unSeenCount, markAllSeen, markClicked. markClicked needs to be called when user clics on any of the notification item

```
import 'package:suprsend_flutter_inbox/main.dart';

final notifData = useNotifications();
```

```
notifData structure:

{
  "notifications": List<Noticication>,
  "unSeenCount": int,
  "markAllSeen": ()=>void
  "markClicked":(notification_id)=>void
}

Noticication structure:

{
  "created_on": int,
  "seen_on": int,
  "message": {
    "header": string,
    "text": string,
    "url": string,
    "actions:[
      {
        "name": string,
        "url": string
      }
    ]
  },
  "n_id": string
}
```

## License

MIT © [https://github.com/suprsend](https://github.com/suprsend)

```

```
