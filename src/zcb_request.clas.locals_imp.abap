CLASS lhc_Request DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF request_status,
        open     TYPE c LENGTH 1 VALUE 'O', "Open
        accepted TYPE c LENGTH 1 VALUE 'A', "Accepted
        rejected TYPE c LENGTH 1 VALUE 'X', "Rejected
        neutral  TYPE c LENGTH 1 VALUE '5', "Neutral
        waiting  TYPE c LENGTH 1 VALUE 'W', "Awaiting Approval
      END OF request_status.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Request RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Request RESULT result.

    METHODS setRequestID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Request~setRequestID.
    METHODS setStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Request~setStatusToOpen.
    "METHODS validateTitle FOR VALIDATE ON SAVE
    "IMPORTING keys FOR Request~validateTitle.
    "METHODS get_instance_features FOR INSTANCE FEATURES
    " IMPORTING keys REQUEST requested_features FOR Request RESULT result.
    METHODS validatemandatoryfields FOR VALIDATE ON SAVE
      IMPORTING keys FOR request~validatemandatoryfields.
    METHODS trigger_travelworkflow FOR DETERMINE ON SAVE
      IMPORTING keys FOR request~trigger_travelworkflow.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR request RESULT result.

    METHODS replicationValidate FOR MODIFY
      IMPORTING keys FOR ACTION request~replicationValidate RESULT result.

    "METHODS sendforApproval FOR MODIFY
    " IMPORTING keys FOR ACTION Request~sendforApproval RESULT result.

ENDCLASS.

CLASS lhc_Request IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD setRequestID.

    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request
        FIELDS ( RequestID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    DELETE requests WHERE RequestID IS NOT INITIAL.
    CHECK requests IS NOT INITIAL.

    "Get max travelID
    SELECT SINGLE FROM zta_request FIELDS MAX( request_id ) INTO @DATA(max_requestid).

    "max_requestid = max_requestid + 300000.

    "update involved instances
    MODIFY ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request
        UPDATE FIELDS ( RequestID )
        WITH VALUE #( FOR request IN requests INDEX INTO i (
                           %tky      = request-%tky
                           RequestID  = max_requestid + i ) ).

  ENDMETHOD.

  METHOD setStatusToOpen.

    READ ENTITIES OF zcr_request IN LOCAL MODE
   ENTITY Request
     FIELDS ( OverallStatus )
     WITH CORRESPONDING #( keys )
   RESULT DATA(requests).

    "If Status is already set, do nothing
    DELETE requests WHERE OverallStatus IS NOT INITIAL.
    CHECK requests IS NOT INITIAL.

    MODIFY ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR request IN requests ( %tky          = request-%tky
                                                OverallStatus = request_status-open ) ).

    MODIFY ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request
        UPDATE FIELDS ( ReplicationStatus CriticalityStatus ImageUrl )
        WITH VALUE #( FOR request IN requests ( %tky          = request-%tky
                                                ReplicationStatus = 'Pending'
                                                CriticalityStatus = request_status-neutral
                                                ImageUrl          = |sap-icon://overview-chart| ) ).
  ENDMETHOD.

  "METHOD get_instance_features.

  "ENDMETHOD.

  "METHOD sendforApproval.

  "ENDMETHOD.

  "METHOD validateTitle.
  "  READ ENTITIES OF zcr_request IN LOCAL MODE
  "  ENTITY Request
  "   FIELDS ( Title )
  "  WITH CORRESPONDING #( keys )
  " RESULT DATA(requests).

  " Raise message for empty Title
  " LOOP AT requests INTO DATA(request).

  "  APPEND VALUE #(  %tky                 = request-%tky
  "                  %state_area          = 'VALIDATE_TITLE'
  "               ) TO reported-request.

  "   IF request-title IS  INITIAL.
  " APPEND VALUE #( %tky = request-%tky ) TO failed-request.

  " APPEND VALUE #( %tky                = request-%tky
  "                %state_area         = 'VALIDATE_TITLE'
  "           %msg                = NEW /dmo/cm_flight_messages(
  "                                             textid   = /dmo/cm_flight_messages=>enter_customer_id
  "                                              severity = if_abap_behv_message=>severity-error )
  "      %element-Title = if_abap_behv=>mk-on
  "    ) TO reported-request.
  "ENDIF.

  " ENDLOOP.
  "ENDMETHOD.

  METHOD validateMandatoryFields.

    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(requests).
    "CHECK sy-uname EQ 'CB9980000000'.
    " Raise message for empty Title
    READ TABLE requests INTO DATA(request) INDEX 1.

    " Clear state messages that might exist
    APPEND VALUE #(  %tky               = request-%tky
                    %state_area        = 'VALIDATE_CHECK' )
     TO reported-request.
    APPEND VALUE #(  %tky               = request-%tky
                     %state_area        = 'VALIDATE_COMPANYCODE' )
      TO reported-request.
    APPEND VALUE #(  %tky               = request-%tky
                     %state_area        = 'VALIDATE_TITLE' )
      TO reported-request.
    APPEND VALUE #(  %tky               = request-%tky
             %state_area        = 'VALIDATE_DESCRIPTION' )
TO reported-request.
    APPEND VALUE #(  %tky               = request-%tky
             %state_area        = 'VALIDATE_REQUESTTYPE' )
TO reported-request.
    APPEND VALUE #(  %tky               = request-%tky
             %state_area        = 'VALIDATE_JUSTIFICATION' )
TO reported-request.
    APPEND VALUE #(  %tky               = request-%tky
             %state_area        = 'VALIDATE_SOURCE' )
