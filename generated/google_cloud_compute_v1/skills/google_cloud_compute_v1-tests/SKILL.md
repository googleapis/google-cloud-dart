---
name: google-cloud-compute-v1-tests
description: >-
  Use this skill when writing tests for code that uses
  package:google_cloud_compute_v1
---

## Testing with Fakes

Most unit tests should use fakes instead of making network requests to Google
services.

- Code that uses `AcceleratorTypes` can be tested by injecting the
  fake `FakeAcceleratorTypes`.
- Code that uses `Addresses` can be tested by injecting the
  fake `FakeAddresses`.
- Code that uses `Advice` can be tested by injecting the
  fake `FakeAdvice`.
- Code that uses `Autoscalers` can be tested by injecting the
  fake `FakeAutoscalers`.
- Code that uses `BackendBuckets` can be tested by injecting the
  fake `FakeBackendBuckets`.
- Code that uses `BackendServices` can be tested by injecting the
  fake `FakeBackendServices`.
- Code that uses `CrossSiteNetworks` can be tested by injecting the
  fake `FakeCrossSiteNetworks`.
- Code that uses `DiskTypes` can be tested by injecting the
  fake `FakeDiskTypes`.
- Code that uses `Disks` can be tested by injecting the
  fake `FakeDisks`.
- Code that uses `ExternalVpnGateways` can be tested by injecting the
  fake `FakeExternalVpnGateways`.
- Code that uses `FirewallPolicies` can be tested by injecting the
  fake `FakeFirewallPolicies`.
- Code that uses `Firewalls` can be tested by injecting the
  fake `FakeFirewalls`.
- Code that uses `ForwardingRules` can be tested by injecting the
  fake `FakeForwardingRules`.
- Code that uses `FutureReservations` can be tested by injecting the
  fake `FakeFutureReservations`.
- Code that uses `GlobalAddresses` can be tested by injecting the
  fake `FakeGlobalAddresses`.
- Code that uses `GlobalForwardingRules` can be tested by injecting the
  fake `FakeGlobalForwardingRules`.
- Code that uses `GlobalNetworkEndpointGroups` can be tested by injecting the
  fake `FakeGlobalNetworkEndpointGroups`.
- Code that uses `GlobalOperations` can be tested by injecting the
  fake `FakeGlobalOperations`.
- Code that uses `GlobalOrganizationOperations` can be tested by injecting the
  fake `FakeGlobalOrganizationOperations`.
- Code that uses `GlobalPublicDelegatedPrefixes` can be tested by injecting the
  fake `FakeGlobalPublicDelegatedPrefixes`.
- Code that uses `GlobalVmExtensionPolicies` can be tested by injecting the
  fake `FakeGlobalVmExtensionPolicies`.
- Code that uses `HealthChecks` can be tested by injecting the
  fake `FakeHealthChecks`.
- Code that uses `Hosts` can be tested by injecting the
  fake `FakeHosts`.
- Code that uses `ImageFamilyViews` can be tested by injecting the
  fake `FakeImageFamilyViews`.
- Code that uses `Images` can be tested by injecting the
  fake `FakeImages`.
- Code that uses `InstanceGroupManagerResizeRequests` can be tested by injecting the
  fake `FakeInstanceGroupManagerResizeRequests`.
- Code that uses `InstanceGroupManagers` can be tested by injecting the
  fake `FakeInstanceGroupManagers`.
- Code that uses `InstanceGroups` can be tested by injecting the
  fake `FakeInstanceGroups`.
- Code that uses `InstanceSettingsService` can be tested by injecting the
  fake `FakeInstanceSettingsService`.
- Code that uses `InstanceTemplates` can be tested by injecting the
  fake `FakeInstanceTemplates`.
- Code that uses `Instances` can be tested by injecting the
  fake `FakeInstances`.
- Code that uses `InstantSnapshotGroups` can be tested by injecting the
  fake `FakeInstantSnapshotGroups`.
- Code that uses `InstantSnapshots` can be tested by injecting the
  fake `FakeInstantSnapshots`.
- Code that uses `InterconnectAttachmentGroups` can be tested by injecting the
  fake `FakeInterconnectAttachmentGroups`.
