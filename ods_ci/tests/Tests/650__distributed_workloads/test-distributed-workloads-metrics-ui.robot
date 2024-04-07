*** Settings ***
Documentation       Suite to test Workload metrics feature
Library             SeleniumLibrary
Library             OpenShiftLibrary
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            test-run-codeflare-sdk-e2e-tests.robot
Suite Setup         Project Suite Setup
Suite Teardown      Project Suite Teardown
Test Tags           DistributedWorkloadMetrics


*** Variables ***
${PRJ_TITLE}=    test-dw-ui
${PRJ_TITLE_NONADMIN}=    test-dw-nonadmin
${PRJ_DESCRIPTION}=    project used for distributed workload metrics
${KUEUE_RESOURCES_SETUP_FILEPATH}=    tests/Resources/Page/DistributedWorkloads/kueue_resources_setup.sh
${KUEUE_WORKLOADS_SETUP_FILEPATH}=    tests/Resources/Page/DistributedWorkloads/kueue_workloads.sh
${CPU_SHARED_QUOTA}=    20
${MEMEORY_SHARED_QUOTA}=    36
${project_created}=    False
${RESOURCE_FLAVOR_NAME}=    test-resource-flavor
${CLUSTER_QUEUE_NAME}=    test-cluster-queue
${LOCAL_QUEUE_NAME}=    test-user-queue
${CPU_REQUESTED}=    1
${MEMORY_REQUESTED}=    800
${JOB_NAME_QUEUE}=    kueue-job


*** Test Cases ***
Verify Workload Metrics Home page Contents
    [Documentation]    Verifies "Workload Metrics" page is accessible from
    ...                the navigation menu on the left and page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    Open Distributed Workload Metrics Home Page
    Wait until Element is Visible    ${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}   timeout=20
    Wait until Element is Visible    ${PROJECT_METRICS_TAB_XP}   timeout=20
    Page Should Contain Element     ${DISTRIBUITED_WORKLOAD_METRICS_TITLE_XP}
    Page Should Contain Element     ${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}
    Page Should Contain Element     ${PROJECT_XP}
    Page Should Contain Element     ${PROJECT_METRICS_TAB_XP}
    Page Should Contain Element     ${WORKLOAD_STATUS_TAB_XP}
    Click Element    ${REFRESH_INTERNAL_MENU_XP}
    ${get_refresh_interval_list}=    Get All Text Under Element   xpath=//*[starts-with(@id, "select-option-")]
    Lists Should Be Equal    ${REFRESH_INTERNAL_LIST}    ${get_refresh_interval_list}

Verify Project Metrics Default Page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    [Documentation]    Verifiy Project Metrics default Page contents
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Check Project Metrics Default Page Contents    ${PRJ_TITLE}

Verify Distributed Workload status Default Page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    [Documentation]    Verifiy distributed workload status page default contents
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Wait until Element is Visible    xpath=//div[text()="Distributed workload resource metrics"]   timeout=20
    Check Distributed Workload Status Page Contents

Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Documentation]    Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Tags]    RHOAIENG-4837
    ...       Tier1    DistributedWorkloads
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE_NONADMIN}   description=${PRJ_DESCRIPTION}
    Open  Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE_NONADMIN}
    Wait until Element is Visible    xpath=//h4[text()="Configure the project queue"]   timeout=20
    Page Should Contain Element     xpath=//div[text()="Configure the queue for this project, or select a different project."]
    # setup Kueue resource for the created project
    Setup Kueue Resources    ${PRJ_TITLE_NONADMIN}    cluster-queue-user    resource-flavor-user    local-queue-user
    Click Link    Distributed Workload Metrics
    Select Distributed Workload Project By Name    ${PRJ_TITLE_NONADMIN}
    Check Project Metrics Default Page Contents    ${PRJ_TITLE_NONADMIN}
    Check Distributed Workload Status Page Contents
    [Teardown]    Run Keywords
    ...    Cleanup Kueue Resources    ${PRJ_TITLE_NONADMIN}    cluster-queue-user    resource-flavor-user    local-queue-user
    ...    AND
    ...    Delete Data Science Project   ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Switch Browser    1

