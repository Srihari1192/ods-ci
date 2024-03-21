*** Settings ***
Documentation       Suite to test Workload metrics feature
Library             SeleniumLibrary
Library             OpenShiftLibrary

Library  JupyterLibrary
Library  String
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetrics.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Suite Setup         Project Suite Setup
Suite Teardown      Project Suite Teardown

*** Variables ***
${WORKLOADS_METRICS_TITLE_XP}=     xpath=//h1[text()="Distributed Workload Metrics"]
${WORKLOAD_METRICS_TEXT_XP}=    xpath=//div[text()='Monitor the metrics of your active resources.']
${PROJECT_METRICS_TAB_XP}=    xpath=//button[@aria-label="Project metrics tab"]
${WORKLOAD_STATUS_TAB_XP}=    xpath=//button[@aria-label="Distributed workload status tab"]
${STATUS_OVERVIEW_XP}=    xpath=//div[text()='Status overview']
${PROJECT_XP}=    xpath=//div[text()='Project']
${REFRESH_INTERVAL_XP}=    xpath=//div[text()='Refresh interval']
${TIME_RANGE}=    xpath=//div[text()='Time range']
${WORKLOADS_STATUS_XP}=    xpath=//div[text()='Distributed Workloads']
${REFRESH_INTERNAL_MENU_XP}=    xpath=//button[@aria-label="Options menu"]
${APPLICATIONS_NAMESPACE}=    redhat-ods-applications
@{STATUS_LIST}    Pending    Inadmissible    Admitted    Running    Evicted    Succeeded    Failed
@{REFRESH_INTERNAL_LIST}    15 seconds    30 seconds    1 minute    5 minutes    15 minutes    30 minutes    1 hour    2 hours    1 day
${project_name}=     dw-ui
${PRJ_TITLE}=    test-dw-ui
${PRJ_DESCRIPTION}=     project used for distributed workload metrics
${MEMEORY_SHARED_QUOTA}=    36
${CPU_SHARED_QUOTA}=    20

*** Test Cases ***
Verify Workload Metrics Home page Contents
    [Documentation]    Verifies "Workload Metrics" page is accessible from
    ...                the navigation menu on the left and page contents
    [Tags]    Tier2
    ...       Workload-Metrics
    Open Workload Metrics Home Page
    Wait until Element is Visible    ${WORKLOAD_METRICS_TEXT_XP}   timeout=20
    Page Should Contain Element     ${WORKLOADS_METRICS_TITLE_XP}
    Page Should Contain Element     ${WORKLOAD_METRICS_TEXT_XP}
    Page Should Contain Element     ${PROJECT_XP}
    Page Should Contain Element     ${PROJECT_METRICS_TAB_XP}
    Page Should Contain Element     ${WORKLOAD_STATUS_TAB_XP}
    Click Element    ${REFRESH_INTERNAL_MENU_XP}
    ${get_refresh_interval_list}=    Get All Text Under Element   xpath=//*[starts-with(@id, "select-option-")]
    Lists Should Be Equal    ${REFRESH_INTERNAL_LIST}    ${get_refresh_interval_list}

Verify Project Metrics Default Page contents
    [Tags]    Tier2
    ...       Workload-Metrics
     [Documentation]    Verifiy Project Metrics Page contents
     Open Workload Metrics Home Page
     Select Project by name    ${PRJ_TITLE}
     Wait until Element is Visible    xpath=//h4[text()="Quota is not set"]   timeout=20
     Page Should Contain Element    ${PROJECT_METRICS_TAB_XP}
     Page Should Contain Element    ${REFRESH_INTERVAL_XP}
     Page Should Contain Element    xpath=//h4[text()="Quota is not set"]
     Page Should Contain Element    xpath=//div[text()="Select another project or set the quota for this project."]

Verify Workload status Default Page contents
    [Tags]    Tier2
    ...       Workload-Metrics
    [Documentation]    Verifiy workload status page contents
    Open Workload Metrics Home Page
    Select Project by name    ${PRJ_TITLE}
    Click Button    ${WORKLOAD_STATUS_TAB_XP}
    Wait until Element is Visible  ${WORKLOADS_STATUS_XP}    timeout=20
    Page Should Contain Element    ${REFRESH_INTERVAL_XP}
    Page Should Contain Element    ${STATUS_OVERVIEW_XP}
    Page Should Contain Element    ${WORKLOADS_STATUS_XP}
    FOR  ${status}  IN   @{STATUS_LIST}
        Page Should Contain    text=${status}: 0
    END
    Page Should Contain    No distributed workloads match your filters