TO reported-request.
    "IF request-CompanyCode IS  INITIAL
    IF request-title IS INITIAL
    OR request-Description IS INITIAL
    OR request-requesttype IS INITIAL
    "OR request-Justification IS INITIAL
    OR request-source IS INITIAL.
      APPEND VALUE #( %tky = request-%tky ) TO failed-request.
      "IF request-CompanyCode IS  INITIAL.

      "APPEND VALUE #(

      "                                   %tky    = request-%tky
      "                                  %state_area         = 'VALIDATE_COMPANYCODE'
      "                                 %msg    = new_message(
      "                                                            id   = 'SY'
      "                                                           number = '002'
      "                                                          v1 = 'Company Code is Required'
      "                                                         severity = if_abap_behv_message=>severity-error
      "                                                  )
      "                            %element-CompanyCode = if_abap_behv=>mk-on

      "          ) TO reported-request.

      "  ENDIF.
      IF request-title IS  INITIAL.

        APPEND VALUE #(
                                   %tky    = request-%tky
                                   %state_area         = 'VALIDATE_TITLE'
                                   %msg    = new_message(
                                                               id   = 'SY'
                                                               number = '002'
                                                               v1 = 'Title is Required'
                                                               severity = if_abap_behv_message=>severity-error
                                                         )
                                    %element-title = if_abap_behv=>mk-on
                                     ) TO reported-request.

      ENDIF.

      IF request-Description IS  INITIAL.

        APPEND VALUE #(
                                    %tky    = request-%tky
                                    %state_area         = 'VALIDATE_DESCRIPTION'
                                    %msg    = new_message(
                                                                id   = 'SY'
                                                                number = '002'
                                                                v1 = 'Description is Required'
                                                                severity = if_abap_behv_message=>severity-error
                                                          )
                                     %element-Description = if_abap_behv=>mk-on
                                     ) TO reported-request.

      ENDIF.
      IF request-requesttype IS  INITIAL.

        APPEND VALUE #(
                                    %tky    = request-%tky
                                    %state_area         = 'VALIDATE_REQUESTTYPE'
                                     %msg    = new_message(
                                                                 id   = 'SY'
                                                                 number = '002'
                                                                v1 = 'Request Type is Required'
                                                                severity = if_abap_behv_message=>severity-error
                                                           )
                                      %element-requesttype = if_abap_behv=>mk-on
                                      ) TO reported-request.

      ENDIF.
      "IF request-Justification IS  INITIAL.

      " APPEND VALUE #(
      "                            %tky    = request-%tky
      "                           %state_area         = 'VALIDATE_JUSTIFICATION'
      "                          %msg    = new_message(
      "                                                     id   = 'SY'
      "                                                    number = '002'
      "                                                   v1 = 'Justification is Required'
      "                                                  severity = if_abap_behv_message=>severity-error
      "                                           )
      "                     %element-Justification = if_abap_behv=>mk-on
      "                    ) TO reported-request.

      "   ENDIF.
      IF request-source IS  INITIAL.

        APPEND VALUE #(
                                    %tky    = request-%tky
                                    %state_area         = 'VALIDATE_SOURCE'
                                    %msg    = new_message(
                                                                id   = 'SY'
                                                                number = '002'
                                                                v1 = 'Source System [SAP WBS] is Required'
                                                                severity = if_abap_behv_message=>severity-error
                                                          )
                                     %element-source = if_abap_behv=>mk-on
                                     ) TO reported-request.

      ENDIF.
    ENDIF.


    " INSERT new_message( id       = 'SY'
    "                 number   = '002'
    "                v1 = 'Data replication validated successfully'
    "               severity = if_abap_behv_message=>severity-success )
    "INTO TABLE reported-%other.


    "LOOP AT requests INTO DATA(request).

    " Clear state messages that might exist

    "ENDLOOP.

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

    TYPES : BEGIN OF ty_projdef2,
              project_definition   TYPE c LENGTH 24,
              description          TYPE c LENGTH 40,
              mask_id              TYPE c LENGTH 24,
              wbs_status_profile   TYPE c LENGTH 8,
              responsible_no       TYPE n LENGTH 8,
              applicant_no         TYPE n LENGTH 8,
              company_code         TYPE c LENGTH 4,
              business_area        TYPE c LENGTH 4,
              controlling_area     TYPE c LENGTH 4,
              profit_ctr           TYPE c LENGTH 10,
              project_currency     TYPE c LENGTH 5,
              project_currency_iso TYPE c LENGTH 3,
              start                TYPE dats,
              finish               TYPE dats,
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
              objectclass          TYPE c LENGTH 5,
              statistical          TYPE c LENGTH 1,
              taxjurcode           TYPE c LENGTH 15,
              interest_prof        TYPE c LENGTH 7,
              wbs_sched_profile    TYPE c LENGTH 12,
              invest_profile       TYPE c LENGTH 6,
              res_anal_key         TYPE c LENGTH 6,
              plan_profile         TYPE c LENGTH 6,
              planintegrated       TYPE c LENGTH 1,
              valuation_spec_stock TYPE c LENGTH 1,
              simulation_profile   TYPE c LENGTH 7,
              grouping_indicator   TYPE c LENGTH 1,
              location             TYPE c LENGTH 10,
              partner_profile      TYPE c LENGTH 4,
              venture              TYPE c LENGTH 6,
              rec_ind              TYPE c LENGTH 2,
              equity_typ           TYPE c LENGTH 3,
              jv_otype             TYPE c LENGTH 4,
              jv_jibcl             TYPE c LENGTH 3,
              jv_jibsa             TYPE c LENGTH 5,
              sched_scenario       TYPE c LENGTH 1,
              fcst_start           TYPE dats,
              fcst_finish          TYPE dats,
              func_area            TYPE c LENGTH 16,
              salesorg             TYPE c LENGTH 4,
              distr_chan           TYPE c LENGTH 2,
              division             TYPE c LENGTH 2,
              dli_profile          TYPE c LENGTH 8,
            END OF ty_projdef2.


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

    "variables needed to call BAPI
    CONSTANTS: gc_x      TYPE char1 VALUE 'X'.
    DATA: ls_projdef2    TYPE ty_projdef2,
          ls_projdef     TYPE ty_projdef,
          ls_projdef_upd TYPE ty_projdef_upd,
          ls_return      TYPE ty_return,
          lt_method_proj TYPE STANDARD TABLE OF ty_method_proj,
          ls_method_proj TYPE ty_method_proj,
          lv_refnum      TYPE n LENGTH 6,
          lt_message     TYPE STANDARD TABLE OF ty_message,
          ls_message     TYPE ty_message,
          ls_logs        TYPE zta_logs,
          lt_return      TYPE STANDARD TABLE OF ty_return2.

    DATA  msg TYPE c LENGTH 255.

    CLEAR: ls_return, msg, lt_message[], lt_method_proj[].
    TRY.

        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_comm_arrangement(
          comm_scenario          = 'Z_OUTBOUND_RFC_CFIN_CSCEN'   " Communication scenario
          service_id             = 'Z_OUTBOUND_RFC_CFIN_SRFC'    " Outbound service
                                "comm_system_id         = 'Z_OUTBOUND_RFC_CSYS_CFIN'          " Communication system
                            ).

        DATA(lv_destination) = lo_destination->get_destination_name( ).

      CATCH cx_rfc_dest_provider_error.
    ENDTRY.

    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY request BY \_Cfin
            ALL FIELDS
      WITH CORRESPONDING #( requests )
      LINK DATA(cfin_links)
      RESULT DATA(cfins).

    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY cfin BY \_cfinItems
            ALL FIELDS
      WITH CORRESPONDING #( cfins )
      LINK DATA(cfinitems_links)
      RESULT DATA(cfinitemss).

    READ TABLE cfinitemss INTO DATA(ls_cfin_items) INDEX 1.
    IF sy-subrc NE 0.
      APPEND VALUE #(  %tky               = request-%tky
           %state_area        = 'VALIDATE_CHECK' )
        TO reported-request.
      APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      APPEND VALUE #(
         %tky    = request-%tky
        %state_area         = 'VALIDATE_CHECK'
        %msg    = new_message(
                       id   = 'ZMSG_WBS'
                            number = '001'
                         v1 = |SAP CFIN- Please add CFIN WBS Element.|
                   severity = if_abap_behv_message=>severity-error
                )
     "%element-replicationstatus = if_abap_behv=>mk-on
       ) TO reported-request.
    ENDIF.

    READ TABLE cfins INTO DATA(ls_cfin_def) INDEX 1.
    "SELECT SINGLE * FROM zcr_cfin WHERE RequestUuid = @request-RequestUuid INTO @DATA(ls_cfin_def).
    IF sy-subrc EQ 0.
      CLEAR ls_projdef2.
      ls_projdef2-project_definition = ls_cfin_def-projectdefinition.
      ls_projdef2-description        = ls_cfin_def-projectdescription.
      ls_projdef2-project_profile    = ls_cfin_def-projectprofile.
      ls_projdef2-controlling_area   = '1000'.
      ls_projdef2-company_code          = ls_cfin_def-companycode.
      ls_projdef2-plant              = ls_cfin_def-plant.
      ls_projdef2-func_area          = ls_cfin_def-functionalarea.
      ls_projdef2-profit_ctr         = ls_cfin_def-profitcenter.
      ls_projdef2-venture            = ls_cfin_def-jointventureid.
      ls_projdef2-rec_ind            = ls_cfin_def-recoveryindicator.
      ls_projdef2-equity_typ         = ls_cfin_def-equitytype.
      ls_projdef2-jv_otype           = ls_cfin_def-jvobjecttype.
      ls_projdef2-jv_jibcl           = ls_cfin_def-jvjibclass.
      ls_projdef2-jv_jibsa           = ls_cfin_def-jvjibsaclass.
      ls_projdef2-responsible_no     = ls_cfin_def-personresponsibleno.
      ls_projdef2-start              = ls_cfin_def-startdate.
      ls_projdef2-finish             = ls_cfin_def-finishdate.

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

      CLEAR lv_refnum.
      ADD 1 TO lv_refnum.
      ls_method_proj-refnumber  = lv_refnum.
      ls_method_proj-objecttype = 'ProjectDefinition'.
      ls_method_proj-method     = 'Create'.
      ls_method_proj-objectkey  = ls_projdef-project_definition.
      APPEND ls_method_proj TO lt_method_proj.

      "APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      "APPEND VALUE #(
      "%tky    = request-%tky
      " %state_area         = 'VALIDATE_CHECK'
      " %msg    = new_message(
      "   id   = 'SY'
      "  number = '002'
      "   v1 = 'CFIN System- Validation successfully'
      " severity = if_abap_behv_message=>severity-information
      "       )
      "%element-replicationstatus = if_abap_behv=>mk-on
      " ) TO reported-request.

      "APPEND VALUE #(
      "%tky    = request-%tky
      "%state_area         = 'VALIDATE_CHECK'
      "%msg    = new_message(
      "  id   = 'SY'
      "   number = '002'
      "  v1 = 'Please check the above error message'
      "  severity = if_abap_behv_message=>severity-information
      " )
      "%element-replicationstatus = if_abap_behv=>mk-on
      ") TO reported-request.

      "Exception handling is mandatory to avoid dumps
      "CALL FUNCTION 'BAPI_PROJECT_MAINTAIN'
      " DESTINATION lv_destination
      "EXPORTING
      " i_project_definition     = ls_projdef
      "i_project_definition_upd = ls_projdef_upd
      "IMPORTING
      " return                   = ls_return
      "TABLES
      " i_method_project         = lt_method_proj
      "e_message_table          = lt_message
      "EXCEPTIONS
      " system_failure           = 1 MESSAGE msg
      "communication_failure    = 2 MESSAGE msg
      "OTHERS                   = 3.
      CALL FUNCTION 'BAPI_PS_INITIALIZATION' DESTINATION lv_destination.
      CALL FUNCTION 'BAPI_BUS2001_CREATE'
        DESTINATION lv_destination
        EXPORTING
          i_project_definition = ls_projdef2
        TABLES
          et_return            = lt_return.

      IF sy-subrc EQ 0.
        DELETE lt_return WHERE number EQ '007'.
        LOOP AT lt_return INTO ls_return WHERE type = 'E'.

          APPEND VALUE #( %tky = request-%tky ) TO failed-request.

          APPEND VALUE #(
                                        %tky    = request-%tky
                                        %state_area         = 'VALIDATE_CHECK'
                                        %msg    = new_message(
                                                                    id   = 'ZMSG_WBS'
                                                                    number = '001'
                                                                    v1 = |CFIN WBS- { ls_return-message(40) }|
                                                                    v2 = |{ ls_return-message+40(50) }|
                                                                    severity = if_abap_behv_message=>severity-error
                                                              )
                                        "%element-replicationstatus = if_abap_behv=>mk-on
                                         ) TO reported-request.

        ENDLOOP.
      ELSE.
        APPEND VALUE #( %tky = request-%tky ) TO failed-request.

        APPEND VALUE #(
                                      %tky    = request-%tky
                                      %state_area         = 'VALIDATE_CHECK'
                                      %msg    = new_message(
                                                                  id   = 'SY'
                                                                  number = '002'
                                                                  v1 = |CFIN WBS- { msg }|
                                                                  severity = if_abap_behv_message=>severity-error
                                                            )
                                      "%element-replicationstatus = if_abap_behv=>mk-on
                                       ) TO reported-request.
      ENDIF.
    ELSE.
      "APPEND VALUE #(  %tky               = request-%tky
      "        %state_area        = 'VALIDATE_CHECK' )
      "    TO reported-request.

      APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      APPEND VALUE #(
                                    %tky    = request-%tky
                                    %state_area         = 'VALIDATE_CHECK'
                                    %msg    = new_message(
                                                                id   = 'SY'
                                                               number = '002'
                                                               v1 = 'CFIN WBS- Please add CFIN WBS Project Definition.'
                                                               severity = if_abap_behv_message=>severity-error
                                                        )
                                    "%element-replicationstatus = if_abap_behv=>mk-on
                                     ) TO reported-request.

    ENDIF.

    CLEAR: ls_return, msg, lt_message[], lt_method_proj[].
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

    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY request BY \_Sap
            ALL FIELDS
      WITH CORRESPONDING #( requests )
      LINK DATA(sap_links)
      RESULT DATA(saps).

    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY sap BY \_sapItems
            ALL FIELDS
      WITH CORRESPONDING #( saps )
      LINK DATA(sapitems_links)
      RESULT DATA(sapitemss).

    READ TABLE sapitemss INTO DATA(ls_sap_items) INDEX 1.
     IF sy-subrc NE 0.
     APPEND VALUE #( %tky = request-%tky ) TO failed-request.

     APPEND VALUE #(
          %tky    = request-%tky
        %state_area         = 'VALIDATE_CHECK'
        %msg    = new_message(
         id   = 'ZMSG_WBS'
       number = '001'
       v1 = |SAP WBS- Please add SAP WBS Element.|
     severity = if_abap_behv_message=>severity-error
     )
    "%element-replicationstatus = if_abap_behv=>mk-on
       ) TO reported-request.
     ENDIF.

    READ TABLE saps INTO DATA(ls_sap_def) INDEX 1.

    "SELECT SINGLE * FROM zcr_sap WHERE RequestUuid = @request-RequestUuid INTO @DATA(ls_sap_def).
    IF sy-subrc EQ 0.
      CLEAR ls_projdef.
      ls_projdef-project_definition = ls_sap_def-projectdefinition.
      ls_projdef-description        = ls_sap_def-projectdescription.
      ls_projdef-project_profile    = ls_sap_def-projectprofile.
      ls_projdef-controlling_area   = 'PET1'.
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
      ls_projdef_upd-objectclass         = gc_x.

      CLEAR lv_refnum.
      ADD 1 TO lv_refnum.
      ls_method_proj-refnumber  = lv_refnum.
      ls_method_proj-objecttype = 'ProjectDefinition'.
      ls_method_proj-method     = 'Create'.
      ls_method_proj-objectkey  = ls_projdef-project_definition.
      APPEND ls_method_proj TO lt_method_proj.

      "APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      "APPEND VALUE #(
      " %tky    = request-%tky
      "%state_area         = 'VALIDATE_CHECK'
      "%msg    = new_message(
      "   id   = 'SY'
      " number = '002'
      "  v1 = 'SAP System- Validation successfully'
      "   severity = if_abap_behv_message=>severity-information
      " )
      "%element-replicationstatus = if_abap_behv=>mk-on
      ") TO reported-request.
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
          e_message_table          = lt_message
        EXCEPTIONS
          system_failure           = 1 MESSAGE msg
          communication_failure    = 2 MESSAGE msg
          OTHERS                   = 3.


      IF sy-subrc EQ 0.

        IF ls_return-message IS NOT INITIAL.
          "APPEND VALUE #( %tky = request-%tky ) TO failed-request.

          "APPEND VALUE #(
          "                             %tky    = request-%tky
          "                            %state_area         = 'VALIDATE_CHECK'
          "                           %msg    = new_message(
          "                                                      id   = 'SY'
          "                                                     number = '002'
          "                                                    v1 = |SAP WBS- { ls_return-message }|
          "                                                   severity = if_abap_behv_message=>severity-error
          ")
          " %element-replicationstatus = if_abap_behv=>mk-on
          "                       ) TO reported-request.
        ENDIF.
        DELETE lt_message WHERE message_number = '036'.
        LOOP AT lt_message INTO ls_message WHERE message_type = 'E'.

          APPEND VALUE #( %tky = request-%tky ) TO failed-request.

          APPEND VALUE #(
                                        %tky    = request-%tky
                                        %state_area         = 'VALIDATE_CHECK'
                                        %msg    = new_message(
                                                                    id   = 'ZMSG_WBS'
                                                                     number = '001'
                                                                     v1 = |SAP WBS- { ls_message-message_text(40) }|
                                                                      v2 = |{ ls_message-message_text+40(32) }|
                                                                    severity = if_abap_behv_message=>severity-error
                                                              )
                                        "%element-replicationstatus = if_abap_behv=>mk-on
                                         ) TO reported-request.


        ENDLOOP.
      ELSE.
        APPEND VALUE #( %tky = request-%tky ) TO failed-request.

        APPEND VALUE #(
                                      %tky    = request-%tky
                                      %state_area         = 'VALIDATE_CHECK'
                                      %msg    = new_message(
                                                                  id   = 'SY'
                                                                  number = '002'
                                                                  v1 = |SAP WBS- { msg }|
                                                                  severity = if_abap_behv_message=>severity-error
                                                            )
                                      "%element-replicationstatus = if_abap_behv=>mk-on
                                       ) TO reported-request.

      ENDIF.
    ELSE.
      " APPEND VALUE #(  %tky               = request-%tky
      "%state_area        = 'VALIDATE_CHECK' )
      "TO reported-request.

      APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      APPEND VALUE #(
                                    %tky    = request-%tky
                                    %state_area         = 'VALIDATE_CHECK'
                                    %msg    = new_message(
                                                                id   = 'SY'
                                                                number = '002'
                                                                v1 = 'SAP WBS- Please add SAP WBS Project Definition.'
                                                                severity = if_abap_behv_message=>severity-error
                                                          )
                                    "%element-replicationstatus = if_abap_behv=>mk-on
                                     ) TO reported-request.
    ENDIF.

    READ ENTITIES OF zcr_request IN LOCAL MODE
  ENTITY request BY \_Approver
        ALL FIELDS
  WITH CORRESPONDING #( requests )
  LINK DATA(approver_links)
  RESULT DATA(approvers).

    READ TABLE approvers INTO DATA(ls_approver) INDEX 1.
    IF sy-subrc NE 0.
      APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      APPEND VALUE #(
                                    %tky    = request-%tky
                                    %state_area         = 'VALIDATE_CHECK'
                                    %msg    = new_message(
                                                                id   = 'SY'
                                                                number = '002'
                                                                v1 = 'Please add Approver.'
                                                                severity = if_abap_behv_message=>severity-error
                                                          )
                                    "%element-replicationstatus = if_abap_behv=>mk-on
                                     ) TO reported-request.
    ENDIF.


  ENDMETHOD.


  METHOD trigger_travelworkflow.

    IF keys IS NOT INITIAL.

      READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY request
          ALL FIELDS
          WITH CORRESPONDING #( keys )
          RESULT DATA(requests).

      DATA(ls_request) = requests[ 1 ].
      "CHECK ls_request-SendApprover EQ abap_true.
      READ ENTITIES OF zcr_request IN LOCAL MODE
        ENTITY request BY \_Approver
          FIELDS ( ApproverEmail )
        WITH CORRESPONDING #( requests )
        LINK DATA(approver_links)
        RESULT DATA(approvers).

      "SELECT SINGLE ApproverEmail FROM zcr_approver WHERE RequestUuid = @ls_request-requestuuid
      "INTO @DATA(approveremail).

      "SELECT SINGLE name FROM /DMO/I_Agency WHERE AgencyID = @ls_travel-AgencyID
      "INTO @DATA(agency_name).

      "SELECT SINGLE firstname, lastname, title FROM /DMO/I_Customer
      "WHERE CustomerID = @ls_travel-customerID
      "INTO ( @DATA(firstname), @DATA(lastname), @DATA(title) ).

      "IF sy-subrc = 0.

      "CONCATENATE title firstname lastname INTO DATA(Customer_name) SEPARATED BY space.
      DATA: lv_string_email  TYPE string,
            lv_string_email2 TYPE string,
            lv_links         TYPE string,
            lv_links1        TYPE string,
            lv_links2        TYPE string,
            lv_createdby     TYPE string.

      "lv_string_email = |https://pt-demo-cf-eu10-sbx.launchpad.cfapps.eu10.hana.ondemand.com/site/wbs#zwbs_request-display?
      "sap-ui-app-id-hint=tutorial_7031283369F466CEAC33F85F95944990&/Request(RequestUuid=guid'52eecbe6-41a8-1edf-bfea-03ceaadcc558',IsActiveEntity=true)|.

      " Convert UUID from hyphened representation into RAW16
      " given
      "CONSTANTS uuid_raw_exp TYPE sysuuid_x VALUE '0050569A14531ED5B9CB7E54178C13F0'.
      "CONSTANTS uuid_hyphened TYPE string VALUE '0050569a-1453-1ed5-b9cb-7e54178c13f0'.
      " Convert UUID from RAW16 into hyphened representation
      " given

      " when
      DATA: lv_uuid    TYPE c LENGTH 36,
            lv_request TYPE c LENGTH 32.

      lv_request = ls_request-requestuuid.

      CONCATENATE lv_request(8) lv_request+8(4) lv_request+12(4) lv_request+16(4) lv_request+20(12)
            INTO lv_uuid
            SEPARATED BY '-'.

      lv_links1 = |https://5557f00d-8a44-4456-95ad-d5a5641572a3.abap-web.eu10.hana.ondemand.com/ui?sap-ushell-config=lean#zwbs_request-display?Request(RequestUuid=guid'2EEB6B39-46FF-1FD0-82C7-5A74B4D051B7')&/Request(RequestUuid=guid'|.
      lv_links2 = |{ lv_uuid }',IsActiveEntity=true)|.
      lv_links = |{ lv_links1 }{ lv_links2 }|.
      CLEAR: lv_string_email2, lv_string_email.
      LOOP AT approvers INTO DATA(approver) WHERE levelname = 'Level 2 - CFIN WBS Approver'.
        IF approver-ApproverEmail NE ''.
          IF lv_string_email2 = ''.
            lv_string_email2 = approver-ApproverEmail.
          ELSE.
            lv_string_email2 = |{ lv_string_email2 },{ approver-ApproverEmail }|.
          ENDIF.
        ENDIF.
      ENDLOOP.

      LOOP AT approvers INTO approver WHERE levelname = 'Level 1 - SAP WBS Approver'.
        IF approver-ApproverEmail NE ''.
          IF lv_string_email = ''.
            lv_string_email = approver-ApproverEmail.
          ELSE.
            lv_string_email = |{ lv_string_email },{ approver-ApproverEmail }|.
          ENDIF.
        ENDIF.
      ENDLOOP.
      lv_createdby = ls_request-localcreatedby.
      NEW zcl_workflow( )->trigger_workflow(
            RequestID     = ls_request-RequestId
            FinancialYear = ls_request-FinancialYear
            Title         = ls_request-Title
            Description   = ls_request-Description
            CompanyCode   = ls_request-CompanyCode
            RequestType   = ls_request-RequestType
            WBSType       = ls_request-WBSType
            ProjectType   = ls_request-ProjectType
            Justification = ls_request-Justification
            Approver      = lv_string_email
            Approver2      = lv_string_email2
            Createdby     = lv_createdby
            Links         = lv_links

      ).

      " Replace the suffix with your choosen group id.
      "This is done to update the Overall Travel Status to Awaiting Approval.
      MODIFY ENTITIES OF zcr_request IN LOCAL MODE
            ENTITY request
               UPDATE FIELDS ( OverallStatus IntegerValue ReplicationStatus ImageUrl )
               WITH VALUE #( FOR key IN keys ( %tky          = key-%tky
                                          OverallStatus = request_status-waiting
                                          IntegerValue   = '1'
                                          ReplicationStatus = 'Pending'
                                          ImageUrl = |sap-icon://manager| ) )
              FAILED DATA(ls_failed)
              REPORTED DATA(ls_reported).
      "ENDIF.

      " DATA(system_uuid) = cl_uuid_factory=>create_system_uuid( ).
      " DATA(uuid_x16) = system_uuid->create_uuid_x16( ).
      "GET TIME STAMP FIELD DATA(lv_short_time_stamp).
      "INSERT zta_msg FROM TABLE @( VALUE #(
      "(
      " logs_uuid = uuid_x16
      "parent_uuid  = ls_request-RequestUuid
      "type      = 'Success'
      "sys       =   'BTP'
      "message = |Requester Submitted to Approver|
      "local_last_changed_at = lv_short_time_stamp
      ")
      ") ).

    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD replicationValidate.

    READ ENTITIES OF zcr_request IN LOCAL MODE
       ENTITY Request
         ALL FIELDS WITH CORRESPONDING #( keys )
       RESULT DATA(requests).

    READ TABLE requests INTO DATA(request) INDEX 1.
    "LOOP AT requests INTO DATA(request).

    " Clear state messages that might exist

    "ENDLOOP.

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
              "usr00                TYPE c LENGTH 20,
              "usr01                TYPE c LENGTH 20,
              "usr02                TYPE c LENGTH 10,
              "usr03                TYPE c LENGTH 10,
              "usr04(2)             TYPE p DECIMALS 3,
              "use04                TYPE c LENGTH 3,
              "usr05(2)             TYPE p DECIMALS 3,
              "use05                TYPE c LENGTH 3,
              "usr06(2)             TYPE p DECIMALS 3,
              "use06                TYPE c LENGTH 5,
              "usr07(2)             TYPE p DECIMALS 3,
              "use07                TYPE c LENGTH 5,
              "usr08                TYPE dats,
              "usr09                TYPE dats,
              "usr10                TYPE c LENGTH 1,
              "usr11                TYPE c LENGTH 1,
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
              wbs_element                    TYPE c LENGTH 24,
              project_definition             TYPE c LENGTH 24,
              description                    TYPE c LENGTH 40,
              short_id                       TYPE c LENGTH 16,
              responsible_no                 TYPE n LENGTH 8,
              applicant_no                   TYPE n LENGTH 8,
              comp_code                      TYPE c LENGTH 4,
              bus_area                       TYPE c LENGTH 4,
              co_area                        TYPE c LENGTH 4,
              profit_ctr                     TYPE c LENGTH 10,
              proj_type                      TYPE c LENGTH 2,
              network_assignment             TYPE n LENGTH 1,
              costing_sheet                  TYPE c LENGTH 6,
              overhead_key                   TYPE c LENGTH 6,
              calendar                       TYPE c LENGTH 2,
              priority                       TYPE c LENGTH 1,
              equipment                      TYPE c LENGTH 18,
              functional_location            TYPE c LENGTH 30,
              currency                       TYPE c LENGTH 5,
              currency_iso                   TYPE c LENGTH 3,
              plant                          TYPE c LENGTH 4,
              user_field_key                 TYPE c LENGTH 7,
              user_field_char20_1            TYPE c LENGTH 20,
              user_field_char20_2            TYPE c LENGTH 20,
              user_field_char10_1            TYPE c LENGTH 10,
              user_field_char10_2            TYPE c LENGTH 10,
              user_field_quan1               TYPE usrquan13,
              user_field_unit1               TYPE c LENGTH 3,
              user_field_unit1_iso           TYPE c LENGTH 3,
              user_field_quan2               TYPE usrquan13,
              user_field_unit2               TYPE c LENGTH 3,
              user_field_unit2_iso           TYPE c LENGTH 3,
              user_field_curr1               TYPE usrcurr13,
              user_field_cuky1               TYPE c LENGTH 5,
              user_field_cuky1_iso           TYPE c LENGTH 3,
              user_field_curr2               TYPE usrcurr13,
              user_field_cuky2               TYPE c LENGTH 5,
              user_field_cuky2_iso           TYPE c LENGTH 3,
              user_field_date1               TYPE dats,
              user_field_date2               TYPE dats,
              user_field_flag1               TYPE c LENGTH 1,
              user_field_flag2               TYPE c LENGTH 1,
              objectclass                    TYPE c LENGTH 2,
              statistical                    TYPE c LENGTH 1,
              taxjurcode                     TYPE c LENGTH 15,
              int_profile                    TYPE c LENGTH 7,
              joint_venture                  TYPE c LENGTH 6,
              recovery_ind                   TYPE c LENGTH 2,
              equity_type                    TYPE c LENGTH 3,
              jv_object_type                 TYPE c LENGTH 4,
              jv_jib_class                   TYPE c LENGTH 3,
              jv_jib_sub_class_a             TYPE c LENGTH 5,
              objectclass_ext                TYPE c LENGTH 5,
              wbs_planning_element           TYPE c LENGTH 1,
              wbs_account_assignment_element TYPE c LENGTH 1,
              wbs_billing_element            TYPE c LENGTH 1,
              respsbl_cctr                   TYPE c LENGTH 10,
              respsbl_cctr_controlling_area  TYPE c LENGTH 4,
              request_cctr                   TYPE c LENGTH 10,
              request_comp_code              TYPE c LENGTH 4,
              request_cctr_controlling_area  TYPE c LENGTH 4,
              location                       TYPE c LENGTH 10,
              change_no                      TYPE c LENGTH 12,
              invest_profile                 TYPE c LENGTH 6,
              res_anal_key                   TYPE c LENGTH 6,
              wbs_cctr_posted_actual         TYPE c LENGTH 10,
              wbs_basic_start_date           TYPE dats,
              wbs_basic_finish_date          TYPE dats,
              wbs_forecast_start_date        TYPE dats,
              wbs_forecast_finish_date       TYPE dats,
              wbs_actual_start_date          TYPE dats,
              wbs_actual_finish_date         TYPE dats,
              "wbs_basic_duration             TYPE PS_PDAUR,
              "wbs_basic_dur_unit             TYPE c LENGTH 3,
              "wbs_basic_dur_unit_iso         TYPE c LENGTH 3,
              "wbs_forecast_duration          TYPE p LENGTH 5 DECIMALS 1,
              "wbs_forcast_dur_unit           TYPE c LENGTH 3,
              "wbs_forecast_dur_unit_iso      TYPE c LENGTH 3,
              "wbs_actual_duration            TYPE p LENGTH 5 DECIMALS 1,
              "wbs_actual_dur_unit            TYPE c LENGTH 3,
              "wbs_actual_dur_unit_iso        TYPE c LENGTH 3,
              "func_area                      TYPE c LENGTH 4,
              "func_area_long                 TYPE c LENGTH 16,
              "inv_reason                     TYPE c LENGTH 2,
              "scale                          TYPE c LENGTH 2,
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
    IF sy-uname NE 'CB9980000000'.
      IF request-ReplicationStatus NE 'Error'.
        APPEND VALUE #(  %tky               = request-%tky
                  %state_area        = 'VALIDATE_CHECK' )
               TO reported-request.

        APPEND VALUE #( %tky = request-%tky ) TO failed-request.

        APPEND VALUE #(
                                      %tky    = request-%tky
                                      %state_area         = 'VALIDATE_CHECK'
                                      %msg    = new_message(
                                                                  id   = 'SY'
                                                                  number = '002'
                                                                  v1 = 'Replication in not allow in current status.'
                                                                  severity = if_abap_behv_message=>severity-information
                                                            )
                                      "%element-replicationstatus = if_abap_behv=>mk-on
                                       ) TO reported-request.
      ENDIF.

      CHECK request-ReplicationStatus = 'Error'.
    ENDIF.
    CLEAR: ls_return, msg, lt_message[], lt_method_proj[], lt_proj_wbs_history[].
    TRY.

        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_comm_arrangement(
          comm_scenario          = 'Z_OUTBOUND_RFC_CFIN_CSCEN'   " Communication scenario
          service_id             = 'Z_OUTBOUND_RFC_CFIN_SRFC'    " Outbound service
                                "comm_system_id         = 'Z_OUTBOUND_RFC_CSYS_CFIN'          " Communication system
                            ).

        DATA(lv_destination) = lo_destination->get_destination_name( ).

      CATCH cx_rfc_dest_provider_error.
    ENDTRY.

    SELECT * FROM zcr_cfin WHERE RequestUuid = @request-RequestUuid INTO TABLE @DATA(lt_cfin).
    LOOP AT lt_cfin INTO DATA(ls_cfin_def).
      "IF sy-subrc EQ 0.
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

      CLEAR lv_refnum.

      SELECT * FROM zcr_cfin_items WHERE RequestUuid = @request-RequestUuid AND CfinUuid = @ls_cfin_def-CfinUuid INTO TABLE @DATA(lt_cfin_items) .
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
        ls_element-joint_venture      = ls_cfin_items-jointventureid.
        ls_element-recovery_ind       = ls_cfin_items-recoveryindicator.
        ls_element-equity_type        = ls_cfin_items-equitytype.
        ls_element-jv_object_type     = ls_cfin_items-jvobjecttype.
        ls_element-jv_jib_class       = ls_cfin_items-jvjibclass.
        ls_element-jv_jib_sub_class_a = ls_cfin_items-jvjibsaclass.
        ls_element-respsbl_cctr       = ls_cfin_items-ResponsibleCostCenter.
        ls_element-request_cctr       = ls_cfin_items-RequestingCostCenter.
        "ls_element-func_area          = ls_cfin_items-FunctionalArea.
        ls_element-costing_sheet      = ls_cfin_items-CostingSheet.
        ls_element-wbs_account_assignment_element = ls_cfin_items-AccountAssignmentElement.
        APPEND ls_element TO lt_element.

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

      "APPEND VALUE #(  %tky               = request-%tky
      "  %state_area        = 'VALIDATE_CHECK' )
      "TO reported-request.

      "APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      "APPEND VALUE #(
      "                             %tky    = request-%tky
      "                            %state_area         = 'VALIDATE_CHECK'
      "                           %msg    = new_message(
      "                                                      id   = 'SY'
      "                                                     number = '002'
      "                                                    v1 = 'CFIN System- Validation & Replication successfully'
      "                                                   severity = if_abap_behv_message=>severity-information
      "                                            )
      "%element-replicationstatus = if_abap_behv=>mk-on
      "                      ) TO reported-request.

      " APPEND VALUE #(
      " %tky    = request-%tky
      "%state_area         = 'VALIDATE_CHECK'
      "%msg    = new_message(
      "       id   = 'SY'
      "     number = '002'
      "   v1 = 'Please check the above error message'
      " severity = if_abap_behv_message=>severity-information
      " )
      "%element-replicationstatus = if_abap_behv=>mk-on
      ") TO reported-request.

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
        IF ls_return-message NE '' OR sy-uname EQ 'CB9980000000'.
          APPEND VALUE #( %tky = request-%tky ) TO failed-request.

          "APPEND VALUE #(
          " %tky    = request-%tky
          " %state_area         = 'VALIDATE_CHECK'
          " %msg    = new_message(
          " id   = 'SY'
          "    number = '002'
          "   v1 = |CFIN- { ls_return-message }|
          "    severity = if_abap_behv_message=>severity-error
          " )
          " %element-replicationstatus = if_abap_behv=>mk-on
          "  ) TO reported-request.
          " ELSE.
          APPEND VALUE #( %tky = request-%tky ) TO failed-request.
          APPEND VALUE #(