Verify The Workload Metrics By Submitting Kueue Batch Workload
    [Documentation]    Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Tags]    RHOAIENG-52161
    ...       Tier1    DistributedWorkloads

    Open Distributed Workload Metrics Home Page
    # Submit kueue batch workload
    ${result} =    Run Process    sh ${KUEUE_WORKLOADS_SETUP_FILEPATH} ${LOCAL_QUEUE_NAME} ${PRJ_TITLE} ${CPU_REQUESTED} ${MEMORY_REQUESTED} ${JOB_NAME_QUEUE}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to submit kueue workloads
    END
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Select Refresh Interval    15 seconds
    Wait until Element is Visible    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}    timeout=20
    Wait until Element is Visible    xpath=//*[text()="Running"]    timeout=30

    ${cpu_requested}=   Get CPU Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}
    ${memory_requested}=   Get Memory Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}
    Check Requested Resources Chart    ${cpu_requested}    ${memory_requested}
    Check Requested Resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    ${cpu_requested}    ${memory_requested}


    Check Distributed Workload Resource Metrics Status    ${JOB_NAME_QUEUE}    Running
    Check Distributed Worklaod Status Overview    ${JOB_NAME_QUEUE}    Running    All pods were ready or succeeded since the workload admission

    Click Button    ${PROJECT_METRICS_TAB_XP}

    Wait until Element is Visible    xpath=//*[@id="topResourceConsumingCPU-ChartLegend-ChartLabel-0"]    timeout=60
    Wait until Element is Visible    xpath=//*[@id="topResourceConsumingMemory-ChartLegend-ChartLabel-0"]    timeout=60
    Check Top Resource Consuming Distributed Workloads    ${JOB_NAME_QUEUE}
    Check Distributed Workload Resource Metrics Chart    ${cpu_requested}    ${memory_requested}

    Wait until Element is Visible    xpath=//*[text()="Succeeded"]    timeout=60
    Page Should Not Contain Element    xpath=//*[text()="Running"]
    Check Requested Resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    0    0
    Check Distributed Workload Resource Metrics Status    ${JOB_NAME_QUEUE}    Succeeded
    Check Distributed Worklaod Status Overview    ${JOB_NAME_QUEUE}    Succeeded    Job finished successfully

    ${result} =    Run Process  oc delete Job ${JOB_NAME_QUEUE} -n ${PRJ_TITLE}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Failed to delete job ${JOB_NAME_QUEUE}
    END

    Click Button    ${PROJECT_METRICS_TAB_XP}
    Wait until Element is Visible    xpath=//*[@data-testid="dw-workloada-resource-metrics"]//*[text()="No distributed workloads in the selected project are currently consuming resources."]    timeout=60
    Page Should Not Contain    ${JOB_NAME_QUEUE}
    Page Should Not Contain    Succeeded
    Check Distributed Workload Status Page Contents

Verify The Workload Metrics By Submitting Ray Workload
    [Documentation]    Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Tags]    RHOAIENG-5216
    ...       Tier1    DistributedWorkloads

    Run Codeflare-sdk Upgrade Test    TestMNISTRayClusterUp


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing Distributed workload Metrics UI
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${OCP_ADMIN_USER.USERNAME}   ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
#    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
#    Set Global Variable    ${project_created}    True
    # setup Kueue resource for the created project
#    Setup Kueue Resources    ${PRJ_TITLE}    ${CLUSTER_QUEUE_NAME}    ${RESOURCE_FLAVOR_NAME}    ${LOCAL_QUEUE_NAME}



Project Suite Teardown
    [Documentation]    Suite teardown steps after testing Distributed Workload metrics .
#    Cleanup Kueue Resources    ${PRJ_TITLE}    ${CLUSTER_QUEUE_NAME}    ${RESOURCE_FLAVOR_NAME}    ${LOCAL_QUEUE_NAME}
#    IF  ${project_created} == True    Run Keywords
#    ...    Delete Data Science Project   ${PRJ_TITLE}    AND
#    ...    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE}
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown

