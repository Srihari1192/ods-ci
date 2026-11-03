*** Settings ***
Documentation    Feature Store / Feast modular operator test keywords.
Library          OperatingSystem
Library          Process
Resource         ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${FEATURE-STORE-RELEASE-TAG}             release-3.6
${FEATURE-STORE_DIR}                     feature-store
${FEAST-MODULE-OPERATOR_DIR}             feast-modular-operator
${FEATURE-STORE_REPO_URL}                %{FEATURE-STORE_REPO_URL=https://github.com/opendatahub-io/feast.git}
${NOTEBOOK_IMAGE}                        quay.io/rhoai/odh-workbench-jupyter-datascience-cpu-py312-rhel9@sha256:63209fdee1f02bb64f8b5e66f8209f2d1999a337962d31c634169ac3e87ae946
${FEAST_VERSION}                         0.67.0
${FEAST_NOTEBOOK_VERSION}                0.66.0
${FEAST-MODULE-OPERATOR_REPO_URL}        %{FEAST-MODULE-OPERATOR_REPO_URL=https://github.com/opendatahub-io/feast-module-operator.git}
${FEAST-MODULE-OPERATOR-RELEASE-TAG}     %{FEAST-MODULE-OPERATOR-RELEASE-TAG=test-release-3.6}
${FEAST_PLATFORM_VERSION}                3.6.0
${DSC_NAME}                              default-dsc
${FEAST_MCP_CONTAINER_NAME}              mcpserver
# Prebuilt Go e2e image (module-operator + feast-operator). No go mod download on the agent.
${FEAST_TEST_IMAGE}                      %{FEAST_TEST_IMAGE=quay.io/feastdev-ci/feast-test-images:feast-3.6}
${FEAST_TEST_WORKDIR}                    feast-test-image
${FEAST_CONTAINER_TOOL}                  %{FEAST_CONTAINER_TOOL=podman}


*** Keywords ***
Prepare Feature Store Test Suite
    [Documentation]   Prepare Feature store setup by enabling component
    RHOSi Setup
    ${management_state}=    Get DSC Component State    ${DSC_NAME}    feastoperator    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Managed"
        Enable Component    feastoperator
        Wait Component Ready    feastoperator
    END

Prepare Feast Test Image Assets
    [Documentation]    Pull combined feast test image and extract binaries + test trees (DW-style).
    ${already}=    Run Keyword And Return Status
    ...    File Should Exist    ${FEAST_TEST_WORKDIR}/.extracted
    IF    ${already}
        Log To Console    Feast test image assets already extracted under ${FEAST_TEST_WORKDIR}
        RETURN
    END
    Log To Console    Pulling feast test image ${FEAST_TEST_IMAGE}
    ${pull}=    Run Process    ${FEAST_CONTAINER_TOOL} pull ${FEAST_TEST_IMAGE}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${pull.stdout}
    Should Be Equal As Integers    ${pull.rc}    0    msg=Failed to pull ${FEAST_TEST_IMAGE}
    Create Directory    ${FEAST_TEST_WORKDIR}
    ${cid_result}=    Run Process    ${FEAST_CONTAINER_TOOL} create ${FEAST_TEST_IMAGE}
    ...    shell=true
    ...    stderr=STDOUT
    Should Be Equal As Integers    ${cid_result.rc}    0    msg=Failed to create container from ${FEAST_TEST_IMAGE}: ${cid_result.stdout}
    ${cid}=    Strip String    ${cid_result.stdout}
    ${cp}=    Run Process    ${FEAST_CONTAINER_TOOL} cp ${cid}:/usr/local/bin/feast-e2e ${FEAST_TEST_WORKDIR}/feast-e2e
    ...    && ${FEAST_CONTAINER_TOOL} cp ${cid}:/usr/local/bin/feast-operator-e2e ${FEAST_TEST_WORKDIR}/feast-operator-e2e
    ...    && ${FEAST_CONTAINER_TOOL} cp ${cid}:/usr/local/bin/feast-operator-e2e-rhoai ${FEAST_TEST_WORKDIR}/feast-operator-e2e-rhoai
    ...    && ${FEAST_CONTAINER_TOOL} cp ${cid}:/usr/local/bin/kubectl ${FEAST_TEST_WORKDIR}/kubectl
    ...    && ${FEAST_CONTAINER_TOOL} cp ${cid}:/feast-module-operator ${FEAST_TEST_WORKDIR}/feast-module-operator
    ...    && ${FEAST_CONTAINER_TOOL} cp ${cid}:/feast-operator ${FEAST_TEST_WORKDIR}/feast-operator
    ...    && ${FEAST_CONTAINER_TOOL} rm ${cid}
    ...    && chmod +x ${FEAST_TEST_WORKDIR}/feast-e2e ${FEAST_TEST_WORKDIR}/feast-operator-e2e ${FEAST_TEST_WORKDIR}/feast-operator-e2e-rhoai ${FEAST_TEST_WORKDIR}/kubectl
    ...    && touch ${FEAST_TEST_WORKDIR}/.extracted
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${cp.stdout}
    Should Be Equal As Integers    ${cp.rc}    0    msg=Failed to extract feast test assets: ${cp.stdout}

Teardown Feast Test Image Assets
    [Documentation]    Remove extracted feast test image assets
    Log To Console    Removing feast test workdir ${FEAST_TEST_WORKDIR}
    ${exists}=    Run Keyword And Return Status    Directory Should Exist    ${FEAST_TEST_WORKDIR}
    IF    ${exists}
        Remove Directory    ${FEAST_TEST_WORKDIR}    recursive=True
    END

Prepare Feast E2E Test Suite
    [Documentation]    Prepare Feast operator E2E suite from prebuilt image (no git clone / go test compile)
    Log To Console    Preparing Feast E2E Test Suite from ${FEAST_TEST_IMAGE}
    Prepare Feast Test Image Assets
    Prepare Feature Store Test Suite
    Skip If Component Is Not Enabled     feastoperator

Teardown Feast E2E Test Suite
    [Documentation]   Cleanup Feast E2E Test Suite assets
    Teardown Feast Test Image Assets

Prepare Feast Modular Operator E2E Test Suite
    [Documentation]    Prepare Feast modular operator suite from prebuilt image
    Log To Console    Preparing Feast Modular Operator E2E from ${FEAST_TEST_IMAGE}
    Prepare Feast Test Image Assets
    Prepare Feature Store Test Suite
    Skip If Component Is Not Enabled     feastoperator

Teardown Feast Modular Operator E2E Test Suite
    [Documentation]   Cleanup modular operator test assets
    Teardown Feast Test Image Assets

Ensure Kueue Unmanaged For Feast Ray Offline Store Test
    [Documentation]    Ensure Kueue is Unmanaged for Feast tests
    ${kueue_state}=    Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NAMESPACE}
    Set Test Variable    ${KUEUE_STATE_BEFORE_FEAST}    ${kueue_state}
    IF    "${kueue_state}" != "Unmanaged"
        Log To Console    Setting Kueue component to Unmanaged for Feast test
        Set Component State    kueue    Unmanaged
    END

Restore Kueue State After Feast Ray Offline Store Test
    [Documentation]    Restore Kueue state if changed for Feast tests
    IF    "${KUEUE_STATE_BEFORE_FEAST}" != "Unmanaged"
        Log To Console    Restoring Kueue component to Removed state after Feast test
        Set Component State    kueue    Removed
    END

Run Feast Operator E2E Test
    [Documentation]   Run feast-operator e2e binary from image (test/e2e)
    [Arguments]   ${TEST_NAME}    ${TEST_TYPE}
    Log To Console    "Running feature-store operator e2e test: ${TEST_NAME} (image binary)"
    ${workdir}=    Normalize Path    ${FEAST_TEST_WORKDIR}
    ${result}=    Run Process    ${workdir}/feast-operator-e2e -test.v -ginkgo.focus=${TEST_NAME}
    ...    shell=true
    ...    cwd=${workdir}/feast-operator
    ...    timeout=15 min
    ...    env:RUN_ON_OPENSHIFT_CI=true
    ...    env:PATH=${workdir}:%{PATH}
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Run Feast Operator Upgrade Test
    [Documentation]   Run feast operator Upgrade test from e2e_rhoai binary
    [Arguments]   ${TEST_NAME}
    Log To Console    "Running feature-store operator Upgrade test: ${TEST_NAME} (image binary)"
    ${workdir}=    Normalize Path    ${FEAST_TEST_WORKDIR}
    ${result}=    Run Process    ${workdir}/feast-operator-e2e-rhoai -test.v -ginkgo.focus=${TEST_NAME}
    ...    shell=true
    ...    cwd=${workdir}/feast-operator
    ...    timeout=15 min
    ...    env:RUN_ON_OPENSHIFT_CI=true
    ...    env:PATH=${workdir}:%{PATH}
    ...    env:AWS_ACCESS_KEY_ID=${S3.AWS_ACCESS_KEY_ID}
    ...    env:AWS_SECRET_ACCESS_KEY=${S3.AWS_SECRET_ACCESS_KEY}
    ...    env:AWS_DEFAULT_REGION=${S3.BUCKET_1.REGION}
    ...    env:AWS_S3_BUCKET=${S3.BUCKET_1.NAME}
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Run Feast Notebook Test
    [Documentation]    Run feast Notebook / e2e_rhoai test from image binary
    [Arguments]   ${TEST_NAME}
    Log To Console    "Running feature-store Notebook test: ${TEST_NAME} (image binary)"
    ${cluster_auth_value}=    Get Variable Value    ${CLUSTER_AUTH}    ${EMPTY}
    IF  "${cluster_auth_value}" == "oidc"
        ${token}=    Get Oidc Token
        ...      ${CLUSTER_OIDC_ISSUER}
        ...      ${TEST_USER.USERNAME}
        ...      ${TEST_USER.PASSWORD}
        Should Not Be Empty    ${token}
    ELSE
        ${token}=    Set Variable    ${EMPTY}
    END
    ${workdir}=    Normalize Path    ${FEAST_TEST_WORKDIR}
    ${result}=    Run Process    ${workdir}/feast-operator-e2e-rhoai -test.v -ginkgo.focus=${TEST_NAME}
    ...    shell=true
    ...    cwd=${workdir}/feast-operator
    ...    stderr=STDOUT
    ...    timeout=15 min
    ...    env:RUN_ON_OPENSHIFT_CI=true
    ...    env:PATH=${workdir}:%{PATH}
    ...    env:NOTEBOOK_IMAGE=${NOTEBOOK_IMAGE}
    ...    env:FEAST_VERSION=${FEAST_NOTEBOOK_VERSION}
    ...    env:APPLICATIONS_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    env:PIP_INDEX_URL=${PIP_INDEX_URL}
    ...    env:PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
    ...    env:TOKEN=${token}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Create Feast Instance
    [Documentation]    Create Simple Feature store instance
    [Arguments]   ${namespace}    ${feast_instance_name}    ${feast_cr_file}
    Log To Console    Creating Feast Instance ${feast_instance_name}
    ${rc}=    Run And Return Rc    sed -e "s/\\$NAMESPACE/${namespace}/g" -e "s/\\$FEAST_PROJECT_NAME/${feast_instance_name}/g" ${feast_cr_file} | oc apply -f -
    IF    ${rc} != 0
        FAIL    Creating Feast instance failed
    ELSE
        Set Global Variable    ${FEAST_INSTANCES_CREATED}   True
    END

Delete Feast Instance And Project
    [Documentation]    Delete the Feast instance and its project. Skip the cleanup when the test
    ...    failed before it created them (FEAST_INSTANCES_CREATED is not True)
    [Arguments]   ${namespace}    ${feast_instance_name}
    Log To Console    Delete Feast Instance and Project
    IF    ${FEAST_INSTANCES_CREATED} == True
        Log To Console    Deleting Feast Instance : ${feast_instance_name}
        Run    oc delete FeatureStore ${feast_instance_name} -n ${namespace}
        Run    oc delete project ${namespace}
    ELSE
        Log To Console    Feast instance and project ${namespace} were not created, nothing to delete
    END

Get Feature Server Image Reference
    [Documentation]    Get Feature server image reference
    Log To Console    Fetching Feature Server Image reference
    ${rc}   ${featureServerImage}=    Run And Return Rc And Output
    ...    oc get csv ${OPERATOR_NAME}.${RHODS_VERSION} -n ${OPERATOR_NAMESPACE} -o jsonpath="{.spec.relatedImages[?(@.name=='odh_feature_server_image')].image}"
    Should Be Equal As Integers    ${rc}    0    msg=${featureServerImage}
    ${featureServerImage}=    Split String    ${featureServerImage}    ${SPACE}
    ${featureServerImageStr}=    Catenate    SEPARATOR=    @{featureServerImage}
    RETURN    ${featureServerImageStr}

Check Feast Instance Pod Images Pull Path Is Correct
    [Documentation]    Check Feast Instance Pod Images Pull Path Is Correct
    [Arguments]   ${namespace}    ${deployment_name}    ${image_pull_path}
    ${featureServerImage}=    Get Feature Server Image Reference

    ${rc}   ${images}=    Run And Return Rc And Output
    ...    oc get deployment/${deployment_name} -n ${namespace} -o jsonpath="{..image}"
    Should Be Equal As Integers    ${rc}    0    msg=${images}
    ${images}=    Split String    ${images}    ${SPACE}

    FOR  ${image}    IN    @{images}
        Log To Console    Check deployment ${deployment_name} pull path for image ${featureServerImage}
        Run Keyword And Continue On Failure
        ...    Should Start With    ${image}   ${image_pull_path}    msg=Deployment image pull path ${image} does not start with ${image_pull_path}
        IF    "${PRODUCT}" == "RHODS"
            Run Keyword And Continue On Failure
                ...    Should Match Regexp    ${image}    @sha256:[a-f0-9]{64}$    msg=Deployment image pull path ${image} does not contain sha256 digest
            Run Keyword And Continue On Failure
            ...    Should Be Equal As Strings    ${featureServerImage}    ${image}
        END
    END

Run Feast Module Operator Test
    [Documentation]   Run feast modular operator binary from image (no go mod download)
    [Arguments]   ${TEST_NAME}    ${TEST_TYPE}
    Log To Console    "Running feast modular operator ${TEST_TYPE} test: ${TEST_NAME} (image binary)"
    ${workdir}=    Normalize Path    ${FEAST_TEST_WORKDIR}
    ${result}=    Run Process    ${workdir}/feast-e2e -test.v -test.run ${TEST_NAME}
    ...    shell=true
    ...    cwd=${workdir}/feast-module-operator
    ...    timeout=15 min
    ...    env:OPERATOR_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    env:APPLICATIONS_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    env:FEAST_VERSION=${FEAST_VERSION}
    ...    env:FEAST_OPERATOR_PLATFORM_VERSION=${FEAST_PLATFORM_VERSION}
    ...    env:PATH=${workdir}:%{PATH}
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running feast modular operator test ${TEST_NAME} failed
    END

Run Feast Module Operator E2E Upgrade Test
    [Documentation]   Run feast modular operator upgrade test (still requires source clone; not in image yet)
    [Arguments]   ${TEST_TYPE}
    Log To Console    "Running feast modular operator ${TEST_TYPE} upgrade test"
    ${cloned}=    Run Keyword And Return Status    Directory Should Exist    ${FEAST-MODULE-OPERATOR_DIR}
    IF    not ${cloned}
        Common.Clone Git Repository    ${FEAST-MODULE-OPERATOR_REPO_URL}    ${FEAST-MODULE-OPERATOR-RELEASE-TAG}    ${FEAST-MODULE-OPERATOR_DIR}
    END
    ${result}=    Run Process    cd ${FEAST-MODULE-OPERATOR_DIR} && go test ./test/e2e/upgrade/${TEST_TYPE}/ -v -tags=e2e -timeout 3m
    ...    shell=true
    ...    timeout=10 min
    ...    env:FEAST_VERSION=${FEAST_VERSION}
    ...    env:FEAST_OPERATOR_PLATFORM_VERSION=${FEAST_PLATFORM_VERSION}
    ...    env:APPLICATIONS_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running feast modular operator ${TEST_TYPE} upgrade test failed
    END

Feast CRD Should Have MCP Server Field
    [Documentation]    Check that the FeatureStore CRD exists and has the spec.services.mcpServer field
    ${rc}    ${out}=    Run And Return Rc And Output    oc get crd featurestores.feast.dev
    Should Be Equal As Integers    ${rc}    0    msg=FeatureStore CRD not found: ${out}
    ${jsonpath}=    Catenate    SEPARATOR=
    ...    {.spec.versions[?(@.name=="v1")].schema.openAPIV3Schema
    ...    .properties.spec.properties.services.properties.mcpServer.type}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get crd featurestores.feast.dev -o jsonpath='${jsonpath}'
    Should Be Equal As Integers    ${rc}    0    msg=${out}
    Should Be Equal As Strings    ${out}    object
    ...    msg=FeatureStore CRD has no spec.services.mcpServer field, the installed operator has no MCP server support

Feast MCP Server Condition Should Be True
    [Documentation]    Check that the McpServer condition of the FeatureStore is True
    [Arguments]    ${namespace}    ${feast_instance_name}
    ${command}=    Catenate    oc get featurestore ${feast_instance_name} -n ${namespace}
    ...    -o jsonpath='{.status.conditions[?(@.type=="McpServer")].status}'
    ${rc}    ${status}=    Run And Return Rc And Output    ${command}
    Should Be Equal As Integers    ${rc}    0    msg=${status}
    Should Be Equal As Strings    ${status}    True    msg=McpServer condition is not True

Feast MCP Server Container Should Be Ready
    [Documentation]    Check that the Feast pod has a ready MCP server container
    [Arguments]    ${namespace}    ${feast_instance_name}
    ${jsonpath}=    Catenate    SEPARATOR=
    ...    {.items[*].status.containerStatuses[?(@.name=="${FEAST_MCP_CONTAINER_NAME}")].ready}
    ${rc}    ${ready}=    Run And Return Rc And Output
    ...    oc get pods -l feast.dev/name=${feast_instance_name} -n ${namespace} -o jsonpath='${jsonpath}'
    Should Be Equal As Integers    ${rc}    0    msg=${ready}
    Should Be Equal As Strings    ${ready}    true    msg=MCP server container is missing or not ready