%tky    = request-%tky
%state_area         = 'VALIDATE_CHECK'
%msg    = new_message(
                           id   = 'ZMSG_WBS'
                           number = '001'
                           v1 = |Project Definition { ls_projdef-project_definition } |
                           v2 = |successfully created.|
                           severity = if_abap_behv_message=>severity-success
                     )
" %element-replicationstatus = if_abap_behv=>mk-on
) TO reported-request.
          "Create WBS Element after project definition created
          CALL FUNCTION 'BAPI_PS_INITIALIZATION' DESTINATION lv_destination.
          CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI' DESTINATION lv_destination
            EXPORTING
              i_project_definition = ls_projdef
            TABLES
              it_wbs_element       = lt_wbs_element
              et_return            = lt_return.
          READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
          IF sy-subrc NE 0.
            CALL FUNCTION 'BAPI_PS_PRECOMMIT' DESTINATION lv_destination.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION lv_destination.
          ENDIF.
          "ENDIF.
          DELETE lt_message WHERE message_number = '280'.
          DELETE lt_message WHERE message_number = '036'.
          LOOP AT lt_message INTO ls_message. " WHERE message_type EQ 'E'.

            APPEND VALUE #( %tky = request-%tky ) TO failed-request.

            CASE ls_message-message_type.
              WHEN 'E'.
                APPEND VALUE #(
                                              %tky    = request-%tky
                                              %state_area         = 'VALIDATE_CHECK'
                                              %msg    = new_message(
                                                                          id   = 'ZMSG_WBS'
                                                                          number = '001'
                                                                           v1 = |CFIN WBS- { ls_message-message_text(40) }|
                                                                           v2 = |{ ls_message-message_text+40(32) }|
                                                                          severity = if_abap_behv_message=>severity-error
                                                                    )
                                              "%element-replicationstatus = if_abap_behv=>mk-on
                                               ) TO reported-request.
              WHEN 'S'.
                "     APPEND VALUE #(
                " %tky    = request-%tky
                " %state_area         = 'VALIDATE_CHECK'
                " %msg    = new_message(
                "                            id   = 'SY'
                "                           number = '002'
                "                           v1 = |CFIN WBS- { ls_message-message_text }|
                "                       severity = if_abap_behv_message=>severity-success
                "                   )
                "%element-replicationstatus = if_abap_behv=>mk-on
                ") TO reported-request.

            ENDCASE.
          ENDLOOP.
        ELSE.
          APPEND VALUE #( %tky = request-%tky ) TO failed-request.

          APPEND VALUE #(
                                        %tky    = request-%tky
                                        %state_area         = 'VALIDATE_CHECK'
                                        %msg    = new_message(
                                                                    id   = 'SY'
                                                                    number = '002'
                                                                    v1 = |CFIN- { msg }|
                                                                    severity = if_abap_behv_message=>severity-error
                                                              )
                                        "%element-replicationstatus = if_abap_behv=>mk-on
                                         ) TO reported-request.
        ENDIF.
      ENDIF.
    ENDLOOP.
    CLEAR: ls_return, msg, lt_message[], lt_method_proj[], lt_element[], lt_element_upd[], lt_hierarchie[], lt_wbs_element[], lt_proj_wbs_history[].
    CLEAR: l_left_ele, l_up_ele, l_cur_proj, l_prev_proj, l_cur_seq, l_cur_lvl, l_prev_lvl, l_l, l_seq, l_exist.
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

    SELECT * FROM zcr_sap WHERE RequestUuid = @request-RequestUuid INTO TABLE @DATA(lt_sap).
    LOOP AT lt_sap INTO DATA(ls_sap_def).
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

      CLEAR: lv_refnum, l_cur_lvl.

      SELECT * FROM zcr_sap_items WHERE RequestUuid = @request-RequestUuid AND SapUuid = @ls_sap_def-SapUuid INTO TABLE @DATA(lt_sap_items) .
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
        ls_element-joint_venture      = ls_sap_items-jointventureid.
        ls_element-recovery_ind       = ls_sap_items-recoveryindicator.
        ls_element-equity_type        = ls_sap_items-equitytype.
        ls_element-jv_object_type     = ls_sap_items-jvobjecttype.
        ls_element-jv_jib_class       = ls_sap_items-jvjibclass.
        ls_element-jv_jib_sub_class_a = ls_sap_items-jvjibsaclass.
        ls_element-respsbl_cctr       = ls_sap_items-ResponsibleCostCenter.
        ls_element-request_cctr       = ls_sap_items-RequestingCostCenter.
        "ls_element-func_area          = ls_sap_items-FunctionalArea.
        ls_element-costing_sheet      = ls_sap_items-CostingSheet.
        ls_element-wbs_account_assignment_element = ls_sap_items-AccountAssignmentElement.
        "ls_element-user_field_char10_1 = ls_sap_items-cfinwbs.
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
        ls_element_upd-wbs_account_assignment_element = gc_x.
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

      "APPEND VALUE #( %tky = request-%tky ) TO failed-request.

      "APPEND VALUE #(
      "                             %tky    = request-%tky
      "                            %state_area         = 'VALIDATE_CHECK'
      "                           %msg    = new_message(
      "                                                      id   = 'SY'
      "                                                     number = '002'
      "                                                    v1 = 'SAP System- Validation & Replication successfully'
      "                                                   severity = if_abap_behv_message=>severity-information
      "                                            )
      "%element-replicationstatus = if_abap_behv=>mk-on
      "                      ) TO reported-request.
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

        "IF ls_return-message IS NOT INITIAL.
        "   APPEND VALUE #( %tky = request-%tky ) TO failed-request.

        "APPEND VALUE #(
        "     %tky    = request-%tky
        "    %state_area         = 'VALIDATE_CHECK'
        "   %msg    = new_message(
        "             id   = 'SY'
        "         number = '002'
        "         v1 = |SAP- { ls_return-message }|
        "          severity = if_abap_behv_message=>severity-error
        "    )
        " %element-replicationstatus = if_abap_behv=>mk-on
        "  ) TO reported-request.
        " ELSE.
        APPEND VALUE #( %tky = request-%tky ) TO failed-request.
        APPEND VALUE #(