Check Project Metrics Default Page Contents
    [Documentation]    checks Project Metrics Default Page contents exists
    [Arguments]    ${project_name}
    Wait until Element is Visible    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}    timeout=20
    Page Should Contain Element    ${PROJECT_METRICS_TAB_XP}
    Page Should Contain Element    ${REFRESH_INTERVAL_XP}
    Page Should Contain Element    ${REQUESTED_RESOURCES_TITLE_XP}
    Check Requested Resources    ${project_name}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    0    0
    Page Should Contain Element    ${RESOURCES_CONSUMING_TITLE_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-top-consuming-workloads"]//*[text()="No distributed workloads in the selected project are currently consuming resources."]
    Page Should Contain Element    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-workloada-resource-metrics"]//*[text()="No distributed workloads in the selected project are currently consuming resources."]

Check Distributed Workload Status Page Contents
    [Documentation]    checks Distributed Workload status Default Page contents exists
    Click Button    ${WORKLOAD_STATUS_TAB_XP}
    Wait until Element is Visible  ${WORKLOADS_STATUS_XP}    timeout=20
    Page Should Contain Element    ${REFRESH_INTERVAL_XP}
    Page Should Contain Element    ${STATUS_OVERVIEW_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-status-overview-card"]//*[text()="Select another project or create a distributed workload in the selected project."]
    Page Should Contain Element    ${WORKLOADS_STATUS_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-workloads-table-card"]//*[text()="Select another project or create a distributed workload in the selected project."]

Check Requested Resources
    [Documentation]    checks requested resource contents
    [Arguments]    ${project_name}   ${cpu_shared_quota}    ${memory_shared_quota}    ${cpu_requested}    ${memory_requested}


    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-0"]    Requested by ${project_name}: ${cpu_requested}

    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-2"]    Total shared quota: ${cpu_shared_quota}

    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-1"]    Requested by all projects: ${cpu_requested}

    ${memory_requested_round} =    Evaluate    round( ${memory_requested}, 1)

    Check Expected String Equals   //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-0"]    Requested by ${project_name}: ${memory_requested_round}

    Check Expected String Equals    //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-1"]    Requested by all projects: ${memory_requested_round}

    Check Expected String Equals    //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-2"]   Total shared quota: ${memory_shared_quota}

Check Top Resource Consuming Distributed Workloads
    [Documentation]    checks requested resource contents
    [Arguments]    ${job_name}
    Wait until Element is Visible    ${RESOURCES_CONSUMING_TITLE_XP}    timeout=20
    Wait until Element is Visible    xpath=//*[@id="topResourceConsumingCPU-ChartLegend-ChartLabel-0"]     timeout=60
    Check Expected String Contains    //*[@id="topResourceConsumingCPU-ChartLegend-ChartLabel-0"]    ${job_name}
    Check Expected String Contains    //*[@id="topResourceConsumingMemory-ChartLegend-ChartLabel-0"]    ${job_name}
#    Check Expected String Equals    //*[@id="topResourceConsumingCPU-ChartLabel-title"]   0cores
#    Check Expected String Equals    //*[@id="topResourceConsumingMemory-ChartLabel-title"]   0cores    0.03GiB

Check Distributed Workload Resource Metrics Status
    [Documentation]    checks requested resource contents
    [Arguments]    ${job_name}    ${job_status}

    Check Expected String Contains    //td[@data-label="Name"]    ${job_name}
    Check Expected String Equals    //td[@data-label="Status"]//span[@class="pf-v5-c-label__text"]    ${job_status}



Check Requested Resources Chart
    [Documentation]    checks Requested Resources Chart
    [Arguments]    ${cpu_requested}   ${memory_requested}

    Mouse over    xpath=(//*[name()='svg']//*[local-name()='g']//*[local-name()='path'])[2]
    Wait until Element is Visible    xpath://*[contains(@style, 'fill: var(--pf-v5-chart-tooltip--Fill')]
    ${hover_cpu_requested} =  Get Text    xpath://*[contains(@style, 'fill: var(--pf-v5-chart-tooltip--Fill')]
    Should Match   ${hover_cpu_requested}   Requested by ${PRJ_TITLE}: ${cpu_requested} cores

    Mouse over    xpath=//*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-0"]


    Mouse over    xpath=(//*[name()='svg']//*[local-name()='g']//*[local-name()='path'])[8]
    Wait until Element is Visible    xpath://*[contains(@style, 'fill: var(--pf-v5-chart-tooltip--Fill')]
    ${hover_memory_requested}=  Get Text    xpath://*[contains(@style, 'fill: var(--pf-v5-chart-tooltip--Fill')]
    Should Match   ${hover_memory_requested}   Requested by ${PRJ_TITLE}: ${memory_requested} GiB

Check Distributed Workload Resource Metrics Chart
    [Documentation]    checks Distributed Workload Resource Metrics Chart
    [Arguments]    ${cpu_requested}   ${memory_requested}

    ${cpu_usgae}=    Get Current CPU Usage    ${PRJ_TITLE}    ${JOB_NAME_QUEUE}    job
    ${memory_usage}=   Get Current Memory Usage    ${PRJ_TITLE}    ${JOB_NAME_QUEUE}    job

    Mouse over    xpath=//*[@aria-label="CPU usage/requested"]
    Wait until Element is Visible    xpath://*[starts-with(@id,'pf-tooltip-')]
    ${cpu_usage_hover_data}=  Get Text    xpath://*[starts-with(@id,'pf-tooltip-')]
    ${cpu_usage_expected_data}=    Set Variable     ■ CPU usage: ${cpu_usgae} cores\n■ CPU requested: ${cpu_requested} cores
    Should Match    ${cpu_usage_hover_data}    ${cpu_usage_expected_data}

    # hovering outside to avoid fetching cpu usage requested
    Mouse over    (//button[@class="pf-v5-c-table__button"])[1]

    Mouse over    xpath=//*[@aria-label="Memory usage/requested"]
    Wait until Element is Visible    xpath://*[starts-with(@id,'pf-tooltip-')]
    ${memory_usage_hover_data}=  Get Text    xpath://*[starts-with(@id,'pf-tooltip-')]
    ${memory_usage_expected_data}=    Set Variable     ■ Memory usage: ${memory_usage} GiB\n■ Memory requested: ${memory_requested} GiB
    Should Match    ${memory_usage_hover_data}   ${memory_usage_expected_data}

Check Distributed Worklaod Status Overview
    [Documentation]    checks Distributed Worklaod Status Overview displaying correctly
    [Arguments]    ${job_name}    ${job_status}    ${job_status_message}
    Click Button    ${WORKLOAD_STATUS_TAB_XP}
    Wait until Element is Visible    xpath=//div[text()="Distributed Workloads"]    timeout=20
    Check Expected String Equals    //*[@id="status-overview-ChartLabel-title"]    1Distributed Workloads
    Page Should Contain    text=${JOB_STATUS}: 1
    Check Expected String Contains    //td[@data-label="Name"]    ${job_name}
    Check Expected String Equals     //td[@data-label="Priority"]    0
    Check Expected String Equals    //td[@data-label="Status"]//span[@class="pf-v5-c-label__text"]    ${job_status}
    Check Expected String Equals     //td[@data-label="Latest Message"]    ${job_status_message}

Setup Kueue Resources
    [Documentation]    Setup the kueue resources for the project
    [Arguments]    ${project_name}    ${cluster_queue_name}    ${resource_flavor_name}    ${local_queue_name}
    ${result} =    Run Process    sh ${KUEUE_RESOURCES_SETUP_FILEPATH} ${cluster_queue_name} ${resource_flavor_name} ${local_queue_name} ${project_name} ${CPU_SHARED_QUOTA} ${MEMEORY_SHARED_QUOTA}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to setup kueue resources
    END

Cleanup Kueue Resources
    [Documentation]    Cleanup the kueue resources for the project
    [Arguments]    ${project_name}    ${cluster_queue_name}   ${resource_flavor}    ${local_queue_name}
    ${result}=    Run Process    oc delete LocalQueue ${local_queue_name} -n ${project_name} & oc delete ClusterQueue ${cluster_queue_name} & oc delete ResourceFlavor ${resource_flavor}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to delete kueue resources
    END


Run Codeflare-sdk Upgrade Test
    [Documentation]    Run codeflare-sdk E2E Test
    [Arguments]    ${TEST_NAME}
     ${result} =    Run Process    git clone https://github.com/project-codeflare/codeflare-sdk.git
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone codeflare-sdk repo https://github.com/project-codeflare/codeflare-sdk.git
    END

    ${result} =    Run Process  virtualenv -p python3.9 venv3.9
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END
    Log To Console    "Running codeflare-sdk test: ${TEST_NAME}"
    ${result} =    Run Process  source venv3.9/bin/activate && cd codeflare-sdk && poetry env use 3.9 && poetry install --with test,docs && poetry run pytest -v -s ./tests/upgrade/raycluster_sdk_upgrade_test.py::poetry run pytest -v -s ./tests/e2e/raycluster_sdk_upgrade_test.py::${TEST_NAME} --timeout\=600 && deactivate
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
