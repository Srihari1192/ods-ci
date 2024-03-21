*** Settings ***
Documentation       Suite to test Workload metrics feature
Library             SeleniumLibrary
Library             OpenShiftLibrary
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
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
${CPU_REQUESTED}=    1
${MEMORY_REQUESTED}=    200

*** Test Cases ***
Verify Workload Metrics Home page Contents
    [Documentation]    Verifies "Workload Metrics" page is accessible from
    ...                the navigation menu on the left and page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    Open Distributed Workload Metrics Home Page
    Wait until Element is Visible    ${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}   timeout=20
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
    Check Project Metrics Default Page Contents

Verify Distributed Workload status Default Page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    [Documentation]    Verifiy distributed workload status page default contents
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
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
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE_NONADMIN}
    Check Project Metrics Default Page Contents
    Check Distributed Workload Status Page Contents
    [Teardown]    Run Keywords
    ...    Delete Data Science Project   ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Switch Browser    1

Verify The Workload Metrics by Submiiting a Ray distributted workload
    [Documentation]    Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Tags]    RHOAIENG-5216
    ...       Tier1    DistributedWorkloads

        # Kueue resource setup
    ${rc}    ${out}=    Run And Return Rc And Output    ${KUEUE_RESOURCES_SETUP_FILEPATH} ${PRJ_TITLE} ${CPU_SHARED_QUOTA} ${MEMEORY_SHARED_QUOTA}
    Should Be Equal As Integers    ${rc}    ${0}
    Log To Console   ${out}

    # Kueue workload setup
    ${rc}    ${out}=    Run And Return Rc And Output    ${KUEUE_WORKLOADS_SETUP_FILEPATH} ${PRJ_TITLE} ${CPU_REQUESTED} ${MEMORY_REQUESTED}
    Should Be Equal As Integers    ${rc}    ${0}
    Log To Console   ${out}

    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Select Refresh Interval    15 seconds

    Check Project Metrics Requested Resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    6    1.2   sample-job   Admitted

#    verify that job is in pending state
     Check Distributed Worklaod Status Overview    sample-job   Admitted
#    Sleep  1min  reason=Wait For Distributed workload metrics page to enable
#    Check Distributed Worklaod Status Overview    sample-job-partial    Succeeded

*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing Distributed workload Metrics UI
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
#    ${rc}    ${out}=    Run And Return Rc And Output
#    ...     oc patch OdhDashboardConfig odh-dashboard-config -n ${APPLICATIONS_NAMESPACE} --type=merge -p '{"spec": {"dashboardConfig": {"disableDistributedWorkloads": false}}}'
#    Should Be Equal As Integers    ${rc}         ${0}
#    Sleep  2min  reason=Wait For Distributed workload metrics page to enable
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing Distributed Workload metrics .
#    ${rc}    ${out}=    Run And Return Rc And Output
#    ...     oc patch OdhDashboardConfig odh-dashboard-config -n ${APPLICATIONS_NAMESPACE} --type=merge -p '{"spec": {"dashboardConfig": {"disableDistributedWorkloads": true}}}'
#    Should Be Equal As Integers    ${rc}         ${0}
    Delete Data Science Project   ${PRJ_TITLE}
    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE}
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown

    Check Project Metrics Default Page Contents
    [Documentation]    checks Project Metrics Default Page contents exists
    Wait until Element is Visible    xpath=//h4[text()="Quota is not set"]   timeout=20
    Page Should Contain Element    ${PROJECT_METRICS_TAB_XP}
    Page Should Contain Element    ${REFRESH_INTERVAL_XP}
    Page Should Contain Element    xpath=//h4[text()="Quota is not set"]
    Page Should Contain Element    xpath=//div[text()="Select another project or set the quota for this project."]

