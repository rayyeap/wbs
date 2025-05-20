@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: WBS SAP Items'
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZCC_CFIN_ITEMS as projection on ZCR_CFIN_ITEMS
{
    key CfinItemsUuid,
    RequestUuid,
    CfinUuid,
    @Search.defaultSearchElement: true
    CfinItemsId,
    @Search.defaultSearchElement: true
    ProjectDefinition,
    WbsElement,
    WbsElementDescription,
    WbsLevel,
    ProjectType,
    PersonResponsibleNo,
    ResponsibleCostCenter,
    RequestingCostCenter,
    PlanningElement,
    AccountAssignmentElement,
    BillingElement,
    FunctionalArea,
    ProfitCenter,
    Plant,
    CostingSheet,
    JointVentureId,
    RecoveryIndicator,
    EquityType,
    JvObjectType,
    JvJibClass,
    JvJibSaClass,
    Locallastchangedat,
    /* Associations */
    _Request : redirected to ZCC_REQUEST,
    _Cfin : redirected to parent ZCC_CFIN
}