- Code that uses `InterconnectAttachments` can be tested by injecting the
  fake `FakeInterconnectAttachments`.
- Code that uses `InterconnectGroups` can be tested by injecting the
  fake `FakeInterconnectGroups`.
- Code that uses `InterconnectLocations` can be tested by injecting the
  fake `FakeInterconnectLocations`.
- Code that uses `InterconnectRemoteLocations` can be tested by injecting the
  fake `FakeInterconnectRemoteLocations`.
- Code that uses `Interconnects` can be tested by injecting the
  fake `FakeInterconnects`.
- Code that uses `LicenseCodes` can be tested by injecting the
  fake `FakeLicenseCodes`.
- Code that uses `Licenses` can be tested by injecting the
  fake `FakeLicenses`.
- Code that uses `MachineImages` can be tested by injecting the
  fake `FakeMachineImages`.
- Code that uses `MachineTypes` can be tested by injecting the
  fake `FakeMachineTypes`.
- Code that uses `NetworkAttachments` can be tested by injecting the
  fake `FakeNetworkAttachments`.
- Code that uses `NetworkEdgeSecurityServices` can be tested by injecting the
  fake `FakeNetworkEdgeSecurityServices`.
- Code that uses `NetworkEndpointGroups` can be tested by injecting the
  fake `FakeNetworkEndpointGroups`.
- Code that uses `NetworkFirewallPolicies` can be tested by injecting the
  fake `FakeNetworkFirewallPolicies`.
- Code that uses `NetworkProfiles` can be tested by injecting the
  fake `FakeNetworkProfiles`.
- Code that uses `Networks` can be tested by injecting the
  fake `FakeNetworks`.
- Code that uses `NodeGroups` can be tested by injecting the
  fake `FakeNodeGroups`.
- Code that uses `NodeTemplates` can be tested by injecting the
  fake `FakeNodeTemplates`.
- Code that uses `NodeTypes` can be tested by injecting the
  fake `FakeNodeTypes`.
- Code that uses `OrganizationSecurityPolicies` can be tested by injecting the
  fake `FakeOrganizationSecurityPolicies`.
- Code that uses `PacketMirrorings` can be tested by injecting the
  fake `FakePacketMirrorings`.
- Code that uses `PreviewFeatures` can be tested by injecting the
  fake `FakePreviewFeatures`.
- Code that uses `Projects` can be tested by injecting the
  fake `FakeProjects`.
- Code that uses `PublicAdvertisedPrefixes` can be tested by injecting the
  fake `FakePublicAdvertisedPrefixes`.
- Code that uses `PublicDelegatedPrefixes` can be tested by injecting the
  fake `FakePublicDelegatedPrefixes`.
- Code that uses `RegionAutoscalers` can be tested by injecting the
  fake `FakeRegionAutoscalers`.
- Code that uses `RegionBackendBuckets` can be tested by injecting the
  fake `FakeRegionBackendBuckets`.
- Code that uses `RegionBackendServices` can be tested by injecting the
  fake `FakeRegionBackendServices`.
- Code that uses `RegionCommitments` can be tested by injecting the
  fake `FakeRegionCommitments`.
- Code that uses `RegionCompositeHealthChecks` can be tested by injecting the
  fake `FakeRegionCompositeHealthChecks`.
- Code that uses `RegionDiskTypes` can be tested by injecting the
  fake `FakeRegionDiskTypes`.
- Code that uses `RegionDisks` can be tested by injecting the
  fake `FakeRegionDisks`.
- Code that uses `RegionHealthAggregationPolicies` can be tested by injecting the
  fake `FakeRegionHealthAggregationPolicies`.
- Code that uses `RegionHealthCheckServices` can be tested by injecting the
  fake `FakeRegionHealthCheckServices`.
- Code that uses `RegionHealthChecks` can be tested by injecting the
  fake `FakeRegionHealthChecks`.
- Code that uses `RegionHealthSources` can be tested by injecting the
  fake `FakeRegionHealthSources`.
