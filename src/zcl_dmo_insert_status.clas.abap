CLASS zcl_dmo_insert_status DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES: if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.

CLASS zcl_dmo_insert_status IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    TRY.

    DATA:it_stat TYPE TABLE OF /dmo/oall_stat_t,
         it_header TYPE TABLE OF /dmo/oall_stat.

      it_stat = VALUE #(
        ( overall_status = 'W' language ='E' text =  'Awaiting Approval' ) ).

       "INSERT /dmo/oall_stat_t FROM TABLE @it_stat.

       it_header = VALUE #(
        ( overall_status = 'W' ) ).

        INSERT /dmo/oall_stat FROM TABLE @it_header.

ENDTRY.
  ENDMETHOD.

ENDCLASS.

