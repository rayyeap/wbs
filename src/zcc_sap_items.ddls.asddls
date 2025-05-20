@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: WBS SAP Items'
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZCC_SAP_ITEMS as projection on ZCR_SAP_ITEMS
{
    key SapItemsUuid,
    RequestUuid,
    SapUuid,
    @Search.defaultSearchElement: true
    SapItemsId,
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
    Cfinwbs,
    Locallastchangedat,
    /* Associations */
    _Request : redirected to ZCC_REQUEST,
    _sap : redirected to parent ZCC_SAP
}