Check Distributed Workload Status Page Contents
    [Documentation]    checks Distributed Workload status Default Page contents exists
    Click Button    ${WORKLOAD_STATUS_TAB_XP}
    Wait until Element is Visible  ${WORKLOADS_STATUS_XP}    timeout=20
    Page Should Contain Element    ${REFRESH_INTERVAL_XP}
    Page Should Contain Element    ${STATUS_OVERVIEW_XP}
    Page Should Contain Element    ${WORKLOADS_STATUS_XP}
    FOR  ${status}  IN   @{STATUS_LIST}
        Page Should Contain    text=${status}: 0
    END
    Page Should Contain    No distributed workloads match your filters

Check Project Metrics Requested Resources
    [Documentation]    checks Project Metrics Requested Resources displaying correctly
    [Arguments]    ${PROJECT_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    ${CPU_REQUESTED}    ${MEMORY_REQUESTED}    ${JOB_NAME}    ${JOB_STATUS}

    Wait until Element is Visible    xpath=//div[text()='Distributed workload resource metrics']    timeout=20
    Wait Until Element Is Visible   xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path']
#    Double Click Element     xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path']
#    Scroll Element Into View    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path']
    Mouse over    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path']

    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-0"]    Requested by ${PROJECT_TITLE}: ${CPU_REQUESTED}

    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-2"]    Total shared quota: ${CPU_SHARED_QUOTA}

    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-1"]    Requested by all projects: ${CPU_REQUESTED}

    Check Expected String Equals   //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-0"]    Requested by ${PROJECT_TITLE}: ${MEMORY_REQUESTED}

    Check Expected String Equals    //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-1"]    Requested by all projects: ${MEMORY_REQUESTED}

    Check Expected String Equals    //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-2"]   Total shared quota: ${MEMEORY_SHARED_QUOTA}

    Check Expected String Contains    //td[@data-label="Name"]    ${JOB_NAME}

    Check Expected String Equals    //td[@data-label="Status"]//span[@class="pf-v5-c-label__text"]    ${JOB_STATUS}

Check Distributed Worklaod Status Overview
    [Documentation]    checks Distributed Worklaod Status Overview displaying correctly
    [Arguments]    ${JOB_NAME}    ${JOB_STATUS}

    Click Button    ${WORKLOAD_STATUS_TAB_XP}

    Wait until Element is Visible  xpath=//div[text()="Distributed Workloads"]    timeout=20

    Check Expected String Equals    //*[@id="status-overview-ChartLabel-title"]    1Distributed Workloads

    Page Should Contain    text=${JOB_STATUS}: 1

    Check Expected String Contains    //td[@data-label="Name"]    ${JOB_NAME}
    Check Expected String Equals     //td[@data-label="Priority"]    0
    Check Expected String Equals    //td[@data-label="Status"]//span[@class="pf-v5-c-label__text"]    ${JOB_STATUS}
    Check Expected String Equals     //td[@data-label="Latest Message"]    The workload is admitted

#    Page Should Contain Element    xpath=//td[@data-label="Created"]
#    Verify Distributed Status label contents    Created     05/04/2024, 18:30:45
#
#    Verify Distributed Status label contents    Latest Message        Job finished successfully
#


#    ${svg_element}    Get WebElement    xpath=//*[contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#    Click Element    ${svg_element}
#    Wait Until Element Is Visible   xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][@style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    Wait Until Element Is Visible    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][1]
#    Double Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][contains(@d, 'A75,75,0,1,1')]
#    Double Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][contains(@d, 'M0,-75A75,75')]
#
#    Double Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][contains(@d, 'M0,-75A75,75,0,1,1,0,75A75,75,0,1,1,0,-75M0,-66A66,66,0,1,0,0,66A66,66,0,1,0,0,-66Z')]
#    Double Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][@style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    Double Click Element    xpath=//*[contains(@d, 'A85,85,0')]
#
#    CLick Image     xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][1]
#    Click Image    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][@style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    Scroll Element Into View    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][@style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    Double Click Element    xpath=//*[contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#
##    Execute JavaScript    document.querySelector('path[fill="rgb(76, 177, 64)"]').click()
##    Execute JavaScript    document.evaluate('//*[name()="svg"]//*[local-name()="g"]//*[local-name()="path"][@style="fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;"]', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.click()
#    Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][@style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']




#    Mouse over    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'and contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#    Mouse over    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path' and @style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    Scroll Element Into View    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path' and @style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    Scroll Element Into View    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'and contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#    Scroll Element Into View    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][1]
#    Mouse over    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][1]
#    Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path'][1]
#    Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path' and @style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    Mouse over    xpath=//*[name()='svg']//*[local-name()='g']//*[local-name()='path' and @style='fill: rgb(76, 177, 64); padding: 8px; stroke: var(--pf-v5-chart-pie--data--stroke--Color, transparent); stroke-width: 1;']
#    ${chart_hover_text} =    Get Text    xpath=//*[contains(@style, 'fill: var(--pf-v5-chart-tooltip--Fill')]
#    Double Click Element   xpath=//*[contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#    Mouse Over   xpath=//*[contains(@d, 'A85,85,0')]
#    Mouse over   xpath=//*[contains(@d, 'M0,-85A85,85,0,1,1,0,85A85,85,0,1,1,0,-85M0,-76A76,76,0,1,0,0,76A76,76,0,1,0,0,-76Z')]
##    Click image   xpath=//*[contains(@d, 'A85,85,0')]
##    Click Element   xpath=//*[contains(@d, 'A85,85,0')]
#    ${chart_hover_text} =    Get Text    xpath=//*[contains(@style, 'fill: var(--pf-v5-chart-tooltip--Fill')]
#    Mouse Over   xpath=//*[contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#    ${donut_ctab} =    Get WebElement   xpath=//*[contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#    Mouse Over    ${donut_ctab}

#    //*[contains(@style, 'var(--pf-v5-chart-pie--data--stroke--Color')]
#    Mouse Over   xpath=//*[@transform="translate(85, 115)"]
#    Mouse Over   xpath=//*[contains(@style, 'var(--')][2]
#    Mouse Over   xpath=//*[@transform="translate(85, 115)"]
#    Mouse Over   xpath=//*[contains(@style, 'var(--')][2]
#    ${donut_ctab} =    Get WebElement   xpath=//*[contains(@style, 'fill: rgb(76, 177, 64)')]
#    Mouse Over    ${donut_ctab}
#    ${chart_hover_text} =    Get Text    xpath=//*[contains(@style, 'fill: var(--pf-v5-chart-tooltip--Fill')]
#
#    ${donut_ctab} =    Get WebElement   xpath=//*[contains(@style, 'fill: rgb(76, 177, 64)')]
#    Click Element    ${donut_ctab}
#    ${donut_ctab} =    Get WebElement   xpath=//*[contains(@style, 'fill: rgb(76, 177, 64)')]
#    Click Element    ${donut_ctab}
#    Mouse Over    xpath=//*[contains(@style, 'fill: rgb(76, 177, 64)')]
#    Mouse Over    xpath=//*[contains(@style, 'fill: rgb(76, 177, 64)')]
#    Mouse Over    xpath= d d//*[contains(@style, 'fill: rgb(76, 177, 64)')]
#    Mouse Over    xpath=//*[contains(@style, 'fill: rgb(76, 177, 64)')]
#    Execute JavaScript    document.querySelector('path[role="presentation"]').setAttribute('fill', 'blue')
#    Execute JavaScript    return document.querySelector('path[transform="translate(85, 115)"]');
#
#    Execute JavaScript    return document.querySelector('path[transform="translate(85, 115)"]');
#    Execute JavaScript    document.querySelector('path[role="presentation"]').setAttribute('fill', 'blue')
#    ${fill} =    Get Element Attribute    ${path_element}    fill
#    Log    The fill attribute of the path element is: ${fill}

Verify Distributed Status Label contents
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    [Arguments]    ${status_xpath}  ${expected_output}
    ${output} =  Get Text  xpath=//td[@data-label="${status_xpath}"]
    Should Match   ${output}  ${expected_output}