%tky    = request-%tky
%state_area         = 'VALIDATE_CHECK'
%msg    = new_message(
                         id   = 'ZMSG_WBS'
                       number = '001'
                     v1 = |Project Definition { ls_projdef-project_definition } |
                     v2 = |successfully created.|
                         severity = if_abap_behv_message=>severity-success
                   )
" %element-replicationstatus = if_abap_behv=>mk-on
) TO reported-request.
        CLEAR lt_return[].
        "Create WBS Element after project definition created
        CALL FUNCTION 'BAPI_PS_INITIALIZATION' DESTINATION lv_destination.
        CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI' DESTINATION lv_destination
          EXPORTING
            i_project_definition = ls_projdef
          TABLES
            it_wbs_element       = lt_wbs_element
            et_return            = lt_return
            extensionin          = lt_extension.

        READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
        IF sy-subrc NE 0.
          CALL FUNCTION 'BAPI_PS_PRECOMMIT' DESTINATION lv_destination.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION lv_destination.
        ENDIF.
        " ENDIF.
        DELETE lt_message WHERE message_number = '280'.
        DELETE lt_message WHERE message_number = '036'.
        LOOP AT lt_message INTO ls_message. " WHERE message_type EQ 'E'.

          APPEND VALUE #( %tky = request-%tky ) TO failed-request.

          CASE ls_message-message_type.
            WHEN 'E'.

              APPEND VALUE #(
                                            %tky    = request-%tky
                                            %state_area         = 'VALIDATE_CHECK'
                                            %msg    = new_message(
                                                                        id   = 'ZMSG_WBS'
                                                                    number = '001'
                                                                     v1 = |SAP WBS- { ls_message-message_text(40) }|
                                                                     v2 = |{ ls_message-message_text+40(32) }|
                                                                        severity = if_abap_behv_message=>severity-error
                                                                  )
                                            "%element-replicationstatus = if_abap_behv=>mk-on
                                             ) TO reported-request.
            WHEN 'S'.
              " APPEND VALUE #(
              " %tky    = request-%tky
              " %state_area         = 'VALIDATE_CHECK'
              " %msg    = new_message(
              "          id   = 'SY'
              "         number = '002'
              "         v1 = |SAP- { ls_message-message_text }|
              "         severity = if_abap_behv_message=>severity-success
              "   )
              "%element-replicationstatus = if_abap_behv=>mk-on
              " ) TO reported-request.

          ENDCASE.
        ENDLOOP.
      ELSE.
        APPEND VALUE #( %tky = request-%tky ) TO failed-request.

        APPEND VALUE #(
                                      %tky    = request-%tky
                                      %state_area         = 'VALIDATE_CHECK'
                                      %msg    = new_message(
                                                                  id   = 'SY'
                                                                  number = '002'
                                                                  v1 = |SAP- { msg }|
                                                                  severity = if_abap_behv_message=>severity-error
                                                            )
                                      "%element-replicationstatus = if_abap_behv=>mk-on
                                       ) TO reported-request.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
