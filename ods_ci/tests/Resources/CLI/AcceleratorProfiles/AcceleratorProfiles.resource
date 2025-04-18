*** Settings ***
Documentation    Collection of keywords to interact with the administration of Accelerator Profiles via CLI


*** Variables ***
${ACCELERATOR_RESOURCES_DIRPATH}=    tests/Resources/Files/accelerator


*** Keywords ***
Create An Accelerator Profile Via CLI
    [Documentation]    Create an instance of Accelerator Profile using OC
    [Arguments]   ${name}  ${ns}=${APPLICATIONS_NAMESPACE}
    ${status}=    Run Keyword And Return Status    Oc Apply    kind=AcceleratorProfile
    ...    src=${ACCELERATOR_RESOURCES_DIRPATH}/${name}.yaml    namespace=${ns}
    ...    template_data={test_name: '${TEST_NAME}', test_ns: '${ns}'}
    Should Be Equal As Integers    ${status}     ${TRUE}

Get Accelerator Profile Spec Values Via CLI
    [Documentation]  Get Spec fields from an specific Accelerator Profile Instance
    [Arguments]   ${display_name}    ${ns}=${APPLICATIONS_NAMESPACE}
    ${ap_from_oc}=    Run
    ...    oc get acceleratorprofile -n ${ns} -o json | jq '.items[] | select(.spec.displayName == "${display_name}")'
    ${ap_json}=    Load Json String    ${ap_from_oc}
    ${ap_spec_dict}=    Get From Dictionary    ${ap_json}    spec
    RETURN    ${ap_spec_dict}

Accelerator Profile Should Not Exist
    [Documentation]  Get Spec fields from an specific Accelerator Profile Instance
    [Arguments]   ${name}    ${ns}=${APPLICATIONS_NAMESPACE}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get acceleratorprofile ${name} -n ${ns}
    Should Be Equal    "${rc}"    "1"
    Should Contain    ${out}    "${name}" not found

Verify Accelerator Profile Values Via CLI
    [Documentation]  Verifies that an specific Accelerator Profile exists, and it's value match with the expected
    [Arguments]   ${name}  ${identifier}=${EMPTY}  ${description}=${EMPTY}  ${enabled}=True
    ...           ${tolerations}=${EMPTY}  ${tol_operator}=Equal  ${tol_effect}=None  ${tol_key}=key
    ...           ${tol_value}=value  ${tol_seconds}=Forever   ${ns}=${APPLICATIONS_NAMESPACE}
    ${ap_spec_dict}=    Get Accelerator Profile Spec Values Via CLI    ${name}    ${ns}
    ${name_from_spec}=    Get From Dictionary    ${ap_spec_dict}    displayName
    ${enabled_from_spec}=    Get From Dictionary    ${ap_spec_dict}    enabled
    ${bool_enabled}=    Convert To Boolean    ${enabled}
    Should Be Equal    ${name_from_spec}    ${name}
    Should Be Equal    ${enabled_from_spec}    ${bool_enabled}
    # Identifier
    IF    "${identifier}" != "${EMPTY}"
        ${identifier_from_spec}=    Get From Dictionary    ${ap_spec_dict}    identifier
        Should Be Equal    ${identifier_from_spec}    ${identifier}
    END
    # Description
    IF    "${description}" != "${EMPTY}"
        ${description_from_spec}=    Get From Dictionary    ${ap_spec_dict}    description
        Should Be Equal    ${description_from_spec}    ${description}
    END
    # Tolerations
    IF    "${tolerations}" != "${EMPTY}"
        ${tolerations_from_spec}=    Get From Dictionary    ${ap_spec_dict}    tolerations
        ${tol_operator_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    operator
        Should Be Equal    ${tol_operator_retrieved}    ${tol_operator}
        ${tol_key_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    key
        Should Be Equal    ${tol_key_retrieved}    ${tol_key}
        ${tol_value_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    value
        Should Be Equal    ${tol_value_retrieved}    ${tol_value}
        # Effect
        ${tol_effect_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    effect
        IF    "${tol_effect}" == "None"
            Should Be Equal    ${tol_effect_retrieved}    ""
        ELSE
            Should Be Equal    ${tol_effect_retrieved}    ${tol_effect}
        END
        # Toleration Seconds
        IF    "${tol_seconds}" != "Forever"
            ${tol_seconds_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    tolerationSeconds
            Should Be Equal    "${tol_seconds_retrieved}"    "${tol_seconds}"
        END
    END

Verify Accelerator Profile Has No Tolerations Via CLI
    [Documentation]  Verifies that an specific Accelerator Profile exists, and it has no tolerations
    [Arguments]   ${name}    ${ns}=${APPLICATIONS_NAMESPACE}
    ${ap_spec_dict}=    Get Accelerator Profile Spec Values Via CLI    ${name}    ${ns}
    ${tolerations_from_spec}=    Get From Dictionary    ${ap_spec_dict}    tolerations
    Should Be Empty    ${tolerations_from_spec}

Delete All Accelerator Profiles Which Starts With
    [Documentation]    Delete all accelerator profiles given prefix. That prefix should match with the metadata.name
    ...                value of the OC Accelerator Profile resource
    ...                Uses OC
    [Arguments]   ${ap_prefix}  ${ns}=${APPLICATIONS_NAMESPACE}
    ${ap_str}=    Run
    ...    oc get acceleratorprofiles -n ${ns} -o json | jq .items[].metadata.name | grep ${ap_prefix} | tr -d '"'
    @{ap_list}=    Split String    ${ap_str}    separator=\n
    Log     List of Accelerator Profiles to be deleted: @{ap_list}    console=yes
    FOR    ${ap_name}    IN    @{ap_list}
        ${ap_desc}=    Run    oc get acceleratorprofile ${ap_name} -n ${ns} -o json
        Log     ${ap_desc}    console=yes
        ${return_code}=    Run And Return Rc
        ...    oc delete acceleratorprofile ${ap_name} -n ${ns}
        Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Accelerator profile ${ap_name}
    END