Verify Workload status overview metrics by creating workloads
    [Tags]    Tier2
    ...       Distributed-Workload-Metrics
    [Documentation]     Create a distributed Workload and  Verifiy workload status overview for the workloads is showing correctly
    Open Workload Metrics Home Page
    Wait until Element is Visible    ${WORKLOAD_STATUS_TAB_XP}   timeout=20
    Click Button    ${WORKLOAD_STATUS_TAB_XP}
    Wait until Element is Visible  xpath=//div[text()="Distributed Workloads"]    timeout=20

    # select project
    Select Project by name    test-dw-ui-8
    Wait until Element is Visible    xpath=//div[text()="Distributed Workloads"]    timeout=20
    Select Refresh Interval    15 seconds

    Mouse over    xpath=//*[starts-with(@id, "victory-container-")]/following-sibling::*[2]
#    xpath=//*[starts-with(@id, "victory-container-")]
    ${text}=  Get Text  xpath=//div[@class="of-v5-1-stack item"]
    Mouse over    xpath=//*[starts-with(@id, "victory-container-")]/following-sibling::*[2]
    Log To Console    Over text is :  ${output}

#    Verify Distributed workloads status Info

Verify Project metrics by creating workloads
    [Tags]    Tier2
    ...       Project-Metrics
    [Documentation]     Create a distributed Workload and  Verifiy workload status overview for the workloads is showing correctly
    Open Workload Metrics Home Page
#    Click Button     ${PROJECT_METRICS_TAB_XP}
    Select Project by name    test-dw-ui-8
    Select Refresh Interval    15 seconds
    Wait until Element is Visible    xpath=//div[text()='Distributed workload resource metrics']
    Verify CPU Requested resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}





*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
#    Enable Component    kueue
#    Wait For Pods Status    namespace=${APPLICATIONS_NAMESPACE}  label_selector=app.kubernetes.io/name=kueue  timeout=120
#    ${rc}    ${out}=    Run And Return Rc And Output
#    ...     oc patch OdhDashboardConfig odh-dashboard-config -n ${APPLICATIONS_NAMESPACE} --type=merge -p '{"spec": {"dashboardConfig": {"disableDistributedWorkloads": false}}}'
#    Should Be Equal As Integers    ${rc}         ${0}
#    Sleep  2min  reason=Wait For workload metrics page to enable
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
#    Open Data Science Projects Home Page
#    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DS Projects. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    SeleniumLibrary.Close All Browsers
#    ${rc}    ${out}=    Run And Return Rc And Output
#    ...     oc patch OdhDashboardConfig odh-dashboard-config -n ${APPLICATIONS_NAMESPACE} --type=merge -p '{"spec": {"dashboardConfig": {"disableDistributedWorkloads": true}}}'
#    Should Be Equal As Integers    ${rc}         ${0}
#    Disable Component    kueue
    RHOSi Teardown

Verify Distributed workloads status Info
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Wait until Element is Visible  xpath=//div[text()="Distributed Workloads"]    timeout=20
    Page Should Contain    text=Admitted: 1

    Page Should Contain Element    xpath=//td[@data-label="Name"]
    ${output} =  Get Text  xpath=//td[@data-label="Name"]
    Should Contain   ${output}  job-dw-test

    Verify Distributed Status label contents    Priority        0

    ${output} =  Get Text   xpath=//td[@data-label="Status"]//span[@class="pf-v5-c-label__text"]
    Should Contain   ${output}  Succeeded

    Page Should Contain Element    xpath=//td[@data-label="Created"]
    Verify Distributed Status label contents    Created     05/04/2024, 18:30:45

    Verify Distributed Status label contents    Latest Message        Job finished successfully

    Mouse Over     xpath=//*[@transform="translate(85, 115)"]
#    Click Element    xpath=//*[@transform="translate(85, 115)"]



Verify Distributed Status label contents
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    [Arguments]    ${status_xpath}  ${expected_output}
    ${output} =  Get Text  xpath=//td[@data-label="${status_xpath}"]
    Should Match   ${output}  ${expected_output}

