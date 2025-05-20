CLASS zcl_appemail_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_appemail_query IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
    DATA: lt_create TYPE STANDARD TABLE OF  zcdi_appemail_vh WITH EMPTY KEY.

    lt_create = VALUE #( ( appemail = 'asmawati_ahmad@petronas.com'
                           name = 'Asmawati Bt Ahmad')
                         ( appemail = 'angeline.chew@petronas.com'
                           name = 'Angeline Chew Soh Chen')
                         ( appemail = 'sharonlee.sinhua@petronas.com'
                         name = 'Sharon Lee Sin Hua')
                         ( appemail = 'abdul.manafdasir@petronas.com'
                         name = 'Abdul Manaf Dasirf')
                         ( appemail = 'jeewei.yeong@petronas.com'
                         name = 'Jee Wei Yeong')
                         ( appemail = 'chunleong.yeap@petronas.com'
                         name = 'Ray Yeap Chun Leong')
                         ( appemail = 'loh.kherhan@petronas.com'
                         name = 'Loh Kher Han')
                         ( appemail = 'fazealmah.mahlok@petronas.com'
                         name = 'Fazeal Mah B Mah Lok')
                         ( appemail = 'noraidaamira.kamarud@petronas.com'
                         name = 'Nor Aida Amira Kamarudin')
                         ( appemail = 'nureryanti.abdmanan@petronas.com'
                         name = 'Nur Eryanti Abd Manan')
    ).

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
