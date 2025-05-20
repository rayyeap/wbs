@EndUserText.label: 'Custom Entity: Source'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PROFITCENTER_SAP_QUERY'
//@Search.searchable: true

define custom entity ZCDI_PROFITCENTER_SAP_VH
{
      //@Search.defaultSearchElement: true
      @EndUserText.label: 'Profit Center'
      //@ObjectModel.text.element: ['compname']
     // @UI.textArrangement: #TEXT_SEPARATE
  key ProfitCenter : abap.char(10);

      //@Search.defaultSearchElement: true
      //@Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Name'
      @Semantics.text: true
      ProfitCenterName : abap.char(20);
}
