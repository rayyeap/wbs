@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: WBS CFIN'
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZCC_CFIN
  as projection on ZCR_CFIN
{
  key CfinUuid,
      RequestUuid,

      @Search.defaultSearchElement: true
      CfinId,
      @Search.defaultSearchElement: true
      projectdefinition,
      @Search.defaultSearchElement: true
      projectdescription,
      projectprofile,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_COMPANY_CFIN_VH', element: 'compcode' } }] //, useForValidation: true
      companycode,
      plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_PROFITCENTER_CFIN_VH', element: 'ProfitCenter' } }]
      profitcenter,
      functionalarea,
      personresponsibleno,
      startdate,
      finishdate,
      jointventureid,
      recoveryindicator,
      equitytype,
      jvobjecttype,
      jvjibclass,
      jvjibsaclass,

      LocalLastChangedAt,
      /* Associations */
      _Cfinitems : redirected to composition child ZCC_CFIN_ITEMS,
      _Request   : redirected to parent ZCC_REQUEST
}
