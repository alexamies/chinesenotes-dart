import 'dart:html';

const url = 'https://ntireader.org/dist/ntireader.json';

void main() async {
  try {
    String jsonString = await HttpRequest.getString(url);
    print('got ${jsonString.length}');
  } catch (e) {
    print('got an error ${e}');
    rethrow;
  }
}
