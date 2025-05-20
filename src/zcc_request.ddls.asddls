@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: Request'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZCC_REQUEST
  provider contract transactional_query
  as projection on ZCR_REQUEST
{
  key RequestUuid,

      @Search.defaultSearchElement: true
      RequestId,
      
      @Semantics.imageUrl: true
      ImageUrl,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_REQUESTTYPE_VH', element: 'requesttype' }, useForValidation: true }]
      RequestType,
      FinancialYear,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_WBSTYPE_VH', element: 'wbstype' }, useForValidation: true }] 
      WbsType,
      Title,
      ProjectType,
      Description,
      @Search.defaultSearchElement: true
      //@ObjectModel.text.element: ['_Company.compname']
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_COMPANY_VH', element: 'compcode' }, useForValidation: true }]
      CompanyCode,
      Justification,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_SOURCE_VH', element: 'source' }, useForValidation: true }]
      Source,
      
      SendApprover,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_PRIORITY_VH', element: 'priority' }, useForValidation: true }]
      Priority,
      
      @ObjectModel.text.element: ['OverallStatusText']
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Overall_Status_VH', element: 'OverallStatus' } }]
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,
      // StatusCriticality,
      ReplicationStatus,
      CriticalityStatus,
      Attachment,
      MimeType,
      FileName,
      IntegerValue,
      ProgressIntegerValue,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _OverallStatus,
      _Cfin     : redirected to composition child ZCC_CFIN,
      _Sap      : redirected to composition child ZCC_SAP,
      _Approver : redirected to composition child ZCC_APPROVER,
      _Logs     : redirected to composition child ZCC_LOGS,
      _Msg      : redirected to composition child ZCC_MSG,
      _File     : redirected to composition child ZCC_FILE,
      _Company
}
