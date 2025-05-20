@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: Request Draft'

@Metadata.allowExtensions: true
@Search.searchable: true
//@ObjectModel.semanticKey: ['RequestID']

define root view entity ZCC_REQUEST_D 
provider contract transactional_query
  as projection on ZCR_REQUEST
{
    key RequestUuid,
    
    @Search.defaultSearchElement: true
    RequestId,
    RequestType,
    FinancialYear,
    WbsType,
    Title,
    ProjectType,
    Description,
    CompanyCode,
    Justification,
    OverallStatus,
    ReplicationStatus,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _Approver : redirected to composition child ZCC_APPROVER_D,
    _Cfin : redirected to composition child ZCC_CFIN_D,
    _OverallStatus,
    _Sap : redirected to composition child ZCC_SAP_D
}
