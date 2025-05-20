@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root View: Request'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZCR_REQUEST
  as select from zta_request
  composition [0..*] of ZCR_CFIN                 as _Cfin
  composition [0..*] of ZCR_SAP                  as _Sap
  composition [0..*] of ZCR_APPROVER             as _Approver
  composition [0..*] of ZCR_LOGS                 as _Logs
  composition [0..*] of ZCR_MSG                   as _Msg
  composition [1] of ZCR_FILE                 as _File
  association [1..1] to /DMO/I_Overall_Status_VH as _OverallStatus on $projection.OverallStatus = _OverallStatus.OverallStatus
  association to ZCDI_SOURCE_VH as _Source on $projection.OverallStatus = _Source.source
  association [1..1] to ZCDI_COMPANY_VH as _Company on $projection.CompanyCode = _Company.compcode
{
  key request_uuid          as RequestUuid,
      image_url             as ImageUrl,
      request_id            as RequestId,
      request_type          as RequestType,
      financial_year        as FinancialYear,
      wbs_type              as WbsType,
      title                 as Title,
      project_type          as ProjectType,
      description           as Description,
     // @Search.defaultSearchElement: true
     // @ObjectModel.text.element: ['_Company.compname']
     // @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_COMPANY_VH', element: 'compcode' }, useForValidation: true }]
      company_code          as CompanyCode,
      justification         as Justification,
      overall_status        as OverallStatus,
      priority              as Priority,
    //@Consumption.filter.hidden: true
      //case overall_status
     // when 'O' then 0
      //when 'W' then 2
      //when 'A' then 3
      //else 0
      //end as StatusCriticality,

      replication_status    as ReplicationStatus,
      criticality_status    as CriticalityStatus,
      source                as Source,

      @Semantics.largeObject: { mimeType: 'MimeType',   //case-sensitive
                       fileName: 'FileName',   //case-sensitive
                       acceptableMimeTypes: ['text/csv'],
                       contentDispositionPreference: #ATTACHMENT }
      attachment            as Attachment,
      @Semantics.mimeType: true
      mime_type             as MimeType,
      file_name             as FileName,
      send_approver         as SendApprover,
      integer_value          as IntegerValue,
      cast ( integer_value as /DMO/FSA_BT_ProgressInteger preserving type ) as ProgressIntegerValue,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      //total ETag field
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Cfin, // Make association public
      _Sap, // Make association public
      _Approver,
      _Logs,
      _Msg,
      _OverallStatus,
      _File,
      _Source,
      _Company
}