Select Project by name
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    [Arguments]    ${project_name}
    Wait until Element is Visible    ${PROJECT_XP}   timeout=20
    Click Element    xpath://div[@data-testid="project-selector-dropdown"]
    Click Element    xpath://a[@role="menuitem" and text()="${project_name}"]

Select Refresh Interval
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    [Arguments]    ${refresh_interval}
    Wait until Element is Visible  ${REFRESH_INTERVAL_XP}    timeout=20
    Click Element     ${REFRESH_INTERNAL_MENU_XP}
    Click Element     xpath=//button[text()="${refresh_interval}"]

Verify CPU Requested resources
    [Documentation]    Verify CPU requested resources
    [Arguments]    ${PROJECT_TITLE}    ${CPU_SHARED_QUOTA}

    Mouse over    xpath=//div[@aria-label="CPU usage/requested"]
    ${text}=  Get Text  xpath=//div[@class="of-v5-1-stack item"]
    Log To Console    Over text is :  ${output}

    ${text}=   Get Element Attribute    xpath=//div[starts-with(@id,"pf-tooltip-")]/div[@class='pf-v5-c-tooltip__content pf-m-text-align-left']/text()   value
    Log To Console    Over text is : ${text}

    Mouse over    xpath=//*[@id="requested-resources-chart-CPU-ChartBulletTitle-ChartLabel"]/following-sibling::*[1]
#    //div[starts-with(@id,"pf-tooltip-")]/div[@class='pf-v5-c-tooltip__content pf-m-text-align-left']/text()

    Wait until Element is Visible  //div[@class="of-v5-1-stack item"]
    ${text}= Get Text  xpath=//div[@class="of-v5-1-stack item"]
    Log To Console    Over text is :  ${output}

    ${text}=   Get Element Attribute    xpath=//div[starts-with(@id,"pf-tooltip-")]/div[@class='pf-v5-c-tooltip__content pf-m-text-align-left']/text()   value
    Log To Console    Over text is : ${text}

    ${text}=   Get Element Attribute    xpath=//div[starts-with(@id,"pf-tooltip-")]/div[@class='pf-v5-c-tooltip__content pf-m-text-align-left']/text()   text
    Log To Console    Over text is : ${text}

    ${text}=   Get Element Attribute    xpath=//div[starts-with(@id,"pf-tooltip-")]/div[@class='pf-v5-c-tooltip__content pf-m-text-align-left']/text()   aria-label
    Log To Console    Over text is : ${text}
    ${text}=   Get Element Attribute    xpath=//div[starts-with(@id,"pf-tooltip-")]/div[@class='pf-v5-c-tooltip__content pf-m-text-align-left']/text()   div
    Log To Console    Over text is : ${text}
#    Wait Until Page Contains    Insufficient resources to start
    ${output} =  Get Text  xpath=//*[starts-with(@id, "pf-tooltip-")]
    Log To Console    Over text is :  ${output}
    # //xpath=//*[starts-with(@id, "pf-tooltip-")]

    ${output} =  Get Text  xpath=//*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-0"]
    Should Contain   ${output}  Requested by ${PROJECT_TITLE}: 0

    ${output} =  Get Text  xpath=//*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-2"]
    Should Contain   ${output}  Total shared quota: ${CPU_SHARED_QUOTA}



Verify Memeory Requested resources
    [Documentation]    Verify Memoery requested resources
    [Arguments]    ${PROJECT_TITLE}    ${MEMEORY_SHARED_QUOTA}
    ${output} =  Get Text  xpath=//*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-0"]
    Should Contain   ${output}  Requested by ${PROJECT_TITLE}: 0

    ${output} =  Get Text  xpath=//*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-2"]
    Should Contain   ${output}  Total shared quota: ${MEMEORY_SHARED_QUOTA}


Verify Top resource consuming distributed workloads chart
    [Documnetation]    verify Top resource consuming distributed workloads chart
    [Arguments]      ${PROJECT_TITLE}

Verify Distributed workload resource metrics
    [Documnetation]    verify Distributed workload resource metrics info
    [Arguments]      ${JOB_NAME}

    ${output} =  Get Text  xpath=//td[@data-label="Name"]
    Should Contain   ${output}   ${JOB_NAME}    {CPU_REQUESTED}
