CLASS zcl_profitcenter_cfin_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES ty_response_tab TYPE STANDARD TABLE OF zcdi_profitcenter_cfin_vh WITH EMPTY KEY.
ENDCLASS.



CLASS zcl_profitcenter_cfin_query IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    DATA response TYPE ty_response_tab.
    IF NOT io_request->is_data_requested( ).
      RETURN.
    ENDIF.

    " GET SELECT-OPTIONS
    TRY.
        DATA(filters) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(ex_ranges).
        "RAISE EXCEPTION NEW zcx_rap_query_prov_not_im( previous = ex_ranges ).
    ENDTRY.
    DATA(selopt_rootname_code) = VALUE #( filters[ name = 'PROFITCENTER' ]-range OPTIONAL ).
    DATA(selopt_rootname_name) = VALUE #( filters[ name = 'PROFITCENTERNAME' ]-range OPTIONAL ).
    " VALIDATE SELECT-OPTIONS
    "- We may not process all behavior in the system
    IF selopt_rootname_code IS INITIAL.
      " RAISE EXCEPTION NEW zcx_rap_query_prov_not_im( ).
    ENDIF.
    TYPES : BEGIN OF ty_bapi_profitcenter_list,
              co_area        TYPE c LENGTH 4,
              profit_ctr     TYPE c LENGTH 10,
              valid_to       TYPE dats,
              pctr_name      TYPE c LENGTH 20,
              in_charge      TYPE c LENGTH 20,
              in_charge_user TYPE c LENGTH 12,
            END OF ty_bapi_profitcenter_list.

    TYPES : BEGIN OF ty_return,
              type       TYPE c LENGTH 1,
              code       TYPE c LENGTH 5,
              message    TYPE c LENGTH 220,
              log_no     TYPE c LENGTH 20,
              log_msg_no TYPE n LENGTH 6,
              message_v1 TYPE c LENGTH 50,
              message_v2 TYPE c LENGTH 50,
              message_v3 TYPE c LENGTH 50,
              message_v4 TYPE c LENGTH 50,
            END OF ty_return.

    TYPES : BEGIN OF ty_controllingarea,
              kokrs TYPE c LENGTH 4,
              " prctr TYPE c LENGTH 10,
            END OF ty_controllingarea.
    TRY.

        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_comm_arrangement(
          comm_scenario          = 'Z_OUTBOUND_RFC_CFIN_CSCEN'   " Communication scenario
          service_id             = 'Z_OUTBOUND_RFC_CFIN_SRFC'    " Outbound service
          "comm_scenario          = 'Z_OUTBOUND_RFC_SAP_CSCEN'   " Communication scenario
          "service_id             = 'Z_OUTBOUND_RFC_SAP_SRFC'    " Outbound service
                                "comm_system_id         = 'Z_OUTBOUND_RFC_CSYS_CFIN'          " Communication system
                            ).

        DATA(lv_destination) = lo_destination->get_destination_name( ).


        "variables needed to call BAPI

        DATA lt_profitcenter_list TYPE STANDARD TABLE OF  ty_bapi_profitcenter_list.
        DATA ls_profitcenter_list TYPE ty_bapi_profitcenter_list.
        DATA msg TYPE c LENGTH 255.
        DATA: lt_create          TYPE STANDARD TABLE OF  zcdi_profitcenter_cfin_vh WITH EMPTY KEY,
              lt_tab             TYPE STANDARD TABLE OF  zcdi_profitcenter_cfin_vh WITH EMPTY KEY,
              ls_tab             LIKE LINE OF lt_tab,
              ls_return          TYPE ty_return,
              ls_controllingarea TYPE ty_controllingarea,
              lv_kokrs           TYPE c LENGTH 4.

        lv_kokrs = ls_controllingarea-kokrs = '1000'.

        "Exception handling is mandatory to avoid dumps
        CALL FUNCTION 'BAPI_PROFITCENTER_GETLIST'
          DESTINATION lv_destination
          EXPORTING
            controllingarea       = lv_kokrs
            personincharge        = '%'
            date                  = sy-datum
            in_charge_user        = '%'
          IMPORTING
            return                = ls_return
          TABLES
            profitcenter_list     = lt_profitcenter_list
          EXCEPTIONS
            system_failure        = 1 MESSAGE msg
            communication_failure = 2 MESSAGE msg
            OTHERS                = 3.

        CASE sy-subrc.
          WHEN 0.
            "LOOP AT lt_companycode_list INTO ls_companycode_list.
            "APPEND VALUE #( compcode = ls_companycode_list-comp_code compname = ls_companycode_list-comp_name ) TO lt_create.
            "ENDLOOP.
            IF selopt_rootname_code IS NOT INITIAL.
              DELETE lt_profitcenter_list WHERE profit_ctr NOT IN selopt_rootname_code.
            ENDIF.

            IF selopt_rootname_name IS NOT INITIAL.
              DELETE lt_profitcenter_list WHERE pctr_name NOT IN selopt_rootname_name.
            ENDIF.
        ENDCASE.
      CATCH cx_rfc_dest_provider_error.
        "handle exception
    ENDTRY.

    DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).
    DATA(lv_max_rows) = COND #( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited THEN 0
    ELSE lv_page_size ).

    " First time get records from 0 to 20 (assuming page size 20)

    " Second time get records from 21 to 40 and next 31 to 60
    lv_max_rows = lv_skip + lv_page_size.
    IF lv_skip > 0.
      lv_skip = lv_skip + 1.
    ENDIF.

    " Fill records based on Page size (Ex Assume page size of so fill each time records from0..20 , 21..40)

    LOOP AT lt_profitcenter_list ASSIGNING FIELD-SYMBOL(<lfs_out_line_item>)
    FROM lv_skip TO lv_max_rows.
      ls_tab-ProfitCenter = <lfs_out_line_item>-profit_ctr .
      ls_tab-ProfitCenterName = <lfs_out_line_item>-pctr_name .
      APPEND ls_tab TO lt_tab.
    ENDLOOP.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_tab ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_tab ) ).
    ENDIF.

    io_request->get_sort_elements( ).
    io_request->get_paging( ).
  ENDMETHOD.
ENDCLASS.
