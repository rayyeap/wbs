CLASS zcl_system_info_rfc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_system_info_rfc IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_comm_arrangement(
          comm_scenario          = 'Z_OUTBOUND_RFC_CFIN_CSCEN'   " Communication scenario
          service_id             = 'Z_OUTBOUND_RFC_CFIN_SRFC'    " Outbound service
                            ).

        DATA(lv_destination) = lo_destination->get_destination_name( ).
        DATA lv_result TYPE zIF_TYPES_FOR_SYSTEM_INFO=>rfcsi.
        DATA msg TYPE c LENGTH 255.

        CALL FUNCTION 'RFC_GET_SYSTEM_INFO'
          DESTINATION lv_destination
          IMPORTING
            rfcsi_export          = lv_result
          EXCEPTIONS
            system_failure        = 1 MESSAGE msg
            communication_failure = 2 MESSAGE msg
            OTHERS                = 3.
        CASE sy-subrc.
          WHEN 0.
            out->write( lv_result ).
          WHEN 1.
            out->write( | EXCEPTION SYSTEM_FAILURE | && msg ).
          WHEN 2.
            out->write( | EXCEPTION COMMUNICATION_FAILURE | && msg ).
          WHEN 3.
            out->write( | EXCEPTION OTHERS | ).
        ENDCASE.

      CATCH cx_root INTO DATA(lx_root).
        out->write( lx_root->get_text( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
