CLASS zcl_scope_page_space DEFINITION
PUBLIC
FINAL
CREATE PUBLIC .

PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
PROTECTED SECTION.
PRIVATE SECTION.
ENDCLASS.



CLASS zcl_scope_page_space IMPLEMENTATION.
METHOD if_oo_adt_classrun~main.


    DATA(lo_scope_api) = cl_aps_bc_scope_change_api=>create_instance( ).

    lo_scope_api->scope(
    EXPORTING it_object_scope = VALUE #(
    pgmid = if_aps_bc_scope_change_api=>gc_tadir_pgmid-R3TR
    scope_state = if_aps_bc_scope_change_api=>gc_scope_state-ON

* Space template
   ( object = if_aps_bc_scope_change_api=>gc_tadir_object-UIST obj_name = 'ZWBS_REQUEST_ST' )

* Page template
    ( object = if_aps_bc_scope_change_api=>gc_tadir_object-UIPG obj_name = 'ZWBS_REQUEST_PG' )
    )

            iv_simulate = abap_false
            iv_force = abap_false
    IMPORTING et_object_result = DATA(lt_results)
            et_message = DATA(lt_messages) ).
ENDMETHOD.

ENDCLASS.
