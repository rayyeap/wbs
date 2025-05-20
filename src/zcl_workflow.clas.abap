CLASS zcl_workflow DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS trigger_workflow IMPORTING !requestid     TYPE zta_request-request_id OPTIONAL
                                       !financialYear TYPE zta_request-Financial_Year OPTIONAL
                                       !title         TYPE zta_request-Title OPTIONAL
                                       !description   TYPE zta_request-Description OPTIONAL
                                       !companycode   TYPE zta_request-Company_Code OPTIONAL
                                       !requesttype   TYPE zta_request-Request_Type OPTIONAL
                                       !wbstype       TYPE zta_request-WBS_Type OPTIONAL
                                       !projecttype   TYPE zta_request-Project_Type OPTIONAL
                                       !justification TYPE zta_request-Justification OPTIONAL
                                       !approver      TYPE string OPTIONAL
                                       !approver2     TYPE string OPTIONAL
                                       !createdby     TYPE string OPTIONAL
                                       !links         TYPE string OPTIONAL.
    INTERFACES if_swf_cpwf_callback .
  PROTECTED SECTION.
  PRIVATE SECTION.
    "Interface data type for information exchange.
    TYPES: BEGIN OF context,
             requestID     TYPE string,
             financialYear TYPE string,
             title         TYPE string,
             description   TYPE string,
             companycode   TYPE string,
             requesttype   TYPE string,
             wbstype       TYPE string,
             projecttype   TYPE string,
             justification TYPE string,
             approver      TYPE string,
             approver2     TYPE string,
             createdby     TYPE string,
             links         TYPE string,
           END OF context,
           BEGIN OF type_context,
             wbscontext TYPE context,
           END OF type_context.

    "Constants for workflow,
    CONSTANTS:
      BEGIN OF request_status,
        open     TYPE c LENGTH 1 VALUE 'O', "Open,
        accepted TYPE c LENGTH 1 VALUE 'A', "Accepted,
        rejected TYPE c LENGTH 1 VALUE 'X', "Rejected,
        waiting  TYPE c LENGTH 1 VALUE 'W', "Awaiting Approval,
      END OF request_status,
      request_wf_defid  TYPE if_swf_cpwf_api=>cpwf_def_id_long  VALUE 'eu10.pt-demo-cf-eu10-sbx.wbsmdmworkflow.wBSApprovalProcessing', " Replace this value with your workflow definition id.
      wf_retention_days TYPE if_swf_cpwf_api=>retention_time VALUE '30',
      callback_class    TYPE if_swf_cpwf_api=>callback_classname VALUE  'ZCL_WORKFLOW', " Replace this with your callback class
      consumer          TYPE string VALUE 'DEFAULT'.


ENDCLASS.



CLASS zcl_workflow IMPLEMENTATION.


  METHOD trigger_workflow.
    "register the workflow
    TRY.
        MODIFY ENTITIES OF i_cpwf_inst
           ENTITY CPWFInstance "Changed#RD
           EXECUTE registerWorkflow
           FROM VALUE #( ( %key-CpWfHandle      = ''     "cl_system_uuid=>create_uuid_x16_static( )
                        %param-RetentionTime = wf_retention_days
                        %param-PaWfDefId     = request_wf_defid
                        %param-CallbackClass = callback_class
                        %param-Consumer      = consumer ) )
           MAPPED   DATA(mapped_wf)
           FAILED   DATA(failed_wf)
           REPORTED DATA(reported_wf).

        IF mapped_wf IS NOT INITIAL.

          "Map the fields to the outgoing context.
          DATA(context)   = VALUE type_context(
             wbscontext-requestid     = requestid
             wbscontext-financialyear = financialyear
             wbscontext-title         = title
             wbscontext-description   = description
             wbscontext-companycode   = companycode
             wbscontext-requesttype   = requesttype
             wbscontext-wbstype       = wbstype
             wbscontext-projecttype   = projecttype
             wbscontext-justification = justification
             wbscontext-approver      = approver
             wbscontext-approver2     = approver2
             wbscontext-createdby     = createdby
             wbscontext-links         = links
          ).
          CONDENSE: context-wbscontext-RequestID. "context-travel_context-Total_price, context-travel_context-travelid.

          " Set the workflow context for the new workflow instances
          TRY.
              DATA(lo_cpwf_api) = cl_swf_cpwf_api_factory_a4c=>get_api_instance( ).
              DATA(json_conv) = lo_cpwf_api->get_json_converter(  ).
              DATA(context_json) = json_conv->serialize( data = context ).
            CATCH cx_swf_cpwf_api.
          ENDTRY.

          "pass the Payload to workflow
          MODIFY ENTITIES OF i_cpwf_inst
           ENTITY CPWFInstance
           EXECUTE setPayload
           FROM VALUE #( ( %key-CpWfHandle = mapped_wf-cpwfinstance[ 1 ]-CpWfHandle
                          %param-context  = context_json ) )
                MAPPED   mapped_wf
                FAILED   failed_wf
                REPORTED reported_wf ##NO_LOCAL_MODE.

        ENDIF.
      CATCH cx_uuid_error.
        "handle exception
    ENDTRY.

  ENDMETHOD.

  METHOD if_swf_cpwf_callback~workflow_instance_completed.

    TYPES: BEGIN OF callback_context,
             start_event TYPE type_context,
           END OF callback_context.

    DATA: callback_context TYPE callback_context.
    DATA: requestid TYPE zta_request-request_id.

    DATA(system_uuid) = cl_uuid_factory=>create_system_uuid( ).

    TRY.

*       Get the API of workflow.
        DATA(cpwf_api) = cl_swf_cpwf_api_factory_a4c=>get_api_instance( ).

*       Get the Context of workflow using workflow handler ID in jason format
*       Convert it into internal data format callback_context.
        DATA(context_xstring) = cpwf_api->get_workflow_context( iv_cpwf_handle = iv_cpwf_handle ).
        DATA(outcome) = cpwf_api->get_workflow_outcome( iv_cpwf_handle = iv_cpwf_handle ).

        cpwf_api->get_context_data_from_json(
          EXPORTING
            iv_context      = context_xstring
            it_name_mapping = VALUE #( ( abap = 'start_event' json = 'startEvent' ) )
          IMPORTING
            ev_data         = callback_context
        ).

      CATCH cx_swf_cpwf_api INTO DATA(exception).
    ENDTRY.


    IF outcome = 'Rejected'.
      DATA(status)    = 'X'.
    ELSE.
      status = 'A'.
    ENDIF.

