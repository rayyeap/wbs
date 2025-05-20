CLASS zcl_companycode_via_rfc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_companycode_via_rfc IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
    TYPES : BEGIN OF ty_bapi_companycode_list,
              comp_code TYPE c LENGTH 4,
              comp_name TYPE c LENGTH 25,
            END OF ty_bapi_companycode_list.
    DATA: lt_companycode     TYPE STANDARD TABLE OF zce_companycode,
          lt_companycode_out TYPE STANDARD TABLE OF zce_companycode.



    "Set RFC destination
    TRY.

        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_comm_arrangement(
          comm_scenario          = 'Z_OUTBOUND_RFC_CFIN_CSCEN'   " Communication scenario
          service_id             = 'Z_OUTBOUND_RFC_CFIN_SRFC'    " Outbound service

                            ).

        DATA(lv_destination) = lo_destination->get_destination_name( ).

        "Check if data is requested
        " IF io_request->is_data_requested(  ).
        "Call BAPI
        CALL FUNCTION 'BAPI_COMPANYCODE_GETLIST'
          DESTINATION lv_destination
          TABLES
            companycode_list = lt_companycode.

        " lt_companycode = VALUE #(
        "   ( comp_code = '1000' comp_name = 'Notebook' )
        "  ( comp_code = '1000' comp_name = 'Notebook' )
        "  ).
        DATA(lv_top)     = io_request->get_paging( )->get_page_size( ).
        DATA(lv_skip)    = io_request->get_paging( )->get_offset( ).
        "IF lv_top GT 1.
        "DATA(lv_start) = lv_skip + 1.
        "DATA(lv_end) = lv_skip + lv_top.

        APPEND LINES OF lt_companycode FROM 1 TO 20 TO lt_companycode_out.

        "Output data
        IF io_request->is_total_numb_of_rec_requested(  ).
        io_response->set_total_number_of_records( lines( lt_companycode_out ) ).
        ENDIF.
        io_response->set_data( lt_companycode_out ).
"ENDIF.
        "Set total no. of records
        " io_response->set_total_number_of_records( lines( lt_companycode ) ).


        "ENDIF.

      CATCH  cx_rfc_dest_provider_error INTO DATA(lx_dest).
    ENDTRY.


  ENDMETHOD.
ENDCLASS.
