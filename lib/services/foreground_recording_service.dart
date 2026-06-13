import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startPanicRecordingForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(PanicRecordingTaskHandler());
}

class PanicRecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Panic recording active',
      notificationText: 'Audio evidence is being recorded in background',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Panic recording active',
      notificationText: 'Audio evidence is still recording',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

class ForegroundRecordingService {
  Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'panic_recording_service',
        channelName: 'Panic Recording Service',
        channelDescription:
            'Keeps panic audio recording active in the background.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> requestPermissions() async {
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<void> startService() async {
    await requestPermissions();
    await initialize();

    if (Platform.isAndroid) {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          serviceId: 911,
          notificationTitle: 'Panic recording active',
          notificationText: 'Audio evidence is being recorded in background',
          notificationIcon: null,
          notificationInitialRoute: '/',
          serviceTypes: [
            ForegroundServiceTypes.microphone,
          ],
          callback: startPanicRecordingForegroundCallback,
        );
      }
    }
  }

  Future<void> stopService() async {
    if (Platform.isAndroid) {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    }
  }
}
