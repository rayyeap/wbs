@EndUserText.label: 'Custom Entity: Source'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_COMPANYCODE_QUERY'
//@Search.searchable: true

define custom entity ZCDI_COMPANY_VH
{
      //@Search.defaultSearchElement: true
      @EndUserText.label: 'Company Code'
      //@ObjectModel.text.element: ['compname']
     // @UI.textArrangement: #TEXT_SEPARATE
  key compcode : abap.char(4);

      //@Search.defaultSearchElement: true
      //@Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Company Name'
      @Semantics.text: true
      compname : abap.char(25);
}
