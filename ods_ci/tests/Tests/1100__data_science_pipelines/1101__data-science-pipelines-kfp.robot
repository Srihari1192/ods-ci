*** Settings ***
Documentation       Test suite for OpenShift Pipeline using kfp python package

Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Library             DateTime
Library             ../../../libs/DataSciencePipelinesAPI.py
Library             ../../../libs/DataSciencePipelinesKfp.py
Test Tags           DataSciencePipelines-Backend
Suite Setup         Data Science Pipelines Suite Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
${PROJECT_NAME}=    pipelineskfp1
${KUEUE_RESOURCES_SETUP_FILEPATH}=    tests/Resources/Page/DistributedWorkloads/kueue_resources_setup.sh


*** Test Cases ***
Verify Users Can Create And Run A Pipeline That Uses Only Packages From Base Image Using The kfp Python Package
    [Documentation]    Creates and runs flip_coin pipeline as regular user, verifiying the run results
    ...   This is a simple pipeline, where the tasks doesn't have any packages_to_install and just needs
    ...   the python packages included in the base_image
    [Tags]      Smoke    ODS-2203
    Skip If Test Enviroment Is ROSA-HCP    msg=Skipped due to automation bug on ROSA-HCP (tracked at RHOAIENG-16414)
    ${emtpy_dict}=    Create Dictionary
    End To End Pipeline Workflow Using Kfp
    ...    admin_username=${TEST_USER.USERNAME}
    ...    admin_password=${TEST_USER.PASSWORD}
    ...    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=cache-disabled/flip_coin.py
    ...    method_name=flipcoin_pipeline
    ...    status_check_timeout=180
    ...    pipeline_params=${emtpy_dict}
    [Teardown]    Projects.Delete Project Via CLI By Display Name    ${PROJECT_NAME}

Verify Users Can Create And Run A Pipeline That Uses Custom Python Packages To Install Using The kfp Python Package
    [Documentation]    Creates and runs iris_pipeline pipeline as regular user, verifiying the run results
    ...   In this pipeline there are tasks defining with packages_to_install some custom python packages to
    ...   be installed at execution time
    [Tags]      Smoke
    Skip If Test Enviroment Is ROSA-HCP    msg=Skipped due to automation bug on ROSA-HCP (tracked at RHOAIENG-16414)
    ${emtpy_dict}=    Create Dictionary
    End To End Pipeline Workflow Using Kfp
    ...    admin_username=${TEST_USER.USERNAME}
    ...    admin_password=${TEST_USER.PASSWORD}
    ...    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=cache-disabled/pip_index_url/iris_pipeline_pip_index_url.py
    ...    method_name=my_pipeline
    ...    status_check_timeout=300
    ...    pipeline_params=${emtpy_dict}
    [Teardown]    Projects.Delete Project Via CLI By Display Name    ${PROJECT_NAME}

Verify Upload Download In Data Science Pipelines Using The kfp Python Package
    [Documentation]    Creates, runs pipelines with regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]    Sanity    ODS-2683
    Skip If Test Enviroment Is ROSA-HCP    msg=Skipped due to automation bug on ROSA-HCP (tracked at RHOAIENG-16414)
    ${upload_download_dict}=    Create Dictionary    mlpipeline_minio_artifact_secret=value    bucket_name=value
    End To End Pipeline Workflow Using Kfp
    ...    admin_username=${TEST_USER.USERNAME}
    ...    admin_password=${TEST_USER.PASSWORD}
    ...    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=cache-disabled/upload_download.py
    ...    method_name=wire_up_pipeline
    ...    status_check_timeout=180
    ...    pipeline_params=${upload_download_dict}
    [Teardown]    Projects.Delete Project Via CLI By Display Name    ${PROJECT_NAME}


*** Keywords ***
End To End Pipeline Workflow Using Kfp
    [Documentation]    Create, run and double check the pipeline result using Kfp python package. In the end,
    ...    clean the pipeline resources.
    [Arguments]    ${username}    ${password}    ${admin_username}    ${admin_password}    ${project}    ${python_file}
    ...    ${method_name}    ${pipeline_params}    ${status_check_timeout}=160
    # robocop: off=line-too-long
    Projects.Delete Project Via CLI By Display Name    ${project}
    Projects.Create Data Science Project From CLI    name=${project}    as_user=${admin_username}

    DataSciencePipelinesBackend.Create PipelineServer Using Custom DSPA    ${project}

    ${status}    Login And Wait Dsp Route    ${admin_username}    ${admin_password}    ${project}
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working
    # The run_robot_test.sh is sending the --variablefile ${TEST_VARIABLES_FILE} which may contain the `PIP_INDEX_URL`
    # and `PIP_TRUSTED_HOST` variables, e.g. for disconnected testing.
    ODS.Assign Contributor Permissions To User ${username} In Project ${project} Using CLI
    ${pip_index_url} =    Get Variable Value    ${PIP_INDEX_URL}    ${NONE}
    ${pip_trusted_host} =    Get Variable Value    ${PIP_TRUSTED_HOST}    ${NONE}
    Log    pip_index_url = ${pip_index_url} / pip_trusted_host = ${pip_trusted_host}
    ${run_id}    Create Run From Pipeline Func    ${username}    ${password}    ${project}
    ...    ${python_file}    ${method_name}    pipeline_params=${pipeline_params}    pip_index_url=${pip_index_url}
    ...    pip_trusted_host=${pip_trusted_host}
    ${run_status}    Check Run Status    ${run_id}    timeout=${status_check_timeout}
    Should Be Equal As Strings    ${run_status}    SUCCEEDED    Pipeline run doesn't have a status that means success. Check the logs

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
