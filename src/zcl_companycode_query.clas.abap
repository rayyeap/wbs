CLASS zcl_companycode_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES ty_response_tab TYPE STANDARD TABLE OF zcdi_company_vh WITH EMPTY KEY.
ENDCLASS.



CLASS zcl_companycode_query IMPLEMENTATION.


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
    DATA(selopt_rootname_code) = VALUE #( filters[ name = 'COMPCODE' ]-range OPTIONAL ).
    DATA(selopt_rootname_name) = VALUE #( filters[ name = 'COMPNAME' ]-range OPTIONAL ).
    " VALIDATE SELECT-OPTIONS
    "- We may not process all behavior in the system
    IF selopt_rootname_code IS INITIAL.
      " RAISE EXCEPTION NEW zcx_rap_query_prov_not_im( ).
    ENDIF.

    TYPES : BEGIN OF ty_bapi_companycode_list,
              comp_code TYPE c LENGTH 4,
              comp_name TYPE c LENGTH 25,
            END OF ty_bapi_companycode_list.

    TRY.

        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_comm_arrangement(
          comm_scenario          = 'Z_OUTBOUND_RFC_SAP_CSCEN'   " Communication scenario
          service_id             = 'Z_OUTBOUND_RFC_SAP_SRFC'    " Outbound service
                                "comm_system_id         = 'Z_OUTBOUND_RFC_CSYS_CFIN'          " Communication system
                            ).

        DATA(lv_destination) = lo_destination->get_destination_name( ).


        "variables needed to call BAPI

        DATA lt_companycode_list TYPE STANDARD TABLE OF  ty_bapi_companycode_list.
        DATA ls_companycode_list TYPE ty_bapi_companycode_list.
        DATA msg TYPE c LENGTH 255.
        DATA: lt_create TYPE STANDARD TABLE OF  zcdi_company_vh WITH EMPTY KEY,
              lt_tab    TYPE STANDARD TABLE OF  zcdi_company_vh WITH EMPTY KEY,
              ls_tab    LIKE LINE OF lt_tab.

        "Exception handling is mandatory to avoid dumps
        CALL FUNCTION 'BAPI_COMPANYCODE_GETLIST'
          DESTINATION lv_destination
          TABLES
            companycode_list      = lt_companycode_list
          EXCEPTIONS
            system_failure        = 1 MESSAGE msg
            communication_failure = 2 MESSAGE msg
            OTHERS                = 3.
    IF selopt_rootname_code IS NOT INITIAL.
      DELETE lt_companycode_list WHERE comp_code NOT IN selopt_rootname_code.
    ENDIF.

    IF selopt_rootname_name IS NOT INITIAL.
      DELETE lt_companycode_list WHERE comp_name NOT IN selopt_rootname_name.
    ENDIF.
        "CASE sy-subrc.
        "WHEN 0.
        "LOOP AT lt_companycode_list INTO ls_companycode_list.
        "APPEND VALUE #( compcode = ls_companycode_list-comp_code compname = ls_companycode_list-comp_name ) TO lt_create.
        "ENDLOOP.
        "ENDCASE.
      CATCH cx_rfc_dest_provider_error.
        "handle exception
    ENDTRY.

    DATA(lv_top) = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).
    DATA(lv_max_rows) = COND #( WHEN lv_top = if_rap_query_paging=>page_size_unlimited THEN 0
    ELSE lv_top ).


    DATA(top)               = io_request->get_paging( )->get_page_size( ).
    DATA(skip)              = io_request->get_paging( )->get_offset( ).
    DATA(requested_fields)  = io_request->get_requested_elements( ).
    DATA(sort_order)        = io_request->get_sort_elements( ).


    " First time get records from 0 to 20 (assuming page size 20)

    " Second time get records from 21 to 40 and next 31 to 60
    lv_max_rows = lv_skip + lv_top.
    IF lv_skip > 0.
      lv_skip = lv_skip + 1.
    ENDIF.

    DATA(lv_start) = skip + 1.
    DATA(lv_end) = skip + top.

    " Fill records based on Page size (Ex Assume page size of so fill each time records from0..20 , 21..40)

    LOOP AT lt_companycode_list ASSIGNING FIELD-SYMBOL(<lfs_out_line_item>)
    "FROM lv_skip TO lv_max_rows.
    FROM lv_start TO lv_end.
      ls_tab-compcode = <lfs_out_line_item>-comp_code .
      ls_tab-compname = <lfs_out_line_item>-comp_name .
      APPEND ls_tab TO lt_tab.
    ENDLOOP.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_tab ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_tab ).
    ENDIF.

    io_request->get_sort_elements( ).
    io_request->get_paging( ).
  ENDMETHOD.

ENDCLASS.
