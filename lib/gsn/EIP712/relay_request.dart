import 'forward_request.dart';
import 'relay_data.dart';

class RelayRequest {
  ForwardRequest request;
  RelayData relayData;

  RelayRequest({required this.request, required this.relayData});
  List<dynamic> toJson() {
    return [request.toJson(), relayData.toJson()];
  }

  Map<String, dynamic> toMap() {
    return {"request": request.toMap(), "relayData": relayData.toMap()};
  }
}
