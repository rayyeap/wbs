CLASS lhc_sapitems DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setSapitemsID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Sapitems~setSapitemsID.

ENDCLASS.

CLASS lhc_sapitems IMPLEMENTATION.

  METHOD setSapitemsID.
    DATA:
      max_sapitemsid   TYPE /dmo/booking_id,
      sapitems_update TYPE TABLE FOR UPDATE zcr_request\\sapitems,
      sapitems         TYPE STRUCTURE FOR READ RESULT zcr_sap_items.

    "Read all request for the requested sapitemss
    " If multiple sapitemss of the same request are requested, the request is returned only once.
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY sapitems BY \_Sap
        FIELDS ( SapUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(saps).

    " Read all sapitemss for all affected requests
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Sap BY \_sapitems
        FIELDS ( sapitemsID )
        WITH CORRESPONDING #( saps )
        LINK DATA(sapitems_links)
      RESULT DATA(sapitemss).

    " Process all affected request.
    LOOP AT saps INTO DATA(sap).

      " find max used sapitemsID in all sapitemss of this request
      max_sapitemsid = '0000'.
      LOOP AT sapitems_links INTO DATA(sapitems_link) USING KEY id WHERE source-%tky = sap-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        sapitems = sapitemss[ KEY id  %tky = sapitems_link-target-%tky ].
        IF sapitems-sapitemsID > max_sapitemsid.
          max_sapitemsid = sapitems-sapitemsID.
        ENDIF.
      ENDLOOP.

      "Provide a sapitems ID for all sapitemss of this request that have none.
      LOOP AT sapitems_links INTO sapitems_link USING KEY id WHERE source-%tky = sap-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        sapitems = sapitemss[ KEY id  %tky = sapitems_link-target-%tky ].
        IF sapitems-sapitemsID IS INITIAL.
          max_sapitemsid += 1.
          APPEND VALUE #( %tky      = sapitems-%tky
                          sapitemsID = max_sapitemsid
                        ) TO sapitems_update.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " Provide a sapitems ID for all sapitemss that have none.
    MODIFY ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY sapitems
        UPDATE FIELDS ( sapitemsID )
        WITH sapitems_update.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
