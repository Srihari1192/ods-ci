*** Settings ***
Documentation     Feast Modular Operator tests via quay.io/feastdev-ci/feast-test-images:feast-3.6 (FEAST_TEST=module-operator)
Suite Setup       Prepare Feast Modular Operator E2E Test Suite
Suite Teardown    Teardown Feast Modular Operator E2E Test Suite
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Common.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource
Test Tags         ExcludeOnODH


*** Test Cases ***
Run TestFeastModularOperator foundation test
    [Documentation]    Run modular foundation e2e from Feast test image: TestFeastOperator
    [Tags]  Smoke
    ...     FeatureStore
    ...     FeatureStoreModular
    ...     RHOAIENG-31299
    Run Feast Module Operator Test    TestFeastOperator    e2e
