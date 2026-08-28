---
name: google-cloud-aiplatform-v1beta1-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_aiplatform_v1beta1
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `DatasetService` can be tested by injecting the
  fake `FakeDatasetService`.
- Code that uses `DeploymentResourcePoolService` can be tested by injecting the
  fake `FakeDeploymentResourcePoolService`.
- Code that uses `EndpointService` can be tested by injecting the
  fake `FakeEndpointService`.
- Code that uses `EvaluationService` can be tested by injecting the
  fake `FakeEvaluationService`.
- Code that uses `ExampleStoreService` can be tested by injecting the
  fake `FakeExampleStoreService`.
- Code that uses `ExtensionExecutionService` can be tested by injecting the
  fake `FakeExtensionExecutionService`.
- Code that uses `ExtensionRegistryService` can be tested by injecting the
  fake `FakeExtensionRegistryService`.
- Code that uses `FeatureOnlineStoreAdminService` can be tested by injecting the
  fake `FakeFeatureOnlineStoreAdminService`.
- Code that uses `FeatureOnlineStoreService` can be tested by injecting the
  fake `FakeFeatureOnlineStoreService`.
- Code that uses `FeatureRegistryService` can be tested by injecting the
  fake `FakeFeatureRegistryService`.
- Code that uses `FeaturestoreOnlineServingService` can be tested by injecting the
  fake `FakeFeaturestoreOnlineServingService`.
- Code that uses `FeaturestoreService` can be tested by injecting the
  fake `FakeFeaturestoreService`.
- Code that uses `GenAiCacheService` can be tested by injecting the
  fake `FakeGenAiCacheService`.
- Code that uses `GenAiTuningService` can be tested by injecting the
  fake `FakeGenAiTuningService`.
- Code that uses `IndexEndpointService` can be tested by injecting the
  fake `FakeIndexEndpointService`.
- Code that uses `IndexService` can be tested by injecting the
  fake `FakeIndexService`.
- Code that uses `JobService` can be tested by injecting the
  fake `FakeJobService`.
- Code that uses `LlmUtilityService` can be tested by injecting the
  fake `FakeLlmUtilityService`.
- Code that uses `MatchService` can be tested by injecting the
  fake `FakeMatchService`.
- Code that uses `MemoryBankService` can be tested by injecting the
  fake `FakeMemoryBankService`.
- Code that uses `MetadataService` can be tested by injecting the
  fake `FakeMetadataService`.
- Code that uses `MigrationService` can be tested by injecting the
  fake `FakeMigrationService`.
- Code that uses `ModelGardenService` can be tested by injecting the
  fake `FakeModelGardenService`.
- Code that uses `ModelMonitoringService` can be tested by injecting the
  fake `FakeModelMonitoringService`.
- Code that uses `ModelService` can be tested by injecting the
  fake `FakeModelService`.
- Code that uses `NotebookService` can be tested by injecting the
  fake `FakeNotebookService`.
- Code that uses `OnlineEvaluatorService` can be tested by injecting the
  fake `FakeOnlineEvaluatorService`.
- Code that uses `PersistentResourceService` can be tested by injecting the
  fake `FakePersistentResourceService`.
- Code that uses `PipelineService` can be tested by injecting the
  fake `FakePipelineService`.
- Code that uses `PredictionService` can be tested by injecting the
  fake `FakePredictionService`.
- Code that uses `ReasoningEngineExecutionService` can be tested by injecting the
  fake `FakeReasoningEngineExecutionService`.
- Code that uses `ReasoningEngineRuntimeRevisionService` can be tested by injecting the
  fake `FakeReasoningEngineRuntimeRevisionService`.
- Code that uses `ReasoningEngineService` can be tested by injecting the
  fake `FakeReasoningEngineService`.
- Code that uses `ScheduleService` can be tested by injecting the
  fake `FakeScheduleService`.
- Code that uses `SessionService` can be tested by injecting the
  fake `FakeSessionService`.
- Code that uses `SpecialistPoolService` can be tested by injecting the
  fake `FakeSpecialistPoolService`.
- Code that uses `TensorboardService` can be tested by injecting the
  fake `FakeTensorboardService`.
- Code that uses `VertexRagDataService` can be tested by injecting the
  fake `FakeVertexRagDataService`.
- Code that uses `VertexRagService` can be tested by injecting the
  fake `FakeVertexRagService`.
- Code that uses `VizierService` can be tested by injecting the
  fake `FakeVizierService`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_aiplatform_v1beta1/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_aiplatform_v1beta1/aiplatform.dart';
import 'package:google_cloud_aiplatform_v1beta1/testing.dart';

final fake = FakeFeatureOnlineStoreService(
  generateFetchAccessToken: (request) async {
    // Assert request contents here if needed.
    return GenerateFetchAccessTokenResponse();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_aiplatform_v1beta1/aiplatform.dart';
import 'package:google_cloud_aiplatform_v1beta1/testing.dart';

final class MyFakeFeatureOnlineStoreService extends FakeFeatureOnlineStoreService {
  @override
  Future<GenerateFetchAccessTokenResponse> generateFetchAccessToken(
    GenerateFetchAccessTokenRequest request,
  ) async {
    // Assert request contents here if needed.
    return GenerateFetchAccessTokenResponse();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_aiplatform_v1beta1/aiplatform.dart';
import 'package:google_cloud_aiplatform_v1beta1/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(FeatureOnlineStoreService service) async {
  // Application logic here.
  await service.generateFetchAccessToken(GenerateFetchAccessTokenRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeFeatureOnlineStoreService(
      generateFetchAccessToken: (request) async {
          // Assert request contents here.
          return GenerateFetchAccessTokenResponse();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
