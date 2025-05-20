CLASS lhc_Cfinitems DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS setCfinitemsID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Cfinitems~setCfinitemsID.

ENDCLASS.

CLASS lhc_Cfinitems IMPLEMENTATION.

  METHOD setCfinitemsID.
    DATA:
      max_cfinitemsid  TYPE /dmo/booking_id,
      cfinitems_update TYPE TABLE FOR UPDATE zcr_request\\cfinitems,
      cfinitems        TYPE STRUCTURE FOR READ RESULT zcr_cfin_items.

    "Read all request for the requested cfinitemss
    " If multiple cfinitemss of the same request are requested, the request is returned only once.
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY cfinitems BY \_cfin
        FIELDS ( cfinUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(cfins).

    " Read all cfinitemss for all affected requests
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY cfin BY \_cfinitems
        FIELDS ( cfinitemsID )
        WITH CORRESPONDING #( cfins )
        LINK DATA(cfinitems_links)
      RESULT DATA(cfinitemss).

    " Process all affected request.
    LOOP AT cfins INTO DATA(cfin).

      " find max used cfinitemsID in all cfinitemss of this request
      max_cfinitemsid = '0000'.
      LOOP AT cfinitems_links INTO DATA(cfinitems_link) USING KEY id WHERE source-%tky = cfin-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        cfinitems = cfinitemss[ KEY id  %tky = cfinitems_link-target-%tky ].
        IF cfinitems-cfinitemsID > max_cfinitemsid.
          max_cfinitemsid = cfinitems-cfinitemsID.
        ENDIF.
      ENDLOOP.

      "Provide a cfinitems ID for all cfinitemss of this request that have none.
      LOOP AT cfinitems_links INTO cfinitems_link USING KEY id WHERE source-%tky = cfin-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        cfinitems = cfinitemss[ KEY id  %tky = cfinitems_link-target-%tky ].
        IF cfinitems-cfinitemsID IS INITIAL.
          max_cfinitemsid += 1.
          APPEND VALUE #( %tky      = cfinitems-%tky
                          cfinitemsID = max_cfinitemsid
                        ) TO cfinitems_update.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " Provide a cfinitems ID for all cfinitemss that have none.
    MODIFY ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY cfinitems
        UPDATE FIELDS ( cfinitemsID )
        WITH cfinitems_update.
  ENDMETHOD.

ENDCLASS.
