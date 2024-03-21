*** Settings ***
Documentation    Collection of keywords to interact with Workloads Metrics
Resource       ../../Common.robot

#*** Variables ***
#${WORKLOADS_METRICS_TITLE_XP}=     xpath=//h1[text()="Workload Metrics"]
#${PROJECT_XP}=    xpath=//div[text()='Project']

*** Keywords ***
Open Workload Metrics Home Page
    [Documentation]
    Wait Until Page Contains    Distributed Workload Metrics    timeout=30
    Click Link    Distributed Workload Metrics
    Wait For RHODS Dashboard To Load    wait_for_cards=${FALSE}    expected_page=Distributed Workload Metrics

