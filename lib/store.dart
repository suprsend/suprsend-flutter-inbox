import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import './utils.dart';
import 'dart:convert' as convert;
import './api.dart';

// contains config related info
class SuprSendStoreCubit extends Cubit<Map<String, dynamic>> {
  SuprSendStoreCubit(String workspaceKey, String workspaceSecret,
      String? distinctId, String? subscriberId)
      : super({
          "config": {
            "workspaceKey": workspaceKey,
            "workspaceSecret": workspaceSecret,
            "distinctId": distinctId,
            "subscriberId": subscriberId,
            "collectorApiUrl": 'https://hub.suprsend.com',
            "apiUrl": 'https://inboxs.live',
            "pollingInterval": 20,
            "batchSize": 20,
            "batchTimeInterval": 30 * 24 * 60 * 60 * 1000,
            "storage_key": "_suprsend_inbox_storage"
          },
          "notifData": {
            "notifications": [],
            "unSeenCount": 0,
            "lastFetchedOn": null,
            "firstFetchedOn": null,
            "pollingTimerId": null
          },
          "rerender": true
        });

  List latestNotifications = [];

  void updateConfig(Map<String, dynamic> newData) {
    emit({
      ...state,
      "config": {...state["config"], ...newData},
      "rerender": false
    });
  }

  void updateNotifData(Map<String, dynamic> newData, {bool? updateRerender}) {
    emit({
      ...state,
      "notifData": {...state["notifData"], ...newData},
      "rerender": updateRerender
    });
  }

  void clearPolling() {
    final notifData = state["notifData"];
    final pollingTimerId = notifData["pollingTimerId"];
    updateNotifData({"lastFetchedOn": null, "firstFetchedOn": null});
    if (pollingTimerId != null) {
      pollingTimerId.cancel();
    }
  }

  fetchNotifications() async {
    final configData = state["config"];
    final notifData = state["notifData"];
    final isFirstCall = notifData["lastFetchedOn"] == null;
    final currentTimeStamp = epochNow();
    final prevMonthTimeStamp =
        currentTimeStamp - configData["batchTimeInterval"];
    final currentFetchFrom = notifData["lastFetchedOn"] ?? prevMonthTimeStamp;
    bool? hasNewData;
    try {
      final response = await ApiClient()
          .getNotifications(state["config"], currentFetchFrom, null);
      if (response.statusCode == 200) {
        final respData = convert.jsonDecode(response.body);
        print("UNREAD NOTIFICATIONS ${respData["unread"]}");
        hasNewData = isFirstCall == false && respData["results"].length > 0;
        final newNotifications = isFirstCall
            ? [...respData["results"]]
            : [...respData["results"], ...notifData["notifications"]];
        updateNotifData({
          "notifications": newNotifications,
          "unSeenCount": notifData["unSeenCount"] + respData["unread"],
          "lastFetchedOn": currentTimeStamp,
          "firstFetchedOn":
              isFirstCall ? prevMonthTimeStamp : notifData["firstFetchedOn"]
        }, updateRerender: hasNewData || isFirstCall);

        // for emitting new notification event
        if (hasNewData) {
          latestNotifications = [...respData["results"]];
        }

        // store in local storage
        final storageData = {
          "notifications": [...newNotifications.take(configData["batchSize"])],
          "subscriberId": configData["subscriberId"]
        };
        setClientNotificationStorage(configData["storage_key"], storageData);
      } else {
        print(
            'SUPRSEND: api error getting latest notifications ${response.statusCode}');
      }
    } catch (e) {
      print('SUPRSEND: error getting latest notifications ${e.toString()}');
    }
    var duration = Duration(seconds: configData["pollingInterval"]);
    var timerId = Timer(duration, () => {fetchNotifications()});
    updateNotifData({"pollingTimerId": timerId});
  }

  markClicked(String id) async {
    final notifData = state["notifData"];
    final configData = state["config"];
    final notifications = notifData["notifications"];
    var clickedNotification;
    notifications.forEach((item) {
      if (item["n_id"] == id) {
        clickedNotification = item;
      }
    });
    if (clickedNotification != null && clickedNotification["seen_on"] == null) {
      try {
        ApiClient().markNotificationClicked(state["config"], id);
        clickedNotification["seen_on"] = epochNow();
        updateNotifData({
          "notifications": [...notifications]
        }, updateRerender: true);

        // store in local storage
        final storageData = {
          "notifications": [...notifications.take(configData["batchSize"])],
          "subscriberId": configData["subscriberId"]
        };
        setClientNotificationStorage(configData["storage_key"], storageData);
      } catch (e) {
        print('SUPRSEND: error marking notification clicked ${e.toString()}');
      }
    }
  }

  markAllSeen() async {
    try {
      final res = await ApiClient().markBellClicked(state["config"]);
      if (res.statusCode == 200) {
        updateNotifData({"unSeenCount": 0}, updateRerender: true);
      } else {
        print(
            "SUPRSEND: api error marking all notifications seen ${res.statusCode}");
      }
    } catch (e) {
      print("SUPRSEND: error marking all notifications seen ${e.toString()}");
    }
  }
}
