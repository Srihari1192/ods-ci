*** Settings ***
Documentation     Feast Notebook tests - https://github.com/opendatahub-io/feast/tree/master/infra/feast-operator/test/e2e_rhoai/
Suite Setup       Prepare Feast E2E Test Suite
Suite Teardown    Teardown Feast E2E Test Suite
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Common.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource
Test Tags         ExcludeOnODH


*** Test Cases ***
Run feastMilvusNotebook Test
    [Documentation]    Run Feast Notebook test: TestFeastMilvusNotebook
    [Tags]  Tier1
    ...     FeatureStore
    ...     RHOAIENG-27952
    Run Feast Notebook Test    TestFeastMilvusNotebook

Run feastWBConnectionWithAuth Test
    [Documentation]    Run Feast Workbench connection Notebook test: FeastWorkbenchIntegrationWithAuth
    [Tags]  Tier1
    ...     FeatureStore
    ...     RHOAIENG-38921
    Run Feast Notebook Test    FeastWorkbenchIntegrationWithAuth

Run feastWBConnectionWithoutAuth Test
    [Documentation]    Run Feast Workbench connection Notebook test: FeastWorkbenchIntegrationWithoutAuth
    [Tags]  Tier1
    ...     FeatureStore
    ...     RHOAIENG-30000
    Run Feast Notebook Test    FeastWorkbenchIntegrationWithoutAuth

Run feastRayOfflineStore Test
    [Documentation]    Run Feast Ray Offline store Notebook test: TestFeastRayOfflineStoreNotebook
    [Tags]  Tier1
    ...     FeatureStore
    ...     RHOAIENG-38921
    Run Feast Notebook Test    TestFeastRayOfflineStoreNotebook

