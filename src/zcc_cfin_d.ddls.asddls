@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: WBS CFIN Draft'

@Metadata.allowExtensions: true
@Search.searchable: true
//@ObjectModel.semanticKey: ['CfinId']

define view entity ZCC_CFIN_D
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
      _Cfinitems : redirected to composition child ZCC_CFIN_ITEMS_D,
      _Request   : redirected to parent ZCC_REQUEST_D
}
