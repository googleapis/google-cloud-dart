## (Deprecated) Google Cloud GAX

Google API eXtensions - common code for the Google Cloud client library
packages.

> [!WARNING]
>
> This package is deprecated, it's functionality has been migrated to
> [`package:google_cloud_rpc`](https://pub.dev/packages/google_cloud_rpc).

> [!NOTE]
> This package is currently experimental and published under the
> [labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order
> to solicit feedback.
>
> For packages in the labs.dart.dev publisher we generally plan to either
> graduate the package into a supported publisher (dart.dev, tools.dart.dev)
> after a period of feedback and iteration, or discontinue the package.
> These packages have a much higher expected rate of API and breaking changes.
>
> Your feedback is valuable and will help us evolve this package. For general
> feedback, suggestions, and comments, please file an issue in the
> [bug tracker](https://github.com/googleapis/google-cloud-dart/issues).

## Using

> [!TIP]
> This package contains common code for the Google Cloud client library packages.  
> It should rarely be used by application developers.  

This library allows you to send JSON messages over an HTTP connection.

For example:

```dart
import 'package:google_cloud_gax/gax.dart';
import 'package:googleapis_auth/auth_io.dart';

class AnalysisRequest implements JsonEncodable {
  final String text;

  AnalysisRequest(this.text);

  @override
  Object? toJson() => {
    'document': {'type': 'PLAIN_TEXT', 'content': text},
  };
}

void main() async {
  final httpClient = clientViaApiKey('<enter your API key here>');

  final serviceClient = ServiceClient(client: httpClient);
  final response = await serviceClient.post(
    Uri.https('language.googleapis.com', '/v2/documents:analyzeSentiment'),
    body: AnalysisRequest("I am very happy! Are you sad?"),
  );
  print(response);
  serviceClient.close();
}
```
