@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: WBS SAP Items Draft'
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZCC_SAP_ITEMS_D as projection on ZCR_SAP_ITEMS
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
    Locallastchangedat,
    /* Associations */
    _Request : redirected to ZCC_REQUEST_D,
    _sap : redirected to parent ZCC_SAP_D
}
