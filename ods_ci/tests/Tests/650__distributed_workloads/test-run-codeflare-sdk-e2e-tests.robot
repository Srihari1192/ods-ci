*** Settings ***
Documentation     Codeflare-sdk E2E tests - https://github.com/project-codeflare/codeflare-sdk/tree/main/tests/e2e
Suite Setup       Prepare Codeflare-sdk E2E Test Suite
Suite Teardown    Teardown Codeflare-sdk E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/RHOSi.resource


*** Variables ***
${CODEFLARE-SDK_DIR}                codeflare-sdk
${CODEFLARE-SDK_REPO_URL}           %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}

*** Test Cases ***
Run TestMNISTRayClusterSDK test
    [Documentation]    Run Python E2E test: TestMNISTRayClusterSDK
    ...    ProductBug: https://issues.redhat.com/browse/RHOAIENG-3981 https://issues.redhat.com/browse/RHOAIENG-4240
    [Tags]  ODS-2544
    ...     Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    ...   	ProductBug
    Skip    "Skipping test case as its known issue RHOAIENG-3981 and RHOAIENG-4240. Enable once issue is fixed."
    Run Codeflare-sdk E2E Test    mnist_raycluster_sdk_test.py

Run TestRayClusterSDKOauth test
    [Documentation]    Run Python E2E test: TestRayClusterSDKOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    Skip    "Skipping for testing CI"
    Run Codeflare-sdk E2E Test    mnist_raycluster_sdk_oauth_test.py


*** Keywords ***
Prepare Codeflare-sdk E2E Test Suite
    [Documentation]    Prepare codeflare-sdk E2E Test Suite
    ${latest_tag} =  Run Process   git ls-remote --tags ${CODEFLARE-SDK_REPO_URL} | awk '{print $2}' | cut -d '/' -f 3 | sort -V | tail -n 1
    ...    shell=True    stderr=STDOUT
    Log To Console  codeflare-sdk latest tag is : ${latest_tag.stdout}
    IF    ${latest_tag.rc} != 0
        FAIL    Unable to fetch codeflare-sdk latest tag
    END
    ${result} =    Run Process    git clone -b ${latest_tag.stdout} ${CODEFLARE-SDK_REPO_URL} ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone codeflare-sdk repo ${CODEFLARE-SDK_REPO_URL}:${latest_tag.stdout}:${CODEFLARE-SDK_DIR}
    END
    Enable Component    codeflare
    Enable Component    ray
    ${result} =    Run Process  ./ods_ci/tests/Resources/Page/DistributedWorkloads/setup_python_virtual_env.sh
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END
    RHOSi Setup

Teardown Codeflare-sdk E2E Test Suite
    [Documentation]    Teardown codeflare-sdk E2E Test Suite
    Disable Component    codeflare
    Disable Component    ray
    ${result} =    Run Process  ./ods_ci/tests/Resources/Page/DistributedWorkloads/cleanup_python_virtual_env.sh
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup Python virtual environment
    END
    ${result} =    Run Process    poetry env use 3.11
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL   Unable to switch back to python 3.11 version
    END
    RHOSi Teardown

Run Codeflare-sdk E2E Test
    [Documentation]    Run codeflare-sdk E2E Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running codeflare-sdk test: ${TEST_NAME}"
    ${result} =    Run Process  source venv3.9/bin/activate && cd codeflare-sdk && poetry env use 3.9 && poetry install --with test,docs && poetry run pytest -v -s ./tests/e2e/${TEST_NAME} && poetry env use 3.11 && deactivate
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
