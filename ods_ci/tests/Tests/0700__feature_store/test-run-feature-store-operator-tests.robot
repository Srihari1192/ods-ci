*** Settings ***
Documentation     Feature Store Operator E2E tests - https://github.com/opendatahub-io/feast/tree/master/infra/feast-operator/test/e2e
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource
Suite Setup       Prepare Feature Store Operator E2E Test Suite
Suite Teardown    Cleanup Feature Store Operator E2E Test Suite


*** Test Cases ***
Run TesDefaultFeastCR
    [Documentation]
    [Tags]    Sanity
    ...       FeatureStore
    Run Feast Operator E2E Test    TesDefaultFeastCR

Run TestRemoteRegistryFeastCR
    [Documentation]
    [Tags]    Sanity
    ...       FeatureStore
    Run Feast Operator E2E Test    TestRemoteRegistryFeastCR
