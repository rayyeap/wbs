@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: WBS SAP Draft'

@Metadata.allowExtensions: true
@Search.searchable: true
//@ObjectModel.semanticKey: ['SapId']

define view entity ZCC_SAP_D
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
      companycode,
      plant,
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
       _Sapitems: redirected to composition child ZCC_SAP_ITEMS_D,
      _Request : redirected to parent ZCC_REQUEST_D
}
