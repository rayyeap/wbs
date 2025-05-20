CLASS zcl_companycode DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_companycode IMPLEMENTATION.


METHOD if_oo_adt_classrun~main.


    " ABAP source code for type definition for BAPI_EPM_PRODUCT_HEADER
    " generated on: ...

    TYPES : BEGIN OF ty_bapi_companycode_list,
              comp_code     TYPE c LENGTH 4,
              comp_name     TYPE c LENGTH 25,
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

        "Exception handling is mandatory to avoid dumps
        CALL FUNCTION 'BAPI_COMPANYCODE_GETLIST'
          DESTINATION lv_destination
          TABLES
            companycode_list      = lt_companycode_list
          EXCEPTIONS
            system_failure        = 1 MESSAGE msg
            communication_failure = 2 MESSAGE msg
            OTHERS                = 3.

        CASE sy-subrc.
          WHEN 0.
            LOOP AT lt_companycode_list INTO ls_companycode_list.
              out->write( ls_companycode_list-comp_code && ls_companycode_list-comp_name ).

            ENDLOOP.
            out->write( lines( lt_companycode_list ) ).
          WHEN 1.
            out->write( |EXCEPTION SYSTEM_FAILURE | && msg ).
          WHEN 2.
            out->write( |EXCEPTION COMMUNICATION_FAILURE | && msg ).
          WHEN 3.
            out->write( |EXCEPTION OTHERS| ).
        ENDCASE.

      CATCH cx_root INTO DATA(lx_root).
        out->write(  lx_root->get_longtext( ) ).

    ENDTRY.
  ENDMETHOD.
ENDCLASS.