- Code that uses `RegionInstanceGroupManagerResizeRequests` can be tested by injecting the
  fake `FakeRegionInstanceGroupManagerResizeRequests`.
- Code that uses `RegionInstanceGroupManagers` can be tested by injecting the
  fake `FakeRegionInstanceGroupManagers`.
- Code that uses `RegionInstanceGroups` can be tested by injecting the
  fake `FakeRegionInstanceGroups`.
- Code that uses `RegionInstanceTemplates` can be tested by injecting the
  fake `FakeRegionInstanceTemplates`.
- Code that uses `RegionInstances` can be tested by injecting the
  fake `FakeRegionInstances`.
- Code that uses `RegionInstantSnapshotGroups` can be tested by injecting the
  fake `FakeRegionInstantSnapshotGroups`.
- Code that uses `RegionInstantSnapshots` can be tested by injecting the
  fake `FakeRegionInstantSnapshots`.
- Code that uses `RegionNetworkEndpointGroups` can be tested by injecting the
  fake `FakeRegionNetworkEndpointGroups`.
- Code that uses `RegionNetworkFirewallPolicies` can be tested by injecting the
  fake `FakeRegionNetworkFirewallPolicies`.
- Code that uses `RegionNotificationEndpoints` can be tested by injecting the
  fake `FakeRegionNotificationEndpoints`.
- Code that uses `RegionOperations` can be tested by injecting the
  fake `FakeRegionOperations`.
- Code that uses `RegionSecurityPolicies` can be tested by injecting the
  fake `FakeRegionSecurityPolicies`.
- Code that uses `RegionSnapshotSettings` can be tested by injecting the
  fake `FakeRegionSnapshotSettings`.
- Code that uses `RegionSnapshots` can be tested by injecting the
  fake `FakeRegionSnapshots`.
- Code that uses `RegionSslCertificates` can be tested by injecting the
  fake `FakeRegionSslCertificates`.
- Code that uses `RegionSslPolicies` can be tested by injecting the
  fake `FakeRegionSslPolicies`.
- Code that uses `RegionTargetHttpProxies` can be tested by injecting the
  fake `FakeRegionTargetHttpProxies`.
- Code that uses `RegionTargetHttpsProxies` can be tested by injecting the
  fake `FakeRegionTargetHttpsProxies`.
- Code that uses `RegionTargetTcpProxies` can be tested by injecting the
  fake `FakeRegionTargetTcpProxies`.
- Code that uses `RegionUrlMaps` can be tested by injecting the
  fake `FakeRegionUrlMaps`.
- Code that uses `RegionZones` can be tested by injecting the
  fake `FakeRegionZones`.
- Code that uses `Regions` can be tested by injecting the
  fake `FakeRegions`.
- Code that uses `ReliabilityRisks` can be tested by injecting the
  fake `FakeReliabilityRisks`.
- Code that uses `ReservationBlocks` can be tested by injecting the
  fake `FakeReservationBlocks`.
- Code that uses `ReservationSlots` can be tested by injecting the
  fake `FakeReservationSlots`.
- Code that uses `ReservationSubBlocks` can be tested by injecting the
  fake `FakeReservationSubBlocks`.
- Code that uses `Reservations` can be tested by injecting the
  fake `FakeReservations`.
- Code that uses `ResourcePolicies` can be tested by injecting the
  fake `FakeResourcePolicies`.
- Code that uses `RolloutPlans` can be tested by injecting the
  fake `FakeRolloutPlans`.
- Code that uses `Rollouts` can be tested by injecting the
  fake `FakeRollouts`.
- Code that uses `Routers` can be tested by injecting the
  fake `FakeRouters`.
- Code that uses `Routes` can be tested by injecting the
  fake `FakeRoutes`.
- Code that uses `SecurityPolicies` can be tested by injecting the
  fake `FakeSecurityPolicies`.
- Code that uses `ServiceAttachments` can be tested by injecting the
  fake `FakeServiceAttachments`.
- Code that uses `SnapshotSettingsService` can be tested by injecting the
  fake `FakeSnapshotSettingsService`.
- Code that uses `Snapshots` can be tested by injecting the
  fake `FakeSnapshots`.
