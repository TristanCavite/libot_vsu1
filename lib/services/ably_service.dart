import 'package:ably_flutter/ably_flutter.dart' as ably;

class AblyService {
  static ably.Realtime? _client;

  static Future<void> initialize(String apiKey) async {
    _client = ably.Realtime(
      options: ably.ClientOptions.fromKey(apiKey),
    );
  }

  static ably.RealtimeChannel getChannel(String channelName) {
    return _client!.channels.get(channelName);
  }
}
