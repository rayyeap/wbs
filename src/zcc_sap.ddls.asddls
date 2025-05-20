@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: WBS SAP'
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZCC_SAP
  as projection on ZCR_SAP
{
  key SapUuid,
      RequestUuid,

      @Search.defaultSearchElement: true
      SapId,
      @Search.defaultSearchElement: true
      projectdefinition,
      @Search.defaultSearchElement: true
      projectdescription,
      projectprofile,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_COMPANY_VH', element: 'compcode' }, useForValidation: true }]
      companycode,
      plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_PROFITCENTER_SAP_VH', element: 'ProfitCenter' }, useForValidation: true }]
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
       _Sapitems: redirected to composition child ZCC_SAP_ITEMS,
      _Request : redirected to parent ZCC_REQUEST
}
