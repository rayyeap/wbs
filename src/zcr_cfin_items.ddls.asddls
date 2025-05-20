@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View: WBS CFIN Items'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCR_CFIN_ITEMS 
as select from zta_cfin_items
association to parent ZCR_CFIN     as _Cfin     on $projection.CfinUuid = _Cfin.CfinUuid
association [1..1] to ZCR_REQUEST as _Request on $projection.RequestUuid   = _Request.RequestUuid

{
    key cfin_items_uuid as CfinItemsUuid,
    request_uuid as RequestUuid,
    cfin_uuid as CfinUuid,
    cfin_items_id as CfinItemsId,
    project_definition as ProjectDefinition,
    wbs_element as WbsElement,
    wbs_element_description as WbsElementDescription,
    wbs_level as WbsLevel,
    project_type as ProjectType,
    person_responsible_no as PersonResponsibleNo,
    responsible_cost_center as ResponsibleCostCenter,
    requesting_cost_center as RequestingCostCenter,
    planning_element as PlanningElement,
    account_assignment_element as AccountAssignmentElement,
    billing_element as BillingElement,
    functional_area as FunctionalArea,
    profit_center as ProfitCenter,
    plant as Plant,
    costing_sheet as CostingSheet,
    joint_venture_id as JointVentureId,
    recovery_indicator as RecoveryIndicator,
    equity_type as EquityType,
    jv_object_type as JvObjectType,
    jv_jib_class as JvJibClass,
    jv_jib_sa_class as JvJibSaClass,
    //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
    locallastchangedat as Locallastchangedat,
    // Make association public
    _Request,
    _Cfin 
}
