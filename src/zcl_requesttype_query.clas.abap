CLASS zcl_requesttype_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_requesttype_query IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
    DATA: lt_create TYPE STANDARD TABLE OF  zcdi_requesttype_vh WITH EMPTY KEY.

    lt_create = VALUE #( ( requesttype = 'New' )
                         ( requesttype = 'Append' ) ).

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_create ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_create ) ).
    ENDIF.

    io_request->get_sort_elements( ).
    io_request->get_paging( ).
  ENDMETHOD.
ENDCLASS.