- Code that uses `SslCertificates` can be tested by injecting the
  fake `FakeSslCertificates`.
- Code that uses `SslPolicies` can be tested by injecting the
  fake `FakeSslPolicies`.
- Code that uses `StoragePoolTypes` can be tested by injecting the
  fake `FakeStoragePoolTypes`.
- Code that uses `StoragePools` can be tested by injecting the
  fake `FakeStoragePools`.
- Code that uses `Subnetworks` can be tested by injecting the
  fake `FakeSubnetworks`.
- Code that uses `TargetGrpcProxies` can be tested by injecting the
  fake `FakeTargetGrpcProxies`.
- Code that uses `TargetHttpProxies` can be tested by injecting the
  fake `FakeTargetHttpProxies`.
- Code that uses `TargetHttpsProxies` can be tested by injecting the
  fake `FakeTargetHttpsProxies`.
- Code that uses `TargetInstances` can be tested by injecting the
  fake `FakeTargetInstances`.
- Code that uses `TargetPools` can be tested by injecting the
  fake `FakeTargetPools`.
- Code that uses `TargetSslProxies` can be tested by injecting the
  fake `FakeTargetSslProxies`.
- Code that uses `TargetTcpProxies` can be tested by injecting the
  fake `FakeTargetTcpProxies`.
- Code that uses `TargetVpnGateways` can be tested by injecting the
  fake `FakeTargetVpnGateways`.
- Code that uses `UrlMaps` can be tested by injecting the
  fake `FakeUrlMaps`.
- Code that uses `VpnGateways` can be tested by injecting the
  fake `FakeVpnGateways`.
- Code that uses `VpnTunnels` can be tested by injecting the
  fake `FakeVpnTunnels`.
- Code that uses `WireGroups` can be tested by injecting the
  fake `FakeWireGroups`.
- Code that uses `ZoneOperations` can be tested by injecting the
  fake `FakeZoneOperations`.
- Code that uses `ZoneVmExtensionPolicies` can be tested by injecting the
  fake `FakeZoneVmExtensionPolicies`.
- Code that uses `Zones` can be tested by injecting the
  fake `FakeZones`.

Import the fakes from the testing library:

```dart
import 'package:google_cloud_compute_v1/testing.dart';
```

### Option A: Using Constructor Closures (Recommended)

You can inject behavior by passing optional function callbacks to the fake's
constructor. Methods that are not provided will throw an `UnsupportedError`.

```dart
import 'package:google_cloud_compute_v1/compute.dart';
import 'package:google_cloud_compute_v1/testing.dart';

final fake = FakeFirewallPolicies(
  listAssociations: (request) async {
    // Assert request contents here if needed.
    return FirewallPoliciesListAssociationsResponse();
  },
);
```

### Option B: Subclassing the Fake

For more complex test setups or shared states, you can subclass the fake and
override its methods. Methods that are not overridden will throw an
`UnsupportedError`.

```dart
import 'package:google_cloud_compute_v1/compute.dart';
import 'package:google_cloud_compute_v1/testing.dart';

final class MyFakeFirewallPolicies extends FakeFirewallPolicies {
  @override
  Future<FirewallPoliciesListAssociationsResponse> listAssociations(
    ListAssociationsFirewallPolicyRequest request,
  ) async {
    // Assert request contents here if needed.
    return FirewallPoliciesListAssociationsResponse();
  }
}
```

## A Simple Test

```dart
import 'package:google_cloud_compute_v1/compute.dart';
import 'package:google_cloud_compute_v1/testing.dart';
import 'package:test/test.dart';

Future<void> functionUnderTest(FirewallPolicies service) async {
  // Application logic here.
  await service.listAssociations(ListAssociationsFirewallPolicyRequest());
  // More application logic here.
}

void main() {
  test('test', () async {
    final fake = FakeFirewallPolicies(
      listAssociations: (request) async {
          // Assert request contents here.
          return FirewallPoliciesListAssociationsResponse();
      },
    );
    // Instead of verifying that `functionUnderTest` completes, you should verify
    // the relevant properties of the result.
    await expectLater(functionUnderTest(fake), completes);
  });
}
```
