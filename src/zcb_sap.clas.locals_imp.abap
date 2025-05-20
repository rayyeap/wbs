CLASS lhc_Sap DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Sap~validateDates.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Sap RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Sap RESULT result.

    METHODS setSapID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Sap~setSapID.

ENDCLASS.

CLASS lhc_Sap IMPLEMENTATION.

**********************************************************************
* Validation: Check the validity of begin and end dates
**********************************************************************
  METHOD validateDates.
    CHECK sy-subrc EQ '3'.
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Sap BY \_Request
        FIELDS (  RequestUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    " Read all cfins for all affected requests
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request BY \_Sap
        FIELDS ( SapID )
        WITH CORRESPONDING #( requests )
        LINK DATA(sap_links)
      RESULT DATA(saps).

    LOOP AT saps INTO DATA(sap).

      APPEND VALUE #(  %tky               = sap-%tky
                       %state_area        = 'VALIDATE_DATES' ) TO reported-sap.

      IF sap-StartDate IS INITIAL.
        APPEND VALUE #( %tky = sap-%tky ) TO failed-sap.

        APPEND VALUE #( %tky               = sap-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                severity = if_abap_behv_message=>severity-error )
                      %element-StartDate = if_abap_behv=>mk-on ) TO reported-sap.
      ENDIF.
      IF sap-StartDate < cl_abap_context_info=>get_system_date( ) AND sap-StartDate IS NOT INITIAL.
        APPEND VALUE #( %tky               = sap-%tky ) TO failed-sap.

        APPEND VALUE #( %tky               = sap-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = NEW /dmo/cm_flight_messages(
                                                                begin_date = sap-StartDate
                                                                textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-StartDate = if_abap_behv=>mk-on ) TO reported-sap.
      ENDIF.
      IF sap-Finishdate IS INITIAL.
        APPEND VALUE #( %tky = sap-%tky ) TO failed-sap.

        APPEND VALUE #( %tky               = sap-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg                = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                               severity = if_abap_behv_message=>severity-error )
                        %element-Finishdate   = if_abap_behv=>mk-on ) TO reported-sap.
      ENDIF.
      IF sap-Finishdate < sap-StartDate AND sap-StartDate IS NOT INITIAL
                                           AND sap-finishdate IS NOT INITIAL.
        APPEND VALUE #( %tky = sap-%tky ) TO failed-sap.

        APPEND VALUE #( %tky               = sap-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                                textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                                begin_date = sap-StartDate
                                                                end_date   = sap-Finishdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-StartDate = if_abap_behv=>mk-on
                        %element-finishdate   = if_abap_behv=>mk-on ) TO reported-sap.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD setSapID.
    DATA:
      max_sapid  TYPE /dmo/booking_id,
      sap_update TYPE TABLE FOR UPDATE zcr_request\\sap,
      sap        TYPE STRUCTURE FOR READ RESULT zcr_sap.

    "Read all request for the requested saps
    " If multiple saps of the same request are requested, the request is returned only once.
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY sap BY \_Request
        FIELDS ( RequestUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    " Read all saps for all affected requests
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request BY \_Sap
        FIELDS ( sapID )
        WITH CORRESPONDING #( requests )
        LINK DATA(sap_links)
      RESULT DATA(saps).

    " Process all affected request.
    LOOP AT requests INTO DATA(request).

      " find max used sapID in all saps of this request
      max_sapid = '0000'.
      LOOP AT sap_links INTO DATA(sap_link) USING KEY id WHERE source-%tky = request-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        sap = saps[ KEY id  %tky = sap_link-target-%tky ].
        IF sap-SapID > max_sapid.
          max_sapid = sap-sapID.
        ENDIF.
      ENDLOOP.

      "Provide a sap ID for all saps of this request that have none.
      LOOP AT sap_links INTO sap_link USING KEY id WHERE source-%tky = request-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        sap = saps[ KEY id  %tky = sap_link-target-%tky ].
        IF sap-sapID IS INITIAL.
          max_sapid += 1.
          APPEND VALUE #( %tky      = sap-%tky
                          sapID = max_sapid
                        ) TO sap_update.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " Provide a sap ID for all saps that have none.
    MODIFY ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY sap
        UPDATE FIELDS ( sapID )
        WITH sap_update.
  ENDMETHOD.

ENDCLASS.