* Since Request ID is not key we would not be able to use EML to update status using it.
* Ideally Request ID in real time scenario would be a unique key
* derived by Late or early numbering and you would be able to use EML to udate status.
* For this scenario we would have to get the Request UUID as that's the key.

    requestid  = callback_context-start_event-wbscontext-requestid.

    " Replace the suffix (last 4 digits) with your choosen group id.
    SELECT SINGLE requestuuid FROM zcr_request WHERE requestid = @requestid
    INTO @DATA(requestuuid).

    IF sy-subrc = 0.
      " Update the status of the travel based on the workflow outcome.
      IF status = 'X'. "Reject
        MODIFY ENTITIES OF zcr_request " Replace the suffix with your choosen group id.
                  ENTITY request
                     UPDATE FIELDS ( OverallStatus IntegerValue ReplicationStatus CriticalityStatus ImageUrl )
                        WITH VALUE #( ( requestuuid    = requestuuid
                                        OverallStatus = status
                                        IntegerValue  = '2'
                                        ReplicationStatus = 'Pending'
                                        CriticalityStatus = '1'
                                        ImageUrl = |sap-icon://error|
                                      ) )
                      FAILED DATA(ls_failed)
                      REPORTED DATA(ls_reported).
        COMMIT ENTITIES.

        DATA(uuid_x16) = system_uuid->create_uuid_x16( ).
        GET TIME STAMP FIELD DATA(lv_short_time_stamp).
        INSERT zta_msg FROM TABLE @( VALUE #(
        (
         logs_uuid = uuid_x16
         parent_uuid  = requestuuid
         type      = 'Rejected'
         sys =   'CFIN'
         message = |Approver Rejected comment: { outcome }|
         local_last_changed_at = lv_short_time_stamp
         )
         ) ).

      ELSE.
        MODIFY ENTITIES OF zcr_request " Replace the suffix with your choosen group id.
            ENTITY request
               UPDATE FIELDS ( OverallStatus IntegerValue ReplicationStatus CriticalityStatus ImageUrl )
                  WITH VALUE #( ( requestuuid    = requestuuid
                                  OverallStatus = status
                                  IntegerValue  = '3'
                                  ReplicationStatus = 'Completed'
                                  CriticalityStatus = '3'
                                  ImageUrl = |sap-icon://complete|
                                ) )
                FAILED ls_failed
                REPORTED ls_reported.
        COMMIT ENTITIES.

        uuid_x16 = system_uuid->create_uuid_x16( ).
        GET TIME STAMP FIELD lv_short_time_stamp.
        INSERT zta_msg FROM TABLE @( VALUE #(
        (
         logs_uuid = uuid_x16
         parent_uuid  = requestuuid
         type      = 'Success'
         sys =   'Workflow'
         message = |Approver approved in workflow { status }|
         local_last_changed_at = lv_short_time_stamp
         )
         ) ).
      ENDIF.
      CHECK status = 'A'.
      "Call Backend to process WBS Creation
      TYPES : BEGIN OF ty_projdef,
                project_definition   TYPE c LENGTH 24,
                description          TYPE c LENGTH 40,
                mask_id              TYPE c LENGTH 24,
                responsible_no       TYPE n LENGTH 8,
                applicant_no         TYPE n LENGTH 8,
                comp_code            TYPE c LENGTH 4,
                bus_area             TYPE c LENGTH 4,
                controlling_area     TYPE c LENGTH 4,
                profit_ctr           TYPE c LENGTH 10,
                project_currency     TYPE c LENGTH 5,
                project_currency_iso TYPE c LENGTH 3,
                network_assignment   TYPE n LENGTH 1,
                start                TYPE c LENGTH 8,
                finish               TYPE c LENGTH 8,
                plant                TYPE c LENGTH 4,
                calendar             TYPE c LENGTH 2,
                plan_basic           TYPE n LENGTH 1,
                plan_fcst            TYPE n LENGTH 1,
                time_unit            TYPE c LENGTH 3,
                time_unit_iso        TYPE c LENGTH 3,
                network_profile      TYPE c LENGTH 7,
                project_profile      TYPE c LENGTH 7,
                budget_profile       TYPE c LENGTH 6,
                project_stock        TYPE c LENGTH 1,
                objectclass          TYPE c LENGTH 2,
                statistical          TYPE c LENGTH 1,
                taxjurcode           TYPE c LENGTH 15,
                int_profile          TYPE c LENGTH 7,
                wbs_sched_profile    TYPE c LENGTH 12,
                csh_bdgt_profile     TYPE c LENGTH 6,
                plan_profile         TYPE c LENGTH 6,
                joint_venture        TYPE c LENGTH 6,
                recovery_ind         TYPE c LENGTH 2,
                equity_type          TYPE c LENGTH 3,
                jv_object_type       TYPE c LENGTH 4,
                jv_jib_class         TYPE c LENGTH 3,
                jv_jib_sub_class_a   TYPE c LENGTH 5,
                objectclass_ext      TYPE c LENGTH 5,
                func_area            TYPE c LENGTH 4,
                func_area_long       TYPE c LENGTH 16,
                slwid                TYPE c LENGTH 7,
                fcst_start           TYPE dats,
                fcst_finish          TYPE dats,
              END OF ty_projdef.

      TYPES : BEGIN OF ty_projdef_upd,
                project_definition   TYPE c LENGTH 1,
                description          TYPE c LENGTH 1,
                mask_id              TYPE c LENGTH 1,
                responsible_no       TYPE c LENGTH 1,
                applicant_no         TYPE c LENGTH 1,
                comp_code            TYPE c LENGTH 1,
                bus_area             TYPE c LENGTH 1,
                controlling_area     TYPE c LENGTH 1,
                profit_ctr           TYPE c LENGTH 1,
                project_currency     TYPE c LENGTH 1,
                project_currency_iso TYPE c LENGTH 1,
                network_assignment   TYPE c LENGTH 1,
                start                TYPE c LENGTH 1,
                finish               TYPE c LENGTH 1,
                plant                TYPE c LENGTH 1,
                calendar             TYPE c LENGTH 1,
                plan_basic           TYPE n LENGTH 1,
                plan_fcst            TYPE n LENGTH 1,
                time_unit            TYPE c LENGTH 1,
                time_unit_iso        TYPE c LENGTH 1,
                network_profile      TYPE c LENGTH 1,
                project_profile      TYPE c LENGTH 1,
                budget_profile       TYPE c LENGTH 1,
                project_stock        TYPE c LENGTH 1,
                objectclass          TYPE c LENGTH 1,
                statistical          TYPE c LENGTH 1,
                taxjurcode           TYPE c LENGTH 1,
                int_profile          TYPE c LENGTH 1,
                wbs_sched_profile    TYPE c LENGTH 1,
                csh_bdgt_profile     TYPE c LENGTH 1,
                plan_profile         TYPE c LENGTH 1,
                joint_venture        TYPE c LENGTH 1,
                recovery_ind         TYPE c LENGTH 1,
                equity_type          TYPE c LENGTH 1,
                jv_object_type       TYPE c LENGTH 1,
                jv_jib_class         TYPE c LENGTH 1,
                jv_jib_sub_class_a   TYPE c LENGTH 1,
                objectclass_ext      TYPE c LENGTH 1,
                func_area            TYPE c LENGTH 1,
                func_area_long       TYPE c LENGTH 1,
                user_field_key       TYPE c LENGTH 1,
                user_field_char20_1  TYPE c LENGTH 1,
                user_field_char20_2  TYPE c LENGTH 1,
                user_field_char10_1  TYPE c LENGTH 1,
                user_field_char10_2  TYPE c LENGTH 1,
                user_field_quan1     TYPE c LENGTH 1,
                user_field_unit1     TYPE c LENGTH 1,
                user_field_unit1_iso TYPE c LENGTH 1,
                user_field_quan2     TYPE c LENGTH 1,
                user_field_unit2     TYPE c LENGTH 1,
                user_field_unit2_iso TYPE c LENGTH 1,
                user_field_curr1     TYPE c LENGTH 1,
                user_field_cuky1     TYPE c LENGTH 1,
                user_field_cuky1_iso TYPE c LENGTH 1,
                user_field_curr2     TYPE c LENGTH 1,
                user_field_cuky2     TYPE c LENGTH 1,
                user_field_cuky2_iso TYPE c LENGTH 1,
                user_field_date1     TYPE c LENGTH 1,
                user_field_date2     TYPE c LENGTH 1,
                user_field_flag1     TYPE c LENGTH 1,
                user_field_flag2     TYPE c LENGTH 1,
                fcst_start           TYPE c LENGTH 1,
                fcst_finish          TYPE c LENGTH 1,
              END OF ty_projdef_upd.

      TYPES : BEGIN OF ty_element,
                wbs_element         TYPE c LENGTH 24,
                project_definition  TYPE c LENGTH 24,
                description         TYPE c LENGTH 40,
                short_id            TYPE c LENGTH 16,
                responsible_no      TYPE n LENGTH 8,
                applicant_no        TYPE n LENGTH 8,
                comp_code           TYPE c LENGTH 4,
                bus_area            TYPE c LENGTH 4,
                co_area             TYPE c LENGTH 4,
                profit_ctr          TYPE c LENGTH 10,
                proj_type           TYPE c LENGTH 2,
                network_assignment  TYPE n LENGTH 1,
                costing_sheet       TYPE c LENGTH 6,
                overhead_key        TYPE c LENGTH 6,
                calendar            TYPE c LENGTH 2,
                priority            TYPE c LENGTH 1,
                equipment           TYPE c LENGTH 18,
                functional_location TYPE c LENGTH 30,
                currency            TYPE c LENGTH 5,
                currency_iso        TYPE c LENGTH 3,
                plant               TYPE c LENGTH 4,
                user_field_key      TYPE c LENGTH 7,
                user_field_char20_1 TYPE c LENGTH 20,
                user_field_char20_2 TYPE c LENGTH 20,
                user_field_char10_1 TYPE c LENGTH 10,
                user_field_char10_2 TYPE c LENGTH 10,
                "user_field_quan1               TYPE c LENGTH 13,
                "user_field_unit1               TYPE c LENGTH 3,
                "user_field_unit1_iso           TYPE c LENGTH 3,
                "user_field_quan2               TYPE c LENGTH 13,
                "user_field_unit2               TYPE c LENGTH 3,
                "user_field_unit2_iso           TYPE c LENGTH 3,
                "user_field_curr1               TYPE c LENGTH 13,
                "user_field_cuky1               TYPE c LENGTH 5,
                "user_field_cuky1_iso           TYPE c LENGTH 3,
                "user_field_curr2               TYPE c LENGTH 13,
                "user_field_cuky2               TYPE c LENGTH 5,
                " user_field_cuky2_iso           TYPE c LENGTH 3,
                "user_field_date1               TYPE dats,
                "user_field_date2               TYPE dats,
                "user_field_flag1               TYPE c LENGTH 1,
                "user_field_flag2               TYPE c LENGTH 1,
                "objectclass                    TYPE c LENGTH 2,
                "statistical                    TYPE c LENGTH 1,
                "taxjurcode                     TYPE c LENGTH 15,
                "int_profile                    TYPE c LENGTH 7,
                "joint_venture                  TYPE c LENGTH 6,
                "recovery_ind                   TYPE c LENGTH 2,
                "equity_type                    TYPE c LENGTH 3,
                "jv_object_type                 TYPE c LENGTH 4,
                "jv_jib_class                   TYPE c LENGTH 3,
                "jv_jib_sub_class_a             TYPE c LENGTH 5,
                "objectclass_ext                TYPE c LENGTH 5,
                "wbs_planning_element           TYPE c LENGTH 1,
                "wbs_account_assignment_element TYPE c LENGTH 1,
                "wbs_billing_element            TYPE c LENGTH 1,
                "respsbl_cctr                   TYPE c LENGTH 10,
                "respsbl_cctr_controlling_area  TYPE c LENGTH 4,
                "request_cctr                   TYPE c LENGTH 10,
                "request_comp_code              TYPE c LENGTH 4,
                "request_cctr_controlling_area  TYPE c LENGTH 4,
                "location                       TYPE c LENGTH 10,
                "change_no                      TYPE c LENGTH 12,
                "invest_profile                 TYPE c LENGTH 6,
                "res_anal_key                   TYPE c LENGTH 6,
                "wbs_cctr_posted_actual         TYPE c LENGTH 10,
                "wbs_basic_start_date           TYPE dats,
                "wbs_basic_finish_date          TYPE dats,
                "wbs_forecast_start_date        TYPE dats,
                "wbs_forecast_finish_date       TYPE dats,
                "wbs_actual_start_date          TYPE dats,
                "wbs_actual_finish_date         TYPE dats,
                "wbs_basic_duration             TYPE c LENGTH 5,
                "wbs_basic_dur_unit             TYPE c LENGTH 3,
                "wbs_basic_dur_unit_iso         TYPE c LENGTH 3,
                "wbs_forecast_duration          TYPE c LENGTH 5,
                "wbs_forcast_dur_unit           TYPE c LENGTH 3,
                "wbs_forecast_dur_unit_iso      TYPE c LENGTH 3,
                "wbs_actual_duration            TYPE c LENGTH 5,
                "wbs_actual_dur_unit            TYPE c LENGTH 3,
                "wbs_actual_dur_unit_iso        TYPE c LENGTH 3,
                " func_area                      TYPE c LENGTH 4,
                "func_area_long                 TYPE c LENGTH 16,
                "inv_reason                     TYPE c LENGTH 2,
                " scale                          TYPE c LENGTH 2,
                "envir_invest                   TYPE c LENGTH 5,
              END OF ty_element.

      TYPES : BEGIN OF ty_element_upd,
                wbs_element                    TYPE c LENGTH 1,
                project_definition             TYPE c LENGTH 1,
                description                    TYPE c LENGTH 1,
                short_id                       TYPE c LENGTH 1,
                responsible_no                 TYPE c LENGTH 1,
                applicant_no                   TYPE c LENGTH 1,
                comp_code                      TYPE c LENGTH 1,
                bus_area                       TYPE c LENGTH 1,
                co_area                        TYPE c LENGTH 1,
                profit_ctr                     TYPE c LENGTH 1,
                proj_type                      TYPE c LENGTH 1,
                network_assignment             TYPE c LENGTH 1,
                costing_sheet                  TYPE c LENGTH 1,
                overhead_key                   TYPE c LENGTH 1,
                calendar                       TYPE c LENGTH 1,
                priority                       TYPE c LENGTH 1,
                equipment                      TYPE c LENGTH 1,
                functional_location            TYPE c LENGTH 1,
                currency                       TYPE c LENGTH 1,
                currency_iso                   TYPE c LENGTH 1,
                plant                          TYPE c LENGTH 1,
                user_field_key                 TYPE c LENGTH 1,
                user_field_char20_1            TYPE c LENGTH 1,
                user_field_char20_2            TYPE c LENGTH 1,
                user_field_char10_2            TYPE c LENGTH 1,
                user_field_quan1               TYPE c LENGTH 1,
                user_field_unit1               TYPE c LENGTH 1,
                user_field_unit1_iso           TYPE c LENGTH 1,
                user_field_quan2               TYPE c LENGTH 1,
                user_field_unit2               TYPE c LENGTH 1,
                user_field_unit2_iso           TYPE c LENGTH 1,
                user_field_curr1               TYPE c LENGTH 1,
                user_field_cuky1               TYPE c LENGTH 1,
                user_field_cuky1_iso           TYPE c LENGTH 1,
                user_field_curr2               TYPE c LENGTH 1,
                user_field_cuky2               TYPE c LENGTH 1,
                user_field_cuky2_iso           TYPE c LENGTH 1,
                user_field_date1               TYPE c LENGTH 1,
                user_field_date2               TYPE c LENGTH 1,
                user_field_flag1               TYPE c LENGTH 1,
                user_field_flag2               TYPE c LENGTH 1,
                objectclass                    TYPE c LENGTH 1,
                statistical                    TYPE c LENGTH 1,
                taxjurcode                     TYPE c LENGTH 1,
                int_profile                    TYPE c LENGTH 1,
                joint_venture                  TYPE c LENGTH 1,
                recovery_ind                   TYPE c LENGTH 1,
                equity_type                    TYPE c LENGTH 1,
                jv_object_type                 TYPE c LENGTH 1,
                jv_jib_class                   TYPE c LENGTH 1,
                jv_jib_sub_class_a             TYPE c LENGTH 1,
                objectclass_ext                TYPE c LENGTH 1,
                wbs_planning_element           TYPE c LENGTH 1,
                wbs_account_assignment_element TYPE c LENGTH 1,
                wbs_billing_element            TYPE c LENGTH 1,
                respsbl_cctr                   TYPE c LENGTH 1,
                respsbl_cctr_controlling_area  TYPE c LENGTH 1,
                request_cctr                   TYPE c LENGTH 1,
                request_comp_code              TYPE c LENGTH 1,
                request_cctr_controlling_area  TYPE c LENGTH 1,
                location                       TYPE c LENGTH 1,
                change_no                      TYPE c LENGTH 1,
                invest_profile                 TYPE c LENGTH 1,
                res_anal_key                   TYPE c LENGTH 1,
                wbs_cctr_posted_actual         TYPE c LENGTH 1,
                wbs_basic_start_date           TYPE c LENGTH 1,
                wbs_basic_finish_date          TYPE c LENGTH 1,
                wbs_forecast_start_date        TYPE c LENGTH 1,
                wbs_forecast_finish_date       TYPE c LENGTH 1,
                wbs_actual_start_date          TYPE c LENGTH 1,
                wbs_actual_finish_date         TYPE c LENGTH 1,
                wbs_basic_duration             TYPE c LENGTH 1,
                wbs_basic_dur_unit             TYPE c LENGTH 1,
                wbs_basic_dur_unit_iso         TYPE c LENGTH 1,
                wbs_forecast_duration          TYPE c LENGTH 1,
                wbs_forcast_dur_unit           TYPE c LENGTH 1,
                wbs_forecast_dur_unit_iso      TYPE c LENGTH 1,
                wbs_actual_dur_unit            TYPE c LENGTH 1,
                wbs_actual_dur_unit_iso        TYPE c LENGTH 1,
                wbs_actual_duration            TYPE c LENGTH 1,
                func_area                      TYPE c LENGTH 1,
                func_area_long                 TYPE c LENGTH 1,
                inv_reason                     TYPE c LENGTH 1,
                scale                          TYPE c LENGTH 1,
                envir_invest                   TYPE c LENGTH 1,
              END OF ty_element_upd.

      TYPES : BEGIN OF ty_hierarchie,
                wbs_element        TYPE c LENGTH 24,
                project_definition TYPE c LENGTH 24,
                up                 TYPE c LENGTH 24,
                down               TYPE c LENGTH 24,
                left               TYPE c LENGTH 24,
                right              TYPE c LENGTH 24,
              END OF ty_hierarchie.

      TYPES : BEGIN OF ty_return,
                type       TYPE c LENGTH 1,
                id         TYPE c LENGTH 20,
                number     TYPE c LENGTH 3,
                message    TYPE c LENGTH 220,
                log_no     TYPE c LENGTH 20,
                log_msg_no TYPE n LENGTH 6,
                message_v1 TYPE c LENGTH 50,
                message_v2 TYPE c LENGTH 50,
                message_v3 TYPE c LENGTH 50,
                message_v4 TYPE c LENGTH 50,
              END OF ty_return.

      TYPES : BEGIN OF ty_method_proj,
                refnumber  TYPE n LENGTH 6,
                objecttype TYPE c LENGTH 32,
                method     TYPE c LENGTH 32,
                objectkey  TYPE c LENGTH 90,
              END OF ty_method_proj.

      TYPES : BEGIN OF ty_message,
                method             TYPE c LENGTH 32,
                object_type        TYPE c LENGTH 32,
                internal_object_id TYPE c LENGTH 90,
                external_object_id TYPE c LENGTH 90,
                message_id         TYPE c LENGTH 20,
                message_number     TYPE c LENGTH 3,
                message_type       TYPE c LENGTH 1,
                message_text       TYPE c LENGTH 72,
              END OF ty_message.

      TYPES : BEGIN OF ty_BUS2054,
                wbs_element                    TYPE c LENGTH 24,
                description                    TYPE c LENGTH 40,
                responsible_no                 TYPE n LENGTH 8,
                applicant_no                   TYPE n LENGTH 8,
                company_code                   TYPE c LENGTH 4,
                business_area                  TYPE c LENGTH 4,
                controlling_area               TYPE c LENGTH 4,
                profit_ctr                     TYPE c LENGTH 10,
                proj_type                      TYPE c LENGTH 2,
                wbs_planning_element           TYPE c LENGTH 1,
                wbs_account_assignment_element TYPE c LENGTH 1,
                wbs_billing_element            TYPE c LENGTH 1,
                cstg_sheet                     TYPE c LENGTH 6,
                overhead_key                   TYPE c LENGTH 6,
                res_anal_key                   TYPE c LENGTH 6,
                request_cctr_controlling_area  TYPE c LENGTH 4,
                request_cctr                   TYPE c LENGTH 10,
                respsbl_cctr_controlling_area  TYPE c LENGTH 4,
                respsbl_cctr                   TYPE c LENGTH 10,
                calendar                       TYPE c LENGTH 2,
                priority                       TYPE c LENGTH 1,
                equipment                      TYPE c LENGTH 18,
                funct_loc                      TYPE c LENGTH 30,
                currency                       TYPE waers,
                currency_iso                   TYPE c LENGTH 3,
                plant                          TYPE c LENGTH 4,
                user_field_key                 TYPE c LENGTH 7,
                user_field_char20_1            TYPE c LENGTH 20,
                user_field_char20_2            TYPE c LENGTH 20,
                user_field_char10_1            TYPE c LENGTH 10,
                user_field_char10_2            TYPE c LENGTH 10,
                user_field_quan1               TYPE usrquan13,
                user_field_unit1               TYPE meins,
                user_field_unit1_iso           TYPE c LENGTH 3,
                user_field_quan2               TYPE usrquan13,
                user_field_unit2               TYPE meins,
                user_field_unit2_iso           TYPE c LENGTH 3,
                user_field_curr1               TYPE usrcurr13,
                user_field_cuky1               TYPE waers,
                user_field_cuky1_iso           TYPE c LENGTH 3,
                user_field_curr2               TYPE usrcurr13,
                user_field_cuky2               TYPE waers,
                user_field_cuky2_iso           TYPE c LENGTH 3,
                user_field_date1               TYPE dats,
                user_field_date2               TYPE dats,
                user_field_flag1               TYPE c LENGTH 1,
                user_field_flag2               TYPE c LENGTH 1,
                wbs_cctr_posted_actual         TYPE c LENGTH 10,
                wbs_summarization              TYPE c LENGTH 1,
                objectclass                    TYPE c LENGTH 5,
                statistical                    TYPE c LENGTH 1,
                taxjurcode                     TYPE c LENGTH 15,
                interest_prof                  TYPE c LENGTH 7,
                invest_profile                 TYPE c LENGTH 6,
                evgew                          TYPE p LENGTH 5 DECIMALS 0,
                change_no                      TYPE c LENGTH 12,
                subproject                     TYPE c LENGTH 12,
                planintegrated                 TYPE c LENGTH 1,
                inv_reason                     TYPE c LENGTH 2,
                scale                          TYPE c LENGTH 2,
                envir_invest                   TYPE c LENGTH 5,
                request_comp_code              TYPE c LENGTH 4,
                wbs_mrp_element                TYPE c LENGTH 1,
                location                       TYPE c LENGTH 10,
                venture                        TYPE c LENGTH 6,
                rec_ind                        TYPE c LENGTH 2,
                equity_typ                     TYPE c LENGTH 3,
                jv_otype                       TYPE c LENGTH 4,
                jv_jibcl                       TYPE c LENGTH 3,
                jv_jibsa                       TYPE c LENGTH 5,
                wbs_basic_start_date           TYPE dats,
                wbs_basic_finish_date          TYPE dats,
                wbs_forecast_start_date        TYPE dats,
                wbs_forecast_finish_date       TYPE dats,
                wbs_actual_start_date          TYPE dats,
                wbs_actual_finish_date         TYPE dats,
                wbs_basic_duration             TYPE p LENGTH 3 DECIMALS 1,
                wbs_basic_dur_unit             TYPE c LENGTH 3,
                wbs_basic_dur_unit_iso         TYPE c LENGTH 3,
                wbs_forecast_duration          TYPE p LENGTH 3 DECIMALS 1,
                wbs_forcast_dur_unit           TYPE c LENGTH 3,
                wbs_forecast_dur_unit_iso      TYPE c LENGTH 3,
                wbs_actual_duration            TYPE p LENGTH 3 DECIMALS 1,
                wbs_actual_dur_unit            TYPE c LENGTH 3,
                wbs_actual_dur_unit_iso        TYPE c LENGTH 3,
                wbs_left                       TYPE c LENGTH 24,
                wbs_up                         TYPE c LENGTH 24,
                func_area                      TYPE c LENGTH 16,
              END OF ty_BUS2054.

      TYPES : BEGIN OF ty_return2,
                type       TYPE c LENGTH 1,
                id         TYPE c LENGTH 20,
                number     TYPE n LENGTH 3,
                message    TYPE c LENGTH 220,
                log_no     TYPE c LENGTH 20,
                log_msg_no TYPE c LENGTH 6,
                message_v1 TYPE c LENGTH 50,
                message_v2 TYPE c LENGTH 50,
                message_v3 TYPE c LENGTH 50,
                message_v4 TYPE c LENGTH 50,
                parameter  TYPE c LENGTH 32,
                row        TYPE int4,
                field      TYPE c LENGTH 30,
                system     TYPE c LENGTH 10,
              END OF ty_return2.

      TYPES:
        BEGIN OF ty_proj_wbs_history,
          seq(6)      TYPE n,
          lvl(3)      TYPE n,
          wbs_element TYPE c LENGTH 24,
          wbs_up      TYPE c LENGTH 24,
          wbs_left    TYPE c LENGTH 24,
        END OF ty_proj_wbs_history.

      TYPES:
        BEGIN OF ty_extension,
          structure  TYPE c LENGTH 30,
          valuepart1 TYPE c LENGTH 240,
          valuepart2 TYPE c LENGTH 240,
          valuepart3 TYPE c LENGTH 240,
          valuepart4 TYPE c LENGTH 240,
        END OF ty_extension.

      TYPES:
        BEGIN OF ty_BAPI_TE_WBS_ELEMENT,
          wbs_element    TYPE c LENGTH 24,
          zhandover1     TYPE c LENGTH 20,
          zhandover2     TYPE c LENGTH 20,
          zdate1         TYPE dats,
          zdate2         TYPE dats,
          zproj          TYPE c LENGTH 10,
          zphase         TYPE c LENGTH 10,
          zzexptypeid    TYPE n LENGTH 2,
          zzerdat        TYPE dats,
          zzaenam        TYPE c LENGTH 12,
          zzaedat        TYPE dats,
          zclassid       TYPE c LENGTH 2,
          zzposid_source TYPE c LENGTH 24,
        END OF ty_BAPI_TE_WBS_ELEMENT.

      TRY.

          DATA(lo_destination) = cl_rfc_destination_provider=>create_by_comm_arrangement(
            comm_scenario          = 'Z_OUTBOUND_RFC_CFIN_CSCEN'   " Communication scenario
            service_id             = 'Z_OUTBOUND_RFC_CFIN_SRFC'    " Outbound service
                                  "comm_system_id         = 'Z_OUTBOUND_RFC_CSYS_CFIN'          " Communication system
                              ).

          DATA(lv_destination) = lo_destination->get_destination_name( ).

        CATCH cx_rfc_dest_provider_error.
      ENDTRY.

      "variables needed to call BAPI
      CONSTANTS: gc_x      TYPE char1 VALUE 'X'.
      DATA: ls_projdef          TYPE ty_projdef,
            ls_projdef_upd      TYPE ty_projdef_upd,
            ls_element          TYPE ty_element,
            lt_element          TYPE STANDARD TABLE OF ty_element,
            ls_element_upd      TYPE ty_element_upd,
            lt_element_upd      TYPE STANDARD TABLE OF ty_element_upd,
            ls_hierarchie       TYPE ty_hierarchie,
            lt_hierarchie       TYPE STANDARD TABLE OF ty_hierarchie,
            ls_return           TYPE ty_return,
            lt_method_proj      TYPE STANDARD TABLE OF ty_method_proj,
            ls_method_proj      TYPE ty_method_proj,
            lv_refnum           TYPE n LENGTH 6,
            lt_message          TYPE STANDARD TABLE OF ty_message,
            ls_message          TYPE ty_message,
            lt_extension        TYPE STANDARD TABLE OF ty_extension,
            ls_extension        TYPE ty_extension,
            ls_logs             TYPE zta_logs,
            lt_wbs_element      TYPE STANDARD TABLE OF ty_BUS2054,
            ls_wbs_element      TYPE ty_BUS2054,
            lt_return           TYPE STANDARD TABLE OF ty_return2,
            ls_return2          TYPE ty_return2,
            l_left_ele          TYPE c LENGTH 24,
            l_up_ele            TYPE c LENGTH 24,
            l_cur_proj          TYPE c LENGTH 24,
            l_prev_proj         TYPE c LENGTH 24,
            l_cur_seq(6)        TYPE n VALUE 0,
            l_cur_lvl(3)        TYPE n VALUE 0,
            l_prev_lvl(3)       TYPE n VALUE 0,
            l_l(3)              TYPE n,
            l_seq(6)            TYPE n VALUE 1,
            l_exist(1),
            wa_proj_wbs_history TYPE ty_proj_wbs_history,
            lt_proj_wbs_history TYPE STANDARD TABLE OF ty_proj_wbs_history,
            ls_te_wbs_element   TYPE ty_BAPI_TE_WBS_ELEMENT.

      DATA  msg TYPE c LENGTH 255.

      SELECT * FROM zcr_cfin WHERE RequestUuid = @requestuuid INTO TABLE @DATA(lt_cfin).
      LOOP AT lt_cfin INTO DATA(ls_cfin_def).
        CLEAR ls_projdef.
        ls_projdef-project_definition = ls_cfin_def-projectdefinition.
        ls_projdef-description        = ls_cfin_def-projectdescription.
        ls_projdef-project_profile    = ls_cfin_def-projectprofile.
        ls_projdef-controlling_area   = ''.
        ls_projdef-comp_code          = ls_cfin_def-companycode.
        ls_projdef-plant              = ls_cfin_def-plant.
        ls_projdef-func_area          = ls_cfin_def-functionalarea.
        ls_projdef-profit_ctr         = ls_cfin_def-profitcenter.
        ls_projdef-joint_venture      = ls_cfin_def-jointventureid.
        ls_projdef-recovery_ind       = ls_cfin_def-recoveryindicator.
        ls_projdef-equity_type        = ls_cfin_def-equitytype.
        ls_projdef-jv_object_type     = ls_cfin_def-jvobjecttype.
        ls_projdef-jv_jib_class       = ls_cfin_def-jvjibclass.
        ls_projdef-jv_jib_sub_class_a = ls_cfin_def-jvjibsaclass.
        ls_projdef-responsible_no     = ls_cfin_def-personresponsibleno.
        ls_projdef-start              = ls_cfin_def-startdate.
        ls_projdef-finish             = ls_cfin_def-finishdate.

        CLEAR ls_projdef_upd.
        ls_projdef_upd-project_profile    = gc_x.
        ls_projdef_upd-controlling_area   = gc_x.
        ls_projdef_upd-comp_code          = gc_x.
        ls_projdef_upd-plant              = gc_x.
        ls_projdef_upd-func_area          = gc_x.
        ls_projdef_upd-profit_ctr         = gc_x.
        ls_projdef_upd-joint_venture      = gc_x.
        ls_projdef_upd-recovery_ind       = gc_x.
        ls_projdef_upd-equity_type        = gc_x.
        ls_projdef_upd-jv_object_type     = gc_x.
        ls_projdef_upd-jv_jib_class       = gc_x.
        ls_projdef_upd-jv_jib_sub_class_a = gc_x.
        ls_projdef_upd-project_definition = gc_x.
        ls_projdef_upd-description        = gc_x.
        ls_projdef_upd-responsible_no     = gc_x.
        ls_projdef_upd-start              = gc_x.
        ls_projdef_upd-finish             = gc_x.

        CLEAR: lv_refnum.
        CLEAR: l_left_ele, l_up_ele, l_cur_proj, l_prev_proj, l_cur_seq, l_cur_lvl, l_prev_lvl, l_l, l_seq, l_exist.
        CLEAR: ls_return, msg, lt_message[], lt_method_proj[], lt_element[], lt_element_upd[], lt_hierarchie[], lt_wbs_element[], lt_proj_wbs_history[].
        SELECT * FROM zcr_cfin_items WHERE RequestUuid = @requestuuid AND CfinUuid = @ls_cfin_def-CfinUuid INTO TABLE @DATA(lt_cfin_items) .
        SORT lt_cfin_items BY wbslevel.
        LOOP AT lt_cfin_items INTO DATA(ls_cfin_items).
          CLEAR ls_element.
          ls_element-wbs_element        = ls_cfin_items-WbsElement.
          ls_element-project_definition = ls_cfin_def-projectdefinition.
          ls_element-description        = ls_cfin_items-WbsElementDescription.
          ls_element-short_id           = ls_cfin_items-WbsElement.
          ls_element-responsible_no     = ls_cfin_items-personresponsibleno.
          ls_element-profit_ctr         = ls_cfin_items-ProfitCenter.
          ls_element-proj_type          = ls_cfin_items-ProjectType.
          ls_element-plant              = ls_cfin_items-plant.
          "ls_element-joint_venture      = ls_cfin_items-jointventureid.
          "ls_element-recovery_ind       = ls_cfin_items-recoveryindicator.
          "ls_element-equity_type        = ls_cfin_items-equitytype.
          "ls_element-jv_object_type     = ls_cfin_items-jvobjecttype.
          "ls_element-jv_jib_class       = ls_cfin_items-jvjibclass.
          "ls_element-jv_jib_sub_class_a = ls_cfin_items-jvjibsaclass.
          "ls_element-respsbl_cctr       = ls_cfin_items-ResponsibleCostCenter.
          "ls_element-request_cctr       = ls_cfin_items-RequestingCostCenter.
          "ls_element-func_area          = ls_cfin_items-FunctionalArea.
          ls_element-costing_sheet      = ls_cfin_items-CostingSheet.
          APPEND ls_element TO lt_element.

          CLEAR ls_element_upd.
          ls_element_upd-wbs_element        = gc_x.
          ls_element_upd-project_definition = gc_x.
          ls_element_upd-description        = gc_x.
          ls_element_upd-short_id           = gc_x.
          ls_element_upd-responsible_no     = gc_x.
          ls_element-profit_ctr             = gc_x.
          ls_element_upd-proj_type          = gc_x.
          ls_element_upd-plant              = gc_x.
          ls_element_upd-joint_venture      = gc_x.
          ls_element_upd-recovery_ind       = gc_x.
          ls_element_upd-equity_type        = gc_x.
          ls_element_upd-jv_object_type     = gc_x.
          ls_element_upd-jv_jib_class       = gc_x.
          ls_element_upd-jv_jib_sub_class_a = gc_x.
          ls_element_upd-respsbl_cctr       = gc_x.
          ls_element_upd-request_cctr       = gc_x.
          ls_element_upd-func_area          = gc_x.
          ls_element_upd-costing_sheet      = gc_x.
          APPEND ls_element_upd TO lt_element_upd.

          l_cur_lvl = ls_cfin_items-wbslevel.
          " sort history table descending by sequence
          SORT lt_proj_wbs_history BY seq DESCENDING.
          " when current level equals 0
          IF l_cur_lvl = 0.
            " assign project definition
            l_prev_proj = l_cur_proj.
            l_cur_proj = ls_cfin_items-WbsElement.

            " clear sequence
            l_seq = 1.

            " no up and left element
            l_left_ele = ''.
            l_up_ele = ''.

            " clear history table
            CLEAR lt_proj_wbs_history[].

          ELSEIF l_cur_lvl = 1.
            " level one children do not have parent wbs element
            l_up_ele = ''.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
                       wbs_up = l_up_ele
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ELSEIF l_cur_lvl > l_prev_lvl.
            " go into child of previous wbs
            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_prev_lvl
              INTO wa_proj_wbs_history.
            l_up_ele = wa_proj_wbs_history-wbs_element.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
                       wbs_up = l_up_ele
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ELSEIF l_cur_lvl = l_prev_lvl.
            " siblings from same parent
            l_l = l_cur_lvl - 1.
            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_l
              INTO wa_proj_wbs_history.
            l_up_ele = wa_proj_wbs_history-wbs_element.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ELSEIF l_cur_lvl < l_prev_lvl.
            " go back to higher level element
            l_l = l_cur_lvl - 1.
            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_l
              INTO wa_proj_wbs_history.
            l_up_ele = wa_proj_wbs_history-wbs_element.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
                       wbs_up = l_up_ele
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ENDIF.
          CLEAR wa_proj_wbs_history.
          wa_proj_wbs_history-seq = l_seq.
          wa_proj_wbs_history-lvl = ls_cfin_items-wbslevel.
          wa_proj_wbs_history-wbs_element = ls_cfin_items-WbsElement.
          wa_proj_wbs_history-wbs_up = l_up_ele.
          wa_proj_wbs_history-wbs_left = l_left_ele.
          APPEND wa_proj_wbs_history TO lt_proj_wbs_history.
          " current level as previous level
          l_prev_lvl = l_cur_lvl.
          " add one to sequence
          ADD 1 TO l_seq.

          CLEAR ls_wbs_element.
          ls_wbs_element-wbs_element        = ls_cfin_items-WbsElement.
          ls_wbs_element-description        = ls_cfin_items-WbsElementDescription.
          ls_wbs_element-responsible_no     = ls_cfin_items-personresponsibleno.
          ls_wbs_element-profit_ctr         = ls_cfin_items-ProfitCenter.
          ls_wbs_element-proj_type          = ls_cfin_items-ProjectType.
          ls_wbs_element-plant              = ls_cfin_items-plant.
          ls_wbs_element-venture            = ls_cfin_items-jointventureid.
          ls_wbs_element-rec_ind            = ls_cfin_items-recoveryindicator.
          ls_wbs_element-equity_typ         = ls_cfin_items-equitytype.
          ls_wbs_element-jv_otype           = ls_cfin_items-jvobjecttype.
          ls_wbs_element-jv_jibcl           = ls_cfin_items-jvjibclass.
          ls_wbs_element-jv_jibsa           = ls_cfin_items-jvjibsaclass.
          ls_wbs_element-respsbl_cctr       = ls_cfin_items-ResponsibleCostCenter.
          ls_wbs_element-request_cctr       = ls_cfin_items-RequestingCostCenter.
          ls_wbs_element-func_area          = ls_cfin_items-FunctionalArea.
          ls_wbs_element-cstg_sheet         = ls_cfin_items-CostingSheet.
          ls_wbs_element-wbs_planning_element = ls_cfin_items-PlanningElement.
          ls_wbs_element-wbs_billing_element   = ls_cfin_items-billingElement.
          ls_wbs_element-wbs_account_assignment_element = ls_cfin_items-AccountAssignmentElement.
          ls_wbs_element-wbs_up             = l_up_ele.
          ls_wbs_element-wbs_left           = l_left_ele.
          APPEND ls_wbs_element TO lt_wbs_element.

          ADD 1 TO lv_refnum.
          CLEAR ls_method_proj.
          ls_method_proj-refnumber  = lv_refnum.
          ls_method_proj-objecttype = 'WBSElement'.
          ls_method_proj-method     = 'Create'.
          ls_method_proj-objectkey  = ls_cfin_items-WbsElement.
          "APPEND ls_method_proj TO lt_method_proj.

          CLEAR ls_hierarchie.
          ls_hierarchie-wbs_element = ls_cfin_items-WbsElement.
          ls_hierarchie-project_definition = ls_cfin_def-projectdefinition.
          DATA(lv_up) = ls_cfin_items-wbslevel - 1.
          IF lv_up GE 1.
            READ TABLE lt_cfin_items INTO DATA(ls_level_up) WITH KEY wbslevel = lv_up.
            IF sy-subrc EQ 0.
              ls_hierarchie-up = ls_level_up-WbsElement.
            ENDIF.
          ENDIF.
          DATA(lv_down) = ls_cfin_items-wbslevel + 1.
          READ TABLE lt_cfin_items INTO DATA(ls_level_down) WITH KEY wbslevel = lv_down.
          IF sy-subrc EQ 0.
            ls_hierarchie-down = ls_level_down-WbsElement.
          ENDIF.
          ls_hierarchie-left = ''.
          ls_hierarchie-right = ''.
          APPEND ls_hierarchie TO lt_hierarchie.

        ENDLOOP.

        CLEAR ls_method_proj.
        CLEAR lv_refnum.
        ADD 1 TO lv_refnum.
        CLEAR ls_method_proj.
        "ls_method_proj-refnumber  = lv_refnum.
        ls_method_proj-objecttype = 'ProjectDefinition'.
        ls_method_proj-method     = 'Create'.
        ls_method_proj-objectkey  = ls_projdef-project_definition.
        APPEND ls_method_proj TO lt_method_proj.

        CLEAR ls_method_proj.
        "ls_method_proj-refnumber  = lv_refnum.
        ls_method_proj-objecttype = 'WBS-Hierarchy'.
        ls_method_proj-method     = 'Create'.
        "ls_method_proj-objectkey  = ls_projdef-project_definition.
        "APPEND ls_method_proj TO lt_method_proj.

        CLEAR ls_method_proj.
        ls_method_proj-method     = 'Save'.
        APPEND ls_method_proj TO lt_method_proj.

        system_uuid = cl_uuid_factory=>create_system_uuid( ).
        "uuid_x16 = system_uuid->create_uuid_x16( ).

        SELECT SINGLE * FROM zcr_sap WHERE RequestUuid = @requestuuid INTO @DATA(ls_sap_def).

        CLEAR: ls_return, lt_message[].
        "Exception handling is mandatory to avoid dumps
        CALL FUNCTION 'BAPI_PROJECT_MAINTAIN'
          DESTINATION lv_destination
          EXPORTING
            i_project_definition     = ls_projdef
            i_project_definition_upd = ls_projdef_upd
          IMPORTING
            return                   = ls_return
          TABLES
            i_method_project         = lt_method_proj
            "i_wbs_element_table_update = lt_element_upd
            "i_wbs_element_table        = lt_element
            "i_wbs_hierarchie_table     = lt_hierarchie
            e_message_table          = lt_message
          EXCEPTIONS
            system_failure           = 1 MESSAGE msg
            communication_failure    = 2 MESSAGE msg
            OTHERS                   = 3.

        IF sy-subrc EQ 0.
          IF ls_return-message IS INITIAL.

            CALL FUNCTION 'BAPI_PS_INITIALIZATION' DESTINATION lv_destination.

            CLEAR: lt_return[].
            CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI' DESTINATION lv_destination
              EXPORTING
                i_project_definition = ls_projdef
              TABLES
                it_wbs_element       = lt_wbs_element
                et_return            = lt_return.

            CALL FUNCTION 'BAPI_BUS2001_SET_STATUS'
              DESTINATION lv_destination
              EXPORTING
                project_definition = ls_projdef
                set_system_status  = 'REL'
              IMPORTING
                return             = ls_return.
            "   TABLES
            "    e_result           = lt_result.


            READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
            IF sy-subrc NE 0.
              CALL FUNCTION 'BAPI_PS_PRECOMMIT' DESTINATION lv_destination.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION lv_destination.
            ENDIF.

            GET TIME STAMP FIELD lv_short_time_stamp.
            uuid_x16 = system_uuid->create_uuid_x16( ).
            INSERT zta_msg FROM TABLE @( VALUE #(
            (
             logs_uuid = uuid_x16
             parent_uuid  = requestuuid
             type      = 'Success'
             sys =   'CFIN'
             message = |Project Definition { ls_projdef-project_definition } successfully created.|
             local_last_changed_at = lv_short_time_stamp
             )
             ) ).
            LOOP AT lt_element INTO ls_element.
              GET TIME STAMP FIELD lv_short_time_stamp.
              uuid_x16 = system_uuid->create_uuid_x16( ).
              INSERT zta_msg FROM TABLE @( VALUE #(
              (
               logs_uuid = uuid_x16
               parent_uuid  = requestuuid
               type      = 'Success'
               sys =   'CFIN'
               message = |WBS Element { ls_element-wbs_element } successfully created.|
               local_last_changed_at = lv_short_time_stamp
               )
               ) ).
            ENDLOOP.
          ELSE.
            LOOP AT lt_message INTO ls_message WHERE message_type = 'E'.
              GET TIME STAMP FIELD lv_short_time_stamp.
              uuid_x16 = system_uuid->create_uuid_x16( ).
              INSERT zta_msg FROM TABLE @( VALUE #(
              (
               logs_uuid = uuid_x16
               parent_uuid  = requestuuid
               type      = 'Error'
               sys =   'CFIN'
               message = |{ ls_message-message_text }|
               local_last_changed_at = lv_short_time_stamp
               )
               ) ).
            ENDLOOP.
            MODIFY ENTITIES OF zcr_request " Replace the suffix with your choosen group id.
  ENTITY request
     UPDATE FIELDS ( IntegerValue ReplicationStatus CriticalityStatus ImageUrl )
        WITH VALUE #( ( requestuuid    = requestuuid
                        IntegerValue  = '2'
                        ReplicationStatus = 'Error'
                        CriticalityStatus = '1'
                        ImageUrl = |sap-icon://error|
                      ) )
      FAILED ls_failed
      REPORTED ls_reported.
            COMMIT ENTITIES.
          ENDIF.
        ENDIF.
      ENDLOOP.

      CLEAR: l_left_ele, l_up_ele, l_cur_proj, l_prev_proj, l_cur_seq, l_cur_lvl, l_prev_lvl, l_l, l_seq, l_exist.
      CLEAR: ls_return, msg, lt_message[], lt_method_proj[], lt_element[], lt_element_upd[], lt_hierarchie[], lt_wbs_element[], lt_proj_wbs_history[].
      TRY.

          CLEAR: lo_destination, lv_destination.
          lo_destination = cl_rfc_destination_provider=>create_by_comm_arrangement(
            comm_scenario          = 'Z_OUTBOUND_RFC_SAP_CSCEN'   " Communication scenario
            service_id             = 'Z_OUTBOUND_RFC_SAP_SRFC'    " Outbound service
                                  "comm_system_id         = 'Z_OUTBOUND_RFC_CSYS_CFIN'          " Communication system
                              ).

          lv_destination = lo_destination->get_destination_name( ).

        CATCH cx_rfc_dest_provider_error.
      ENDTRY.

      SELECT * FROM zcr_sap WHERE RequestUuid = @RequestUuid INTO TABLE @DATA(lt_sap).
      LOOP AT lt_sap INTO ls_sap_def.
        CLEAR ls_projdef.
        ls_projdef-project_definition = ls_sap_def-projectdefinition.
        ls_projdef-description        = ls_sap_def-projectdescription.
        ls_projdef-project_profile    = ls_sap_def-projectprofile.
        "ls_projdef-controlling_area   = 'PET1'.
        ls_projdef-comp_code          = ls_sap_def-companycode.
        ls_projdef-plant              = ls_sap_def-plant.
        ls_projdef-func_area          = ls_sap_def-functionalarea.
        ls_projdef-profit_ctr         = ls_sap_def-profitcenter.
        ls_projdef-joint_venture      = ls_sap_def-jointventureid.
        ls_projdef-recovery_ind       = ls_sap_def-recoveryindicator.
        ls_projdef-equity_type        = ls_sap_def-equitytype.
        ls_projdef-jv_object_type     = ls_sap_def-jvobjecttype.
        ls_projdef-jv_jib_class       = ls_sap_def-jvjibclass.
        ls_projdef-jv_jib_sub_class_a = ls_sap_def-jvjibsaclass.
        ls_projdef-responsible_no     = ls_sap_def-personresponsibleno.
        ls_projdef-start              = ls_sap_def-startdate.
        ls_projdef-finish             = ls_sap_def-finishdate.
        ls_projdef-objectclass        = 'IV'.

        CLEAR ls_projdef_upd.
        ls_projdef_upd-project_profile    = gc_x.
        ls_projdef_upd-controlling_area   = gc_x.
        ls_projdef_upd-comp_code          = gc_x.
        ls_projdef_upd-plant              = gc_x.
        ls_projdef_upd-func_area          = gc_x.
        ls_projdef_upd-profit_ctr         = gc_x.
        ls_projdef_upd-joint_venture      = gc_x.
        ls_projdef_upd-recovery_ind       = gc_x.
        ls_projdef_upd-equity_type        = gc_x.
        ls_projdef_upd-jv_object_type     = gc_x.
        ls_projdef_upd-jv_jib_class       = gc_x.
        ls_projdef_upd-jv_jib_sub_class_a = gc_x.
        ls_projdef_upd-project_definition = gc_x.
        ls_projdef_upd-description        = gc_x.
        ls_projdef_upd-responsible_no     = gc_x.
        ls_projdef_upd-start              = gc_x.
        ls_projdef_upd-finish             = gc_x.
        ls_projdef_upd-objectclass        = gc_x.

        CLEAR lv_refnum.
        CLEAR: l_left_ele, l_up_ele, l_cur_proj, l_prev_proj, l_cur_seq, l_cur_lvl, l_prev_lvl, l_l, l_seq, l_exist.
        CLEAR: ls_return, msg, lt_message[], lt_method_proj[], lt_element[], lt_element_upd[], lt_hierarchie[], lt_wbs_element[], lt_proj_wbs_history[].

        SELECT * FROM zcr_sap_items WHERE RequestUuid = @RequestUuid AND SapUuid = @ls_sap_def-SapUuid INTO TABLE @DATA(lt_sap_items) .
        SORT lt_sap_items BY wbslevel.
        LOOP AT lt_sap_items INTO DATA(ls_sap_items).
          CLEAR ls_element.
          ls_element-wbs_element        = ls_sap_items-WbsElement.
          ls_element-project_definition = ls_sap_def-projectdefinition.
          ls_element-description        = ls_sap_items-WbsElementDescription.
          ls_element-short_id           = ls_sap_items-WbsElement.
          ls_element-responsible_no     = ls_sap_items-personresponsibleno.
          ls_element-profit_ctr         = ls_sap_items-ProfitCenter.
          ls_element-proj_type          = ls_sap_items-ProjectType.
          ls_element-plant              = ls_sap_items-plant.
          "ls_element-joint_venture      = ls_cfin_items-jointventureid.
          "ls_element-recovery_ind       = ls_cfin_items-recoveryindicator.
          "ls_element-equity_type        = ls_cfin_items-equitytype.
          "ls_element-jv_object_type     = ls_cfin_items-jvobjecttype.
          "ls_element-jv_jib_class       = ls_cfin_items-jvjibclass.
          "ls_element-jv_jib_sub_class_a = ls_cfin_items-jvjibsaclass.
          "ls_element-respsbl_cctr       = ls_cfin_items-ResponsibleCostCenter.
          "ls_element-request_cctr       = ls_cfin_items-RequestingCostCenter.
          "ls_element-func_area          = ls_cfin_items-FunctionalArea.
          ls_element-costing_sheet      = ls_sap_items-CostingSheet.
          APPEND ls_element TO lt_element.

          CLEAR ls_element_upd.
          ls_element_upd-wbs_element        = gc_x.
          ls_element_upd-project_definition = gc_x.
          ls_element_upd-description        = gc_x.
          ls_element_upd-short_id           = gc_x.
          ls_element_upd-responsible_no     = gc_x.
          ls_element-profit_ctr             = gc_x.
          ls_element_upd-proj_type          = gc_x.
          ls_element_upd-plant              = gc_x.
          ls_element_upd-joint_venture      = gc_x.
          ls_element_upd-recovery_ind       = gc_x.
          ls_element_upd-equity_type        = gc_x.
          ls_element_upd-jv_object_type     = gc_x.
          ls_element_upd-jv_jib_class       = gc_x.
          ls_element_upd-jv_jib_sub_class_a = gc_x.
          ls_element_upd-respsbl_cctr       = gc_x.
          ls_element_upd-request_cctr       = gc_x.
          ls_element_upd-func_area          = gc_x.
          ls_element_upd-costing_sheet      = gc_x.
          APPEND ls_element_upd TO lt_element_upd.

          l_cur_lvl = ls_sap_items-wbslevel.
          " sort history table descending by sequence
          SORT lt_proj_wbs_history BY seq DESCENDING.
          " when current level equals 0
          IF l_cur_lvl = 0.
            " assign project definition
            l_prev_proj = l_cur_proj.
            l_cur_proj = ls_sap_items-WbsElement.

            " clear sequence
            l_seq = 1.

            " no up and left element
            l_left_ele = ''.
            l_up_ele = ''.

            " clear history table
            CLEAR lt_proj_wbs_history[].

          ELSEIF l_cur_lvl = 1.
            " level one children do not have parent wbs element
            l_up_ele = ''.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
                       wbs_up = l_up_ele
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ELSEIF l_cur_lvl > l_prev_lvl.
            " go into child of previous wbs
            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_prev_lvl
              INTO wa_proj_wbs_history.
            l_up_ele = wa_proj_wbs_history-wbs_element.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
                       wbs_up = l_up_ele
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ELSEIF l_cur_lvl = l_prev_lvl.
            " siblings from same parent
            l_l = l_cur_lvl - 1.
            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_l
              INTO wa_proj_wbs_history.
            l_up_ele = wa_proj_wbs_history-wbs_element.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ELSEIF l_cur_lvl < l_prev_lvl.
            " go back to higher level element
            l_l = l_cur_lvl - 1.
            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_l
              INTO wa_proj_wbs_history.
            l_up_ele = wa_proj_wbs_history-wbs_element.

            CLEAR wa_proj_wbs_history.
            READ TABLE lt_proj_wbs_history
              WITH KEY lvl = l_cur_lvl
                       wbs_up = l_up_ele
              INTO wa_proj_wbs_history.
            l_left_ele = wa_proj_wbs_history-wbs_element.
          ENDIF.
          CLEAR wa_proj_wbs_history.
          wa_proj_wbs_history-seq = l_seq.
          wa_proj_wbs_history-lvl = ls_sap_items-wbslevel.
          wa_proj_wbs_history-wbs_element = ls_sap_items-WbsElement.
          wa_proj_wbs_history-wbs_up = l_up_ele.
          wa_proj_wbs_history-wbs_left = l_left_ele.
          APPEND wa_proj_wbs_history TO lt_proj_wbs_history.
          " current level as previous level
          l_prev_lvl = l_cur_lvl.
          " add one to sequence
          ADD 1 TO l_seq.

          CLEAR ls_wbs_element.
          ls_wbs_element-wbs_element        = ls_sap_items-WbsElement.
          ls_wbs_element-description        = ls_sap_items-WbsElementDescription.
          ls_wbs_element-responsible_no     = ls_sap_items-personresponsibleno.
          ls_wbs_element-profit_ctr         = ls_sap_items-ProfitCenter.
          ls_wbs_element-proj_type          = ls_sap_items-ProjectType.
          ls_wbs_element-plant              = ls_sap_items-plant.
          ls_wbs_element-venture            = ls_sap_items-jointventureid.
          ls_wbs_element-rec_ind            = ls_sap_items-recoveryindicator.
          ls_wbs_element-equity_typ         = ls_sap_items-equitytype.
          ls_wbs_element-jv_otype           = ls_sap_items-jvobjecttype.
          ls_wbs_element-jv_jibcl           = ls_sap_items-jvjibclass.
          ls_wbs_element-jv_jibsa           = ls_sap_items-jvjibsaclass.
          ls_wbs_element-respsbl_cctr       = ls_sap_items-ResponsibleCostCenter.
          ls_wbs_element-request_cctr       = ls_sap_items-RequestingCostCenter.
          ls_wbs_element-func_area          = ls_sap_items-FunctionalArea.
          ls_wbs_element-cstg_sheet         = ls_sap_items-CostingSheet.
          ls_wbs_element-wbs_planning_element = ls_sap_items-PlanningElement.
          ls_wbs_element-wbs_billing_element   = ls_sap_items-billingElement.
          ls_wbs_element-wbs_account_assignment_element = ls_sap_items-AccountAssignmentElement.
          ls_wbs_element-wbs_up             = l_up_ele.
          ls_wbs_element-wbs_left           = l_left_ele.
          APPEND ls_wbs_element TO lt_wbs_element.

          CLEAR ls_te_wbs_element.
          ls_te_wbs_element-wbs_element = ls_sap_items-WbsElement.
          ls_te_wbs_element-zzposid_source = ls_sap_items-cfinwbs.
          ls_extension-structure = 'BAPI_TE_WBS_ELEMENT'.
          ls_extension-valuepart1 = ls_te_wbs_element.
          APPEND ls_extension TO lt_extension.

          ADD 1 TO lv_refnum.
          CLEAR ls_method_proj.
          ls_method_proj-refnumber  = lv_refnum.
          ls_method_proj-objecttype = 'WBSElement'.
          ls_method_proj-method     = 'Create'.
          ls_method_proj-objectkey  = ls_sap_items-WbsElement.
          "APPEND ls_method_proj TO lt_method_proj.


          CLEAR ls_hierarchie.
          CLEAR lv_up.
          ls_hierarchie-wbs_element = ls_sap_items-WbsElement.
          ls_hierarchie-project_definition = ls_sap_def-projectdefinition.
          lv_up = ls_sap_items-wbslevel - 1.
          IF lv_up GE 1.
            READ TABLE lt_sap_items INTO DATA(ls_level_up_sap) WITH KEY wbslevel = lv_up.
            IF sy-subrc EQ 0.
              ls_hierarchie-up = ls_level_up_sap-WbsElement.
            ENDIF.
          ENDIF.
          CLEAR lv_down.
          lv_down = ls_sap_items-wbslevel + 1.
          READ TABLE lt_sap_items INTO DATA(ls_level_down_sap) WITH KEY wbslevel = lv_down.
          IF sy-subrc EQ 0.
            ls_hierarchie-down = ls_level_down_sap-WbsElement.
          ENDIF.
          ls_hierarchie-left = ''.
          ls_hierarchie-right = ''.
          APPEND ls_hierarchie TO lt_hierarchie.

        ENDLOOP.

        CLEAR ls_method_proj.

        CLEAR lv_refnum.
        ADD 1 TO lv_refnum.
        CLEAR ls_method_proj.
        "ls_method_proj-refnumber  = lv_refnum.
        ls_method_proj-objecttype = 'ProjectDefinition'.
        ls_method_proj-method     = 'Create'.
        ls_method_proj-objectkey  = ls_projdef-project_definition.
        APPEND ls_method_proj TO lt_method_proj.

        CLEAR ls_method_proj.
        "ls_method_proj-refnumber  = lv_refnum.
        ls_method_proj-objecttype = 'WBS-Hierarchy'.
        ls_method_proj-method     = 'Create'.
        "ls_method_proj-objectkey  = ls_projdef-project_definition.
        "APPEND ls_method_proj TO lt_method_proj.


        CLEAR ls_method_proj.
        ls_method_proj-method     = 'Save'.
        APPEND ls_method_proj TO lt_method_proj.

        CLEAR: lt_message[], ls_return.
        "Exception handling is mandatory to avoid dumps
        CALL FUNCTION 'BAPI_PROJECT_MAINTAIN'
          DESTINATION lv_destination
          EXPORTING
            i_project_definition     = ls_projdef
            i_project_definition_upd = ls_projdef_upd
          IMPORTING
            return                   = ls_return
          TABLES
            i_method_project         = lt_method_proj
          " i_wbs_element_table_update = lt_element_upd
          " i_wbs_element_table      = lt_element
          " i_wbs_hierarchie_table   = lt_hierarchie
            e_message_table          = lt_message
          EXCEPTIONS
            system_failure           = 1 MESSAGE msg
            communication_failure    = 2 MESSAGE msg
            OTHERS                   = 3.

        IF sy-subrc EQ 0.
          IF ls_return-message IS INITIAL.

            CALL FUNCTION 'BAPI_PS_INITIALIZATION' DESTINATION lv_destination.
            CLEAR lt_return[].
            CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI' DESTINATION lv_destination
              EXPORTING
                i_project_definition = ls_projdef
              TABLES
                it_wbs_element       = lt_wbs_element
                et_return            = lt_return
                extensionin          = lt_extension.


            CALL FUNCTION 'BAPI_BUS2001_SET_STATUS'
              DESTINATION lv_destination
              EXPORTING
                project_definition = ls_projdef
                set_system_status  = 'REL'
              IMPORTING
                return             = ls_return.
            "   TABLES
            "    e_result           = lt_result.

        READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
        IF sy-subrc NE 0.
          CALL FUNCTION 'BAPI_PS_PRECOMMIT' DESTINATION lv_destination.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION lv_destination.
        ENDIF.

            GET TIME STAMP FIELD lv_short_time_stamp.
            uuid_x16 = system_uuid->create_uuid_x16( ).
            INSERT zta_msg FROM TABLE @( VALUE #(
            (
             logs_uuid = uuid_x16
             parent_uuid  = requestuuid
             type      = 'Success'
             sys =   'SAP'
             message = |Project Definition { ls_sap_def-projectdefinition } successfully created.|
             local_last_changed_at = lv_short_time_stamp
             )
             ) ).
            LOOP AT lt_element INTO ls_element.
              GET TIME STAMP FIELD lv_short_time_stamp.
              uuid_x16 = system_uuid->create_uuid_x16( ).
              INSERT zta_msg FROM TABLE @( VALUE #(
              (
               logs_uuid = uuid_x16
               parent_uuid  = requestuuid
               type      = 'Success'
               sys =   'SAP'
               message = |WBS Element { ls_element-wbs_element } successfully created.|
               local_last_changed_at = lv_short_time_stamp
               )
               ) ).
            ENDLOOP.
          ELSE.
            LOOP AT lt_message INTO ls_message WHERE message_type = 'E'.
              GET TIME STAMP FIELD lv_short_time_stamp.
              uuid_x16 = system_uuid->create_uuid_x16( ).
              INSERT zta_msg FROM TABLE @( VALUE #(
              (
               logs_uuid = uuid_x16
               parent_uuid  = requestuuid
               type      = 'Error'
               sys =   'SAP'
               message = |{ ls_message-message_text }|
               local_last_changed_at = lv_short_time_stamp
               )
               ) ).
            ENDLOOP.
            MODIFY ENTITIES OF zcr_request " Replace the suffix with your choosen group id.
            ENTITY request
               UPDATE FIELDS ( IntegerValue ReplicationStatus CriticalityStatus ImageUrl )
                  WITH VALUE #( ( requestuuid    = requestuuid
                                  IntegerValue  = '2'
                                  ReplicationStatus = 'Error'
                                  CriticalityStatus = '1'
                                  ImageUrl = |sap-icon://error|
                                ) )
                FAILED ls_failed
                REPORTED ls_reported.
            COMMIT ENTITIES.
          ENDIF.
        ENDIF.

      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
