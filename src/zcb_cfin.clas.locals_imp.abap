CLASS lhc_Cfin DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS setCfinID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Cfin~setCfinID.

ENDCLASS.

CLASS lhc_Cfin IMPLEMENTATION.

  METHOD setCfinID.
  DATA:
      max_cfinid   TYPE /dmo/booking_id,
      cfin_update TYPE TABLE FOR UPDATE zcr_request\\Cfin,
      cfin         TYPE STRUCTURE FOR READ RESULT zcr_cfin.

    "Read all request for the requested cfins
    " If multiple Cfins of the same request are requested, the request is returned only once.
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Cfin BY \_Request
        FIELDS ( RequestUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    " Read all cfins for all affected requests
    READ ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY Request BY \_Cfin
        FIELDS ( CfinID )
        WITH CORRESPONDING #( requests )
        LINK DATA(cfin_links)
      RESULT DATA(cfins).

    " Process all affected request.
    LOOP AT requests INTO DATA(request).

      " find max used cfinID in all cfins of this request
      max_cfinid = '0000'.
      LOOP AT cfin_links INTO DATA(cfin_link) USING KEY id WHERE source-%tky = request-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        cfin = cfins[ KEY id  %tky = cfin_link-target-%tky ].
        IF cfin-CfinID > max_cfinid.
          max_cfinid = cfin-CfinID.
        ENDIF.
      ENDLOOP.

      "Provide a cfin ID for all cfins of this request that have none.
      LOOP AT cfin_links INTO cfin_link USING KEY id WHERE source-%tky = request-%tky.
        " Short dump occurs if link table does not match read table, which must never happen
        cfin = cfins[ KEY id  %tky = cfin_link-target-%tky ].
        IF cfin-CfinID IS INITIAL.
          max_cfinid += 1.
          APPEND VALUE #( %tky      = cfin-%tky
                          CfinID = max_cfinid
                        ) TO cfin_update.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " Provide a cfin ID for all cfins that have none.
    MODIFY ENTITIES OF zcr_request IN LOCAL MODE
      ENTITY cfin
        UPDATE FIELDS ( CfinID )
        WITH cfin_update.
  ENDMETHOD.

ENDCLASS.
