*** Settings ***
Documentation    Collection of keywords to interact with Distributed Workloads Metrics UI
Library    String
Resource         ../../Common.robot


*** Variables ***
${PROJECT_XP}=    xpath=//div[text()='Project']
${DISTRIBUITED_WORKLOAD_METRICS_TITLE_XP}=    xpath=//h1[text()="Distributed Workload Metrics"]
${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}=    xpath=//div[text()='Monitor the metrics of your active resources.']
${PROJECT_METRICS_TAB_XP}=    xpath=//button[@aria-label="Project metrics tab"]
${WORKLOAD_STATUS_TAB_XP}=    xpath=//button[@aria-label="Distributed workload status tab"]
${STATUS_OVERVIEW_XP}=    xpath=//div[text()='Status overview']
${REFRESH_INTERVAL_XP}=    xpath=//div[text()='Refresh interval']
${WORKLOADS_STATUS_XP}=    xpath=//div[text()='Distributed Workloads']
${REFRESH_INTERNAL_MENU_XP}=    xpath=//button[@aria-label="Options menu"]
@{STATUS_LIST}=    Pending    Inadmissible    Admitted    Running    Evicted    Succeeded    Failed
@{REFRESH_INTERNAL_LIST}=    15 seconds    30 seconds    1 minute    5 minutes    15 minutes    30 minutes    1 hour    2 hours    1 day
${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}=    xpath=//div[text()="Distributed workload resource metrics"]
${REQUESTED_RESOURCES_TITLE_XP}=    xpath=//div[text()="Requested resources"]
${RESOURCES_CONSUMING_TITLE_XP}=    xpath=//div[text()="Top resource-consuming distributed workloads"]



*** Keywords ***
Open Distributed Workload Metrics Home Page
    [Documentation]    This will launch to the distributed Workloads Home page
    Wait Until Page Contains    Distributed Workload Metrics    timeout=30
    Click Link    Distributed Workload Metrics
    Wait For RHODS Dashboard To Load    wait_for_cards=${FALSE}    expected_page=Distributed Workload Metrics

Select Distributed Workload Project By Name
    [Documentation]    Select the project in distributed workload metrics page by project name
    [Arguments]    ${project_name}
    Wait until Element is Visible    ${PROJECT_XP}   timeout=20
    Click Element    xpath://div[@data-testid="project-selector-dropdown"]
    Click Element    xpath://a[@role="menuitem" and text()="${project_name}"]

Check Expected String Contains
    [Documentation]    Check Expected String Contains with the xpath prvoided get text
    [Arguments]    ${GET_TEXT_XP}    ${expected_output}
    ${output} =  Get Text  xpath=${GET_TEXT_XP}
    Should Contain   ${output}    ${expected_output}

Check Expected String Equals
    [Documentation]    Check Expected String Equals with the xpath prvoided get text
    [Arguments]    ${GET_TEXT_XP}    ${expected_output}
    ${output} =  Get Text  xpath=${GET_TEXT_XP}
    Should Match   ${output}    ${expected_output}

Select Refresh Interval
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    [Arguments]    ${refresh_interval}
    Wait until Element is Visible  ${REFRESH_INTERVAL_XP}    timeout=20
    Click Element     ${REFRESH_INTERNAL_MENU_XP}
    Click Element     xpath=//button[text()="${refresh_interval}"]

Get Current CPU Usage
    [Documentation]    Returns value of current cpu usage
    [Arguments]    ${namespace}    ${job_name}    ${workload_type}
    ${thanos_url}=    Get OpenShift Thanos URL
    ${token}=    Generate Thanos Token
    ${expression} =    Set Variable
    ...    sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="", namespace="${namespace}"} * on(namespace,pod) group_left(workload, workload_type)namespace_workload_pod:kube_pod_owner:relabel{cluster="", namespace="${namespace}", workload="${job_name}", workload_type="${workload_type}"}) by (pod)
    ${query_result} =    Prometheus.Run Query    https://${thanos_url}    ${token}    ${expression}
    ${value}=    Set Variable    ${query_result.json()["data"]["result"][0]["value"][-1]}
#    RETURN    ${query_result.json()["data"]["result"][0]["value"][-1]}
    ${cpu_usage_rounded_value}=    Evaluate    int(round(${value}, 0))
    RETURN  ${cpu_usage_rounded_value}

Get Current Memory Usage
    [Documentation]    Returns value of current cpu usage
    [Arguments]    ${namespace}    ${job_name}    ${workload_type}
    ${thanos_url}=    Get OpenShift Thanos URL
    ${token}=    Generate Thanos Token
    ${expression} =    Set Variable
    ...    sum(container_memory_working_set_bytes{cluster="", namespace="${namespace}", container!="", image!=""} * on(namespace,pod)group_left(workload, workload_type) namespace_workload_pod:kube_pod_owner:relabel{cluster="", namespace="${namespace}", workload="${job_name}", workload_type="${workload_type}"}) by (pod)
    ${query_result} =    Prometheus.Run Query    https://${thanos_url}    ${token}    ${expression}
#    RETURN    ${query_result.json()["data"]["result"][0]["value"][-1]}
    ${value}=    Set Variable    ${query_result.json()["data"]["result"][0]["value"][-1]}
    ${memory_requested} =    Convert To Number    ${value}
    ${memory_requested_gb_value} =    Evaluate    round( ${memory_requested} / (1024**3), 3)
    RETURN  ${memory_requested_gb_value}

Get CPU Requested
    [Documentation]    get CPU requested from LocalQueue  flavorsReservation
    [Arguments]    ${project}    ${local_queue_name}
    ${result}  ${output} =    Run And Return Rc And Output
    ...    oc get LocalQueue ${local_queue_name} -n ${project} -o=jsonpath='{.status.flavorsReservation[0].resources[?(@.name=="cpu")].total}'
    RETURN   ${output}

Get Memory Requested
    [Documentation]    get Memory requested from LocalQueue  flavorsReservation
    [Arguments]    ${project}    ${local_queue_name}
    ${result}  ${output} =    Run And Return Rc And Output
    ...    oc get LocalQueue ${local_queue_name} -n ${project} -o=jsonpath='{.status.flavorsReservation[0].resources[?(@.name=="memory")].total}'
    ${memory_requested} =    Replace String    ${output}    Mi    ${EMPTY}
    ${memory_requested_num} =    Convert To Number    ${memory_requested}
    ${memory_requested_gb_value} =    Evaluate    round( ${memory_requested_num} / 1024, 3)
    RETURN  ${memory_requested_gb_value}

Convert Memory Bytes To Gib
    [Documentation]    convert memory bytes into Gb
    [Arguments]    ${memory_bytes}
    ${memory_requested} =    Convert To Number    ${memory_bytes}
    ${memory_requested_gb_value} =    Evaluate    round( ${memory_bytes} / 1024, 3)
